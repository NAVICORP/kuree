import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/kuri.dart';
import 'account.dart';
import 'kuri_editor.dart';
import 'kuri_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Every kuri this person runs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.preview});

  /// Kuris and the signed-in person to show without asking the server (screenshots).
  final (List<KuriRecord>, Map<String, dynamic>)? preview;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<KuriRecord>? kuris;
  Map<String, dynamic>? me;
  String? error;
  bool importing = false;

  @override
  void initState() {
    super.initState();
    final p = widget.preview;
    if (p != null) {
      kuris = p.$1;
      me = p.$2;
      _asked = true;
      return;
    }
    _load();
  }

  Future<void> _load() async {
    if (widget.preview != null) return;
    try {
      final results = await Future.wait([Api.instance.rpc('my_kuris'), Api.instance.rpc('whoami')]);
      final list = (results[0] as List? ?? const []).whereType<Map>().map((e) => KuriRecord.fromJson(Map<String, dynamic>.from(e))).toList();
      if (!mounted) return;
      setState(() {
        kuris = list;
        me = results[1] is Map ? Map<String, dynamic>.from(results[1] as Map) : <String, dynamic>{};
        error = null;
      });
      Api.instance.name = (me?['display'] as String?) ?? '';
      if ((me?['name'] as String?)?.trim().isEmpty ?? true) _askName();
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  bool _asked = false;
  Future<void> _askName() async {
    if (_asked) return;
    _asked = true;
    final name = await askName(context, title: 'What should we call you?', initial: '');
    if (name == null || name.isEmpty) return;
    try {
      final r = await Api.instance.rpc('set_my_name', {'name': name});
      if (mounted && r is Map) setState(() => me = Map<String, dynamic>.from(r));
      Api.instance.name = (me?['display'] as String?) ?? name;
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    }
  }

  Future<void> _open(KuriRecord k) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => KuriScreen(record: k)));
    _load();
  }

  Future<void> _create() async {
    final made = await Navigator.of(context).push<KuriRecord>(MaterialPageRoute(builder: (_) => const KuriEditorScreen()));
    if (made == null || !mounted) return;
    await _open(made);
  }

  Future<void> _importBoystown() async {
    setState(() => importing = true);
    try {
      final r = await Api.instance.function('import-boystown');
      if (!mounted) return;
      toast(context, 'The Boystown 5K Kuri is in.');
      await _load();
      if (r is Map && r['kuri'] is Map) {
        final rec = KuriRecord.fromJson(Map<String, dynamic>.from(r['kuri'] as Map));
        if (mounted) await _open(rec);
      }
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (me?['display'] as String?) ?? '';
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.asset('assets/brand/icon.png', width: 32, height: 32)),
          const SizedBox(width: 10),
          const Text('Kuree', style: TextStyle(fontFamily: 'Bricolage', fontSize: 24, fontWeight: FontWeight.w700, color: K.ink, letterSpacing: 0)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountScreen(me: me ?? const {})));
                _load();
              },
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: K.deep, shape: BoxShape.circle),
                child: Text(initials(name.isEmpty ? 'K' : name), style: T.label.copyWith(color: K.heroText, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: kuris == null || kuris!.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              backgroundColor: K.deep,
              foregroundColor: Colors.white,
              elevation: 2,
              highlightElevation: 4,
              shape: const StadiumBorder(),
              icon: const Icon(Icons.add_rounded),
              label: Text('New chit', style: T.button.copyWith(color: Colors.white)),
            ),
      body: _body(),
    );
  }

  Widget _body() {
    if (kuris == null && error != null) return LoadFailed(message: error!, onRetry: _load);
    if (kuris == null) return const Loading();
    final canImport = me?['can_import_boystown'] == true;
    return RefreshIndicator(
      color: K.green,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          if (canImport) ...[
            KCard(
              color: K.sunSoft,
              child: Row(children: [
                const Icon(Icons.download_rounded, color: K.deep),
                const SizedBox(width: 12),
                const Expanded(child: Text('Bring in the Boystown 5K Kuri', style: T.bodyStrong)),
                KButton(label: 'Bring in', small: true, busy: importing, onPressed: _importBoystown),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          if (kuris!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: EmptyState(
                icon: Icons.savings_outlined,
                text: 'No chits yet.',
                action: KButton(label: 'Start a chit', icon: Icons.add_rounded, onPressed: _create),
              ),
            ),
          for (final k in kuris!) ...[
            KuriCard(record: k, onTap: () => _open(k)),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

/// One kuri on the home screen: this month at a glance.
class KuriCard extends StatelessWidget {
  const KuriCard({super.key, required this.record, required this.onTap});
  final KuriRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = record.doc;
    final n = k.currentMonth();
    final m = k.months.isEmpty ? Month(n: 1) : k.months[n - 1];
    final got = k.paidSum(m);
    final paid = k.paidCount(m);
    final winner = m.winner;
    return KCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (k.group.trim().isNotEmpty) Text(k.group, style: T.small.copyWith(color: K.green, fontWeight: FontWeight.w800)),
              Text(k.name, style: T.h2),
            ]),
          ),
          if (!record.isOwner) const Pill('Admin', color: K.surface2, fg: K.ink2),
        ]),
        const SizedBox(height: 4),
        Text('Month $n of ${k.months.length}, ${k.monthLabel(n)}', style: T.small),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(money(got), style: T.h2.copyWith(fontSize: 24).merge(T.tabular)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('of ${money(k.pot)}', style: T.small),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('$paid of ${k.payers.length} paid', style: T.small.copyWith(color: K.ink2, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        ProgressLine(k.pot == 0 ? 0 : got / k.pot, color: K.leaf, track: K.surface2),
        const SizedBox(height: 12),
        Row(children: [
          Icon(winner == null ? Icons.schedule_rounded : Icons.emoji_events_rounded, size: 17, color: winner == null ? K.muted : K.green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              winner == null ? 'Collection ${k.collectDate(n).day} ${k.monthShort(n)}, ${k.nextNote(n)}' : 'Takes the pot: ${k.slotName(winner)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.small.copyWith(color: winner == null ? K.muted : K.green, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// Asks for a name in a small sheet.
Future<String?> askName(BuildContext context, {required String title, String initial = ''}) {
  final c = TextEditingController(text: initial);
  return showKSheet<String>(
    context,
    title: title,
    builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: c,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 60,
        style: T.bodyStrong,
        decoration: const InputDecoration(hintText: 'Your name', counterText: ''),
        onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
      ),
      const SizedBox(height: 14),
      KButton(label: 'Save', icon: Icons.check_rounded, expand: true, onPressed: () => Navigator.of(ctx).pop(c.text.trim())),
    ]),
  );
}
