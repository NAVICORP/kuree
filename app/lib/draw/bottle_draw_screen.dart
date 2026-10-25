import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/format.dart';
import '../core/kuri.dart';
import '../core/messages.dart';
import '../l10n/strings.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'scene.dart';
import 'soundtrack.dart';

export 'scene.dart' show DrawEntry;

enum _Phase { ready, preparing, running, done }

/// The bottle draw for one month, full screen. The winner is picked with the
/// phone's secure random numbers the moment the draw starts; the animation
/// only shows it. Nothing is saved until the admin presses Save.
class BottleDrawScreen extends StatefulWidget {
  const BottleDrawScreen({
    super.key,
    required this.title,
    required this.month,
    required this.label,
    required this.pot,
    this.currency = 'INR',
    required this.entries,
    required this.resultText,
    required this.onSave,
    required this.by,
  });

  /// "Riverside 5K Chit"
  final String title;
  final int month;

  /// "October 2026"
  final String label;
  final int pot;

  /// The chit's currency code, for the pot.
  final String currency;
  final List<DrawEntry> entries;
  final String Function(int slot, int names, DateTime when) resultText;
  final Future<bool> Function(int slot, DrawInfo info) onSave;
  final String by;

  @override
  State<BottleDrawScreen> createState() => _BottleDrawScreenState();
}

class _BottleDrawScreenState extends State<BottleDrawScreen> with SingleTickerProviderStateMixin {
  late final List<DrawEntry> order = shuffled(widget.entries);
  late BottleScene scene = _scene(0, 0, null);
  final ValueNotifier<double> clock = ValueNotifier(-DrawPlan.countdown);
  late final Ticker ticker = createTicker(_tick);
  _Phase phase = _Phase.ready;
  bool sound = true;
  bool saved = false;
  bool saving = false;
  int seed = 0;
  int pickIndex = 0;
  DateTime? when;
  Int16List? samples;
  AudioPlayer? player;
  String? videoPath;
  double? videoProgress;

  BottleScene _scene(int pick, int seed, DateTime? when) => BottleScene(
        order: order,
        pickIndex: pick,
        seed: seed,
        kicker: widget.title.toUpperCase(),
        title: S.current.drawTitle(widget.month),
        subtitle: S.current.drawSubtitle(widget.label, money(widget.pot, widget.currency)),
        when: when,
      )..subtitlePot = money(widget.pot, widget.currency);

  @override
  void dispose() {
    ticker.dispose();
    clock.dispose();
    player?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => phase = _Phase.preparing);
    final rnd = math.Random.secure();
    pickIndex = fair(order.length); // decided here, before a single frame of the draw
    seed = rnd.nextInt(1 << 32);
    when = DateTime.now();
    scene = _scene(pickIndex, seed, when);
    WakelockPlus.enable();
    if (sound) {
      try {
        final plan = scene.plan, s = seed;
        samples = await Isolate.run(() => Soundtrack.render(plan, s));
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/kuree-draw-$seed.wav');
        await f.writeAsBytes(Soundtrack.wav(samples!), flush: true);
        player = AudioPlayer();
        await player!.setReleaseMode(ReleaseMode.stop);
        await player!.play(DeviceFileSource(f.path));
      } catch (_) {
        player = null; // The draw goes on without sound.
      }
    }
    if (!mounted) return;
    setState(() => phase = _Phase.running);
    ticker.start();
  }

  void _tick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1000 - DrawPlan.countdown;
    scene.advanceTo(t);
    clock.value = t;
    if (phase == _Phase.running && t >= scene.plan.end) {
      HapticFeedback.heavyImpact();
      setState(() => phase = _Phase.done);
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final slot = scene.picked.slot;
    final ok = await widget.onSave(
      slot,
      DrawInfo(
        at: when!.toUtc().toIso8601String(),
        by: widget.by,
        picked: slot,
        names: [for (final e in widget.entries) e.slot],
      ),
    );
    if (!mounted) return;
    setState(() {
      saving = false;
      saved = ok;
    });
  }

  Future<void> _video() async {
    if (videoPath != null) return _shareVideo();
    setState(() => videoProgress = 0);
    try {
      final path = await _makeVideo((p) {
        if (mounted) setState(() => videoProgress = p);
      });
      videoPath = path;
      try {
        if (!await Gal.hasAccess()) await Gal.requestAccess();
        await Gal.putVideo(path);
        if (mounted) toast(context, S.of(context).savedToPhotos);
      } catch (_) {
        // No access to the photos: sharing still works.
      }
      if (mounted) setState(() => videoProgress = null);
      await _shareVideo();
    } catch (e) {
      if (mounted) {
        setState(() => videoProgress = null);
        toast(context, S.of(context).videoFailed, bad: true);
      }
    }
  }

  Future<void> _shareVideo() async {
    final p = videoPath;
    if (p == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(p, mimeType: 'video/mp4')], title: S.current.drawShareTitle(widget.title, widget.month)));
  }

  /// Plays the same draw again, frame by frame, into an mp4 with its sound.
  Future<String> _makeVideo(void Function(double) progress) async {
    const vw = 720, vh = 1280, fps = 30;
    final s2 = _scene(pickIndex, seed, when);
    final plan = s2.plan, sd = seed;
    final Int16List pcm = samples ?? await Isolate.run<Int16List>(() => Soundtrack.render(plan, sd));
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${widget.title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').toLowerCase()}-month-${widget.month}-draw.mp4';
    final old = File(path);
    if (await old.exists()) await old.delete();
    await FlutterQuickVideoEncoder.setLogLevel(LogLevel.none);
    await FlutterQuickVideoEncoder.setup(
      width: vw,
      height: vh,
      fps: fps,
      videoBitrate: 4500000,
      profileLevel: ProfileLevel.any,
      audioChannels: 1,
      audioBitrate: 128000,
      sampleRate: Soundtrack.rate,
      filepath: path,
    );
    final frames = (s2.length / 1000 * fps).ceil();
    const perFrame = Soundtrack.rate ~/ fps;
    for (var f = 0; f < frames; f++) {
      final t = -DrawPlan.countdown + f * 1000 / fps;
      s2.advanceTo(t);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.scale(vw / BottleScene.W);
      s2.paint(c, t);
      final pic = rec.endRecording();
      final img = await pic.toImage(vw, vh);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      img.dispose();
      pic.dispose();
      await FlutterQuickVideoEncoder.appendVideoFrame(bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      final chunk = Int16List(perFrame);
      final from = f * perFrame;
      for (var i = 0; i < perFrame && from + i < pcm.length; i++) {
        chunk[i] = pcm[from + i];
      }
      final le = ByteData(perFrame * 2);
      for (var i = 0; i < perFrame; i++) {
        le.setInt16(i * 2, chunk[i], Endian.little);
      }
      await FlutterQuickVideoEncoder.appendAudioFrame(le.buffer.asUint8List());
      if (f % 3 == 0) progress((f + 1) / frames);
    }
    await FlutterQuickVideoEncoder.finish();
    progress(1);
    return path;
  }

  Future<void> _close() async {
    final s = S.of(context);
    if (phase == _Phase.running || phase == _Phase.preparing) {
      if (!await confirm(context, title: s.stopDrawTitle, text: s.nothingSaved, yes: s.stop, danger: true)) return;
    } else if (phase == _Phase.done && !saved) {
      if (!await confirm(context, title: s.closeUnsavedTitle, text: s.winnerNotSaved, yes: s.close, danger: true)) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF021A05),
          body: Stack(children: [
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: BottleScene.W / BottleScene.H,
                  child: RepaintBoundary(child: CustomPaint(painter: _ScenePainter(this))),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.all(Sp.sm),
                  child: RoundIcon(Icons.close_rounded, dark: true, tooltip: s.close, onTap: _close),
                ),
              ),
            ),
            if (phase == _Phase.ready || phase == _Phase.preparing) _readyCard(s),
            if (phase == _Phase.done) _doneCard(s),
          ]),
        ),
      ),
    );
  }

  Widget _sheet(Widget child) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(Sp.md),
          constraints: BoxConstraints(maxWidth: 480, maxHeight: MediaQuery.of(context).size.height * 0.62),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(K.rLg), boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 16)),
          ]),
          child: Material(
            color: K.paper,
            borderRadius: BorderRadius.circular(K.rLg),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.xl, Sp.xl, 18), child: child),
          ),
        ),
      ),
    );
  }

  Widget _readyCard(S s) {
    return _sheet(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(s.drawTitle(widget.month), style: T.h2),
      const SizedBox(height: Sp.xs),
      Text(s.slipsGoIn(widget.entries.length), style: T.small),
      const SizedBox(height: Sp.md),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final e in widget.entries)
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 10, 4),
            decoration: BoxDecoration(color: K.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: K.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SlotBadge('${e.slot}', size: 24, style: SlotBadgeStyle.sun),
              const SizedBox(width: 6),
              Flexible(child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label)),
            ]),
          ),
      ]),
      const SizedBox(height: Sp.md),
      Text(s.recordHint, style: T.small),
      const SizedBox(height: 6),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: sound,
        activeTrackColor: K.green,
        onChanged: phase == _Phase.ready ? (v) => setState(() => sound = v) : null,
        title: Text(s.musicSound, style: T.bodyStrong),
      ),
      const SizedBox(height: 6),
      KButton(
        label: phase == _Phase.preparing ? s.gettingReady : s.startDraw,
        icon: Icons.play_arrow_rounded,
        kind: KButtonKind.sun,
        expand: true,
        busy: phase == _Phase.preparing,
        onPressed: phase == _Phase.ready ? _start : null,
      ),
    ]));
  }

  Widget _doneCard(S s) {
    final win = scene.picked;
    return _sheet(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        SlotBadge('${win.slot}', size: 48, style: SlotBadgeStyle.sun),
        const SizedBox(width: Sp.md),
        Expanded(child: Text(win.name, style: T.h2)),
      ]),
      const SizedBox(height: 6),
      Text(s.takesPotFor(widget.month, widget.label), style: T.body.copyWith(color: K.ink2)),
      const SizedBox(height: Sp.lg),
      KButton(
        label: saved ? s.saved : s.saveAsWinner(widget.month),
        icon: saved ? Icons.check_circle_rounded : Icons.check_rounded,
        expand: true,
        busy: saving,
        onPressed: saved ? null : _save,
      ),
      const SizedBox(height: Sp.md - 2),
      KButton(
        label: videoProgress != null ? s.makingVideo((videoProgress! * 100).round()) : (videoPath != null ? s.shareVideo : s.saveVideo),
        icon: Icons.movie_outlined,
        kind: KButtonKind.secondary,
        expand: true,
        busy: videoProgress != null,
        onPressed: videoProgress != null ? null : _video,
      ),
      const SizedBox(height: Sp.md - 2),
      KButton(
        label: s.sendResultWa,
        icon: Icons.chat_outlined,
        kind: KButtonKind.secondary,
        expand: true,
        onPressed: () => launchUrl(whatsApp(widget.resultText(win.slot, order.length, when!)), mode: LaunchMode.externalApplication),
      ),
      const SizedBox(height: 6),
      KButton(label: s.close, kind: KButtonKind.ghost, onPressed: _close),
    ]));
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.s) : super(repaint: s.clock);
  final _BottleDrawScreenState s;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / BottleScene.W);
    s.scene.paint(canvas, s.clock.value);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => true;
}
