import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/startup.dart';
import '../l10n/strings.dart';
import 'glass.dart';
import 'theme.dart';

/// The loading screen. It carries on from the phone's own launch screen (the
/// chit card in the middle of deep green, the same picture in the same
/// place) while the app picks up the session and loads the chits, then
/// gives way to [child].
///
/// The card lifts off the green and settles, a glass ring takes shape round
/// it, and a light runs round the ring while the work goes on. It plays
/// along: a drag tilts the card towards the finger (the ring and the light
/// behind shift the other way), and a tap bounces it, with a tick under the
/// finger.
///
/// It shows for at least [minShow], so it never flickers, and leaves as soon
/// as the work is done after that. On a slow network it says so after
/// [stillAfter] and hands over anyway after [handOverAfter]; when the chits
/// could not load (no connection), it says why and offers to try again.
/// With reduced motion it stands still and only fades; with Increase
/// contrast the glass turns solid.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key, required this.child, this.work});

  /// The first real screen.
  final Widget child;

  /// The start-up work; the app's own ([Startup.run]) unless a test gives one.
  final Future<void> Function()? work;

  /// The card in its 288 point square (tools/brand/splash.py): the same
  /// picture and size as the phone's launch screen.
  static const mark = AssetImage('assets/brand/splash.png');
  static const markSize = 288.0;

  static const minShow = Duration(milliseconds: 600);
  static const stillAfter = Duration(milliseconds: 2500);
  static const handOverAfter = Duration(seconds: 8);

  /// Decodes the card before the first frame, so that frame already shows
  /// it, exactly where the launch screen had it. Never waits long.
  static Future<void> prepare() {
    final done = Completer<void>();
    final views = PlatformDispatcher.instance.views;
    final ratio = views.isEmpty ? 3.0 : views.first.devicePixelRatio;
    final stream = mark.resolve(ImageConfiguration(devicePixelRatio: ratio, size: const Size.square(markSize)));
    late final ImageStreamListener listener;
    void finish() {
      if (!done.isCompleted) done.complete();
      // The picture stays in the image cache for the first frame.
      scheduleMicrotask(() => stream.removeListener(listener));
    }

    listener = ImageStreamListener((_, __) => finish(), onError: (_, __) => finish());
    stream.addListener(listener);
    return done.future.timeout(const Duration(milliseconds: 500), onTimeout: () {});
  }

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// Seconds since the first frame, for every moving part.
  final ValueNotifier<double> _clock = ValueNotifier(0);
  double _last = 0;

  bool _minPassed = false;
  bool _ready = false;
  bool _still = false;
  String? _error;
  int _attempt = 0;
  Timer? _minTimer, _stillTimer, _handOverTimer;

  /// When the leaving started (on [_clock]), or null while loading.
  double? _leaveAt;
  bool _done = false;

  // Springs: the tilt towards a finger, the squash of a tap and its spin.
  Offset _tilt = Offset.zero, _tiltV = Offset.zero, _tiltTo = Offset.zero;
  bool _dragging = false;
  double _squash = 0, _squashV = 0;
  double _spin = 0, _spinV = 0;
  int _taps = 0;
  double? _pulseAt;

  static const _leaveFor = 0.34;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _minTimer = Timer(LaunchScreen.minShow, () {
      _minPassed = true;
      _maybeLeave();
    });
    _stillTimer = Timer(LaunchScreen.stillAfter, () {
      if (mounted && !_ready) setState(() => _still = true);
    });
    _run();
  }

  Future<void> _run() async {
    final attempt = ++_attempt;
    _handOverTimer?.cancel();
    _handOverTimer = Timer(LaunchScreen.handOverAfter, () {
      // Slow, not failed: the app takes over and carries on loading.
      if (mounted && _error == null) _leave();
    });
    try {
      await (widget.work ?? Startup.instance.run)();
      if (!mounted) return;
      if (attempt != _attempt) return;
      _ready = true;
      _maybeLeave();
    } catch (e) {
      if (!mounted) return;
      if (attempt != _attempt || _leaveAt != null) return;
      final message = e is ApiError ? e.message : S.of(context).errNoConnection;
      _handOverTimer?.cancel();
      setState(() => _error = message);
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _still = false;
    });
    _stillTimer?.cancel();
    _stillTimer = Timer(LaunchScreen.stillAfter, () {
      if (mounted && !_ready && _error == null) setState(() => _still = true);
    });
    _run();
  }

  void _maybeLeave() {
    if (_ready && _minPassed) _leave();
  }

  void _leave() {
    if (!mounted || _leaveAt != null) return;
    _minTimer?.cancel();
    _stillTimer?.cancel();
    _handOverTimer?.cancel();
    setState(() => _leaveAt = _clock.value);
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final dt = (t - _last).clamp(0.0, 1 / 30);
    _last = t;
    _step(dt);
    _clock.value = t;
    final at = _leaveAt;
    final leaveFor = MediaQuery.maybeDisableAnimationsOf(context) ?? false ? 0.2 : _leaveFor;
    if (at != null && t - at >= leaveFor && !_done) {
      _ticker.stop();
      setState(() => _done = true);
    }
  }

  /// One step of the springs: stiff and quick under a finger, softer with a
  /// little wobble when let go.
  void _step(double dt) {
    final (k, c) = _dragging ? (420.0, 38.0) : (170.0, 10.0);
    final a = (_tiltTo - _tilt) * k - _tiltV * c;
    _tiltV += a * dt;
    _tilt += _tiltV * dt;
    _squashV += (-280 * _squash - 12 * _squashV) * dt;
    _squash += _squashV * dt;
    _spinV += (-200 * _spin - 11 * _spinV) * dt;
    _spin += _spinV * dt;
  }

  void _tap() {
    HapticFeedback.selectionClick();
    if (MediaQuery.disableAnimationsOf(context)) return;
    _taps++;
    _squashV = -2.6;
    _spinV = _taps.isOdd ? 2.2 : -2.2;
    _pulseAt = _clock.value;
  }

  void _drag(Offset at, Size size) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final half = size.shortestSide / 2;
    final d = (at - size.center(Offset.zero)) / half;
    _tiltTo = Offset(d.dx.clamp(-1.0, 1.0), d.dy.clamp(-1.0, 1.0));
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _stillTimer?.cancel();
    _handOverTimer?.cancel();
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The first screen keeps its place in the tree from the moment it is
    // built, so it is not built twice when the loading screen goes.
    final leaving = _leaveAt != null;
    return Stack(fit: StackFit.expand, children: [
      if (leaving) KeyedSubtree(key: const ValueKey('launch-child'), child: widget.child) else const ColoredBox(color: K.deep),
      if (!_done) IgnorePointer(ignoring: leaving, child: ExcludeSemantics(excluding: leaving, child: _stage(context))),
    ]);
  }

  Widget _stage(BuildContext context) {
    final s = S.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final solid = glassOff(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: LayoutBuilder(builder: (context, box) {
        final size = box.biggest;
        return GestureDetector(
          key: const ValueKey('launch'),
          behavior: HitTestBehavior.opaque,
          onTap: _tap,
          onPanDown: (d) {
            _dragging = true;
            _drag(d.localPosition, size);
          },
          onPanUpdate: (d) => _drag(d.localPosition, size),
          onPanEnd: (_) {
            _dragging = false;
            _tiltTo = Offset.zero;
          },
          onPanCancel: () {
            _dragging = false;
            _tiltTo = Offset.zero;
          },
          child: Semantics(
            label: s.launchOpening,
            child: ValueListenableBuilder<double>(
              valueListenable: _clock,
              builder: (context, t, _) => _scene(context, t, still, solid),
            ),
          ),
        );
      }),
    );
  }

  Widget _scene(BuildContext context, double t, bool still, bool solid) {
    final s = S.of(context);
    final pose = _Pose.at(t, still: still);
    final leave = _leaveAt == null ? 0.0 : ((t - _leaveAt!) / (still ? 0.2 : _leaveFor)).clamp(0.0, 1.0);
    final out = Curves.easeOutCubic.transform(leave);
    final tilt = still ? Offset.zero : _tilt;
    final squash = still ? 0.0 : _squash;
    final spin = still ? 0.0 : _spin;
    final pulse = _pulseAt == null || still ? null : (t - _pulseAt!) / 0.7;

    final grow = 1 + pose.lift * 0.05 + out * 0.10;
    final card = Matrix4.identity()
      ..setEntry(3, 2, 0.0013)
      ..multiply(Matrix4.translationValues(tilt.dx * 10, tilt.dy * 10 - pose.lift * 9 + pose.bob, 0))
      ..rotateX(-tilt.dy * 0.34)
      ..rotateY(tilt.dx * 0.40)
      ..rotateZ(pose.wobble + spin * 0.12)
      ..multiply(Matrix4.diagonal3Values(grow + squash * 0.35, grow + squash * 0.25, 1));

    final words = <Widget>[];
    if (_error != null) {
      words.add(Text(_error!, textAlign: TextAlign.center, style: T.small.copyWith(color: K.heroText)));
      words.add(const SizedBox(height: Sp.md));
      words.add(_RetryPill(label: s.tryAgain, onTap: _retry));
    } else if (_still) {
      words.add(Text(s.launchStillLoading, textAlign: TextAlign.center, style: T.small.copyWith(color: K.heroText.withValues(alpha: 0.86))));
    }
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, Sp.xxl);

    return Opacity(
      opacity: 1 - Curves.easeInCubic.transform(leave),
      child: Stack(fit: StackFit.expand, children: [
        // Deep green with soft light, which comes up out of the plain green
        // of the launch screen and shifts a little against the tilt.
        CustomPaint(painter: _Backdrop(glow: pose.glow, shift: -tilt * 16, solid: solid)),
        Center(
          child: SizedBox.square(
            dimension: LaunchScreen.markSize,
            child: Stack(clipBehavior: Clip.none, fit: StackFit.expand, children: [
              Transform.translate(
                offset: -tilt * 6,
                child: CustomPaint(
                  painter: _Ring(
                    show: pose.ring,
                    sweep: still ? 0 : t,
                    grow: out,
                    pulse: pulse,
                    solid: solid,
                    still: still,
                  ),
                ),
              ),
              // The card's own shadow on the glass, deeper as it lifts.
              Transform.translate(
                offset: Offset(tilt.dx * 4, 58 + pose.lift * 8),
                child: Center(
                  child: Container(
                    width: 150 - pose.lift * 14,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.30 * pose.lift), blurRadius: 22 + pose.lift * 8, spreadRadius: -2),
                      ],
                    ),
                  ),
                ),
              ),
              Transform(
                alignment: Alignment.center,
                transform: card,
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (r) => _shine(r, pose.shine + tilt.dx * 0.35 - tilt.dy * 0.15, still || solid),
                  child: const Image(image: LaunchScreen.mark, width: LaunchScreen.markSize, height: LaunchScreen.markSize, filterQuality: FilterQuality.medium),
                ),
              ),
            ]),
          ),
        ),
        // The name, under the ring.
        Center(
          child: Transform.translate(
            offset: Offset(0, 146 + (1 - pose.name) * 10 - tilt.dy * 4),
            child: Opacity(
              opacity: pose.name,
              child: const Text('Kuree', style: TextStyle(fontFamily: 'Bricolage', fontSize: 24, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0, color: Colors.white)),
            ),
          ),
        ),
        // Only when the network is slow or out: a word, and a way to retry.
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(Sp.xxl, 0, Sp.xxl, bottom + 36),
            child: AnimatedSwitcher(
              duration: still ? Duration.zero : const Duration(milliseconds: 280),
              child: words.isEmpty
                  ? const SizedBox(key: ValueKey('quiet'))
                  : Semantics(
                      key: ValueKey(_error ?? 'still'),
                      liveRegion: true,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Column(mainAxisSize: MainAxisSize.min, children: words),
                      ),
                    ),
            ),
          ),
        ),
      ]),
    );
  }

  /// A band of light across the card, once as it lifts, then where the
  /// tilt puts it.
  Shader _shine(Rect r, double at, bool off) {
    if (off) return const LinearGradient(colors: [Colors.transparent, Colors.transparent]).createShader(r);
    final c = at.clamp(-0.4, 1.4);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0)],
      stops: [(c - 0.16).clamp(0.0, 1.0), c.clamp(0.0, 1.0), (c + 0.16).clamp(0.0, 1.0)],
    ).createShader(r);
  }
}

/// Where everything is at [t] seconds into the intro. At 0 it is the launch
/// screen exactly: plain green, the card flat, nothing else.
class _Pose {
  const _Pose({required this.glow, required this.ring, required this.lift, required this.wobble, required this.bob, required this.name, required this.shine});

  final double glow, ring, lift, wobble, bob, name, shine;

  static double _ease(double x) => Curves.easeOutCubic.transform(x.clamp(0.0, 1.0));

  factory _Pose.at(double t, {required bool still}) {
    if (still) {
      // No motion: everything simply there, softly faded in.
      final f = _ease(t / 0.25);
      return _Pose(glow: f, ring: f, lift: 0, wobble: 0, bob: 0, name: f, shine: -1);
    }
    // The card rises fast, overshoots and settles a little above the glass.
    double lift;
    if (t < 0.32) {
      lift = _ease(t / 0.32);
    } else {
      final u = t - 0.32;
      lift = 0.45 + 0.55 * math.exp(-7 * u) * math.cos(12 * u);
    }
    final wobble = t < 0.1 ? 0.0 : 0.05 * math.exp(-5 * (t - 0.1)) * math.sin(11 * (t - 0.1));
    final calm = ((t - 0.7) / 0.6).clamp(0.0, 1.0);
    final bob = math.sin(2 * math.pi * (t - 0.7) / 2.6) * 2.4 * calm * calm * (3 - 2 * calm);
    return _Pose(
      glow: _ease(t / 0.7),
      ring: Curves.easeOutBack.transform(((t - 0.08) / 0.5).clamp(0.0, 1.0)),
      lift: lift,
      wobble: wobble,
      bob: bob,
      name: _ease((t - 0.25) / 0.4),
      shine: -0.4 + 1.8 * ((t - 0.3) / 0.7).clamp(0.0, 1.0),
    );
  }
}

/// Deep green with soft light: the lighter green the app icon has at its
/// heart, leaf green above, a touch of sun, all blurred into the page.
class _Backdrop extends CustomPainter {
  _Backdrop({required this.glow, required this.shift, required this.solid});
  final double glow;
  final Offset shift;
  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = K.deep);
    if (solid || glow <= 0) return;
    void blob(Offset c, double r, Color colour) {
      final at = c + shift;
      canvas.drawCircle(
        at,
        r,
        Paint()..shader = RadialGradient(colors: [colour, colour.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: at, radius: r)),
      );
    }

    final m = math.max(size.width, size.height);
    final mid = size.center(Offset.zero);
    blob(mid, m * 0.46, const Color(0xFF11541F).withValues(alpha: 0.85 * glow));
    blob(Offset(size.width * 0.12, size.height * 0.1), m * 0.42, K.leaf.withValues(alpha: 0.30 * glow));
    blob(Offset(size.width * 0.96, size.height * 0.24), m * 0.28, K.sun.withValues(alpha: 0.10 * glow));
    blob(Offset(size.width * 0.86, size.height * 0.92), m * 0.40, K.brand500.withValues(alpha: 0.26 * glow));
    // A little darker at the very bottom, for the words there.
    final low = Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38);
    canvas.drawRect(
      low,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [K.deep.withValues(alpha: 0), const Color(0xFF021B06).withValues(alpha: 0.55 * glow)],
        ).createShader(low),
    );
  }

  @override
  bool shouldRepaint(_Backdrop old) => old.glow != glow || old.shift != shift || old.solid != solid;
}

/// The glass ring round the card: a clear disc with light on its rim (like
/// the dark glass on the month card), and a brighter light running round it
/// while the app loads. A tap sends a soft ring out from it.
class _Ring extends CustomPainter {
  _Ring({required this.show, required this.sweep, required this.grow, required this.pulse, required this.solid, required this.still});
  final double show, sweep, grow;
  final double? pulse;
  final bool solid, still;

  static const radius = 112.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (show <= 0) return;
    final c = size.center(Offset.zero);
    final fade = show.clamp(0.0, 1.0);
    final r = radius * (0.86 + 0.14 * show) * (1 + 0.22 * grow);
    final disc = Rect.fromCircle(center: c, radius: r);
    const white = Colors.white;

    if (solid) {
      canvas.drawCircle(c, r, Paint()..color = const Color(0x26FFFFFF).withValues(alpha: 0.15 * fade));
      canvas.drawCircle(c, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = white.withValues(alpha: 0.55 * fade));
    } else {
      // A soft shadow below the disc, then the clear glass and its sheen.
      canvas.drawCircle(c.translate(0, 14), r, Paint()
        ..color = Colors.black.withValues(alpha: 0.22 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [white.withValues(alpha: 0.13 * fade), white.withValues(alpha: 0.05 * fade), white.withValues(alpha: 0.09 * fade)],
            stops: const [0, 0.55, 1],
          ).createShader(disc),
      );
      canvas.save();
      canvas.clipPath(Path()..addOval(disc));
      final top = Rect.fromLTWH(disc.left, disc.top, disc.width, disc.height * 0.5);
      canvas.drawRect(
        top,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [white.withValues(alpha: 0.10 * fade), white.withValues(alpha: 0)],
          ).createShader(top),
      );
      canvas.restore();
      // The rim: bright at the top left, faint at the sides, a softer catch
      // at the bottom right.
      canvas.drawCircle(
        c,
        r - 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [white.withValues(alpha: 0.60 * fade), white.withValues(alpha: 0.08 * fade), white.withValues(alpha: 0.30 * fade)],
            stops: const [0, 0.5, 1],
          ).createShader(disc),
      );
    }

    // The light that runs round the rim while the app loads.
    final track = Rect.fromCircle(center: c, radius: r - 0.5);
    final len = still ? 2 * math.pi : (0.26 + 0.08 * math.sin(sweep * 2 * math.pi / 1.1)) * 2 * math.pi;
    final start = still ? 0.0 : sweep * 2 * math.pi / 1.25 - math.pi / 2;
    final fadeArc = fade * (1 - grow);
    if (still) {
      canvas.drawCircle(c, r - 0.5, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = K.sun.withValues(alpha: 0.55 * fadeArc));
    } else {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.6
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: len,
          colors: [K.sun.withValues(alpha: 0), K.sun.withValues(alpha: 0.85 * fadeArc), white.withValues(alpha: fadeArc)],
          stops: const [0, 0.7, 1],
          transform: GradientRotation(start),
        ).createShader(track);
      if (!solid) {
        canvas.drawArc(track, start, len, false, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = K.sun.withValues(alpha: 0.16 * fadeArc)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }
      canvas.drawArc(track, start, len, false, arc);
    }

    // A tap: a soft ring going out and fading.
    final p = pulse;
    if (p != null && p >= 0 && p < 1) {
      final e = Curves.easeOutCubic.transform(p);
      canvas.drawCircle(c, r + 46 * e, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = white.withValues(alpha: 0.38 * (1 - p)));
    }
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.show != show || old.sweep != sweep || old.grow != grow || old.pulse != pulse || old.solid != solid || old.still != still;
}

/// "Try again", as a clear glass capsule on the green.
class _RetryPill extends StatelessWidget {
  const _RetryPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPress(
      onTap: onTap,
      child: Glass(
        tone: GlassTone.dark,
        padding: const EdgeInsetsDirectional.fromSTEB(14, 9, 18, 9),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: T.button.copyWith(color: Colors.white, fontSize: 13.5)),
        ]),
      ),
    );
  }
}
