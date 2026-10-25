import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/kuri.dart';
import '../l10n/strings.dart';
import 'account.dart';
import 'collect_screen.dart';
import 'kuri_editor.dart';
import 'kuri_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Every chit this person runs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.preview});

  /// Chits and the signed-in person to show without asking the server (screenshots).
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
    final name = await askName(context, title: S.of(context).askNameTitle, initial: '');
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
    final s = S.of(context);
    setState(() => importing = true);
    try {
      final r = await Api.instance.function('import-boystown');
      if (!mounted) return;
      toast(context, s.importDone);
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

  /// The footer tab on show: 0 chits, 1 to collect, 2 profile.
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: IndexedStack(index: tab, children: [_chitsTab(s), _collectTab(s), _profileTab()]),
      bottomNavigationBar: KNavBar(
        index: tab,
        onTap: (i) => setState(() => tab = i),
        items: [
          KNavItem(Icons.savings_outlined, Icons.savings_rounded, s.tabChits),
          KNavItem(Icons.payments_outlined, Icons.payments_rounded, s.tabCollect),
          KNavItem(Icons.person_outline_rounded, Icons.person_rounded, s.tabProfile),
        ],
      ),
    );
  }

  Widget _chitsTab(S s) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: Sp.xl,
        title: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/brand/icon.png', width: 28, height: 28)),
          const SizedBox(width: 10),
          const Text('Kuree', style: TextStyle(fontFamily: 'Bricolage', fontSize: 21, fontWeight: FontWeight.w600, color: K.ink, letterSpacing: 0)),
        ]),
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
              label: Text(s.newChit, style: T.button.copyWith(color: Colors.white)),
            ),
      body: _body(s),
    );
  }

  Widget _collectTab(S s) {
    return Scaffold(
      appBar: AppBar(titleSpacing: Sp.xl, title: Text(s.tabCollect)),
      body: kuris == null
          ? (error != null ? LoadFailed(message: error!, onRetry: _load) : const Loading())
          : CollectList(kuris: kuris!, onOpen: _open, onRefresh: _load),
    );
  }

  /// Name, language, help, legal and the account, as a tab. Rebuilt when the
  /// person's details come back from the server.
  Widget _profileTab() {
    final who = me;
    if (who == null) return const Scaffold(body: Loading());
    return AccountScreen(key: ValueKey(who), me: who, tab: true);
  }

  Widget _body(S s) {
    if (kuris == null && error != null) return LoadFailed(message: error!, onRetry: _load);
    if (kuris == null) return const Loading();
    final canImport = me?['can_import_boystown'] == true;
    return RefreshIndicator(
      color: K.green,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xs, Sp.page, 112),
        children: [
          if (canImport) ...[
            KCard(
              color: K.sunSoft,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
              child: Row(children: [
                const Icon(Icons.download_rounded, color: K.deep),
                const SizedBox(width: Sp.md),
                Expanded(child: Text(s.importTitle, style: T.bodyStrong)),
                const SizedBox(width: Sp.sm),
                KButton(label: s.importButton, small: true, busy: importing, onPressed: _importBoystown),
              ]),
            ),
            const SizedBox(height: Sp.lg),
          ],
          if (kuris!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 72),
              child: EmptyState(
                icon: Icons.savings_outlined,
                text: s.noChits,
                action: KButton(label: s.startChit, icon: Icons.add_rounded, onPressed: _create),
              ),
            )
          else
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 14),
              child: Row(children: [
                Expanded(child: Text(s.yourChits, style: T.h1)),
                Pill('${kuris!.length}', color: K.surface2, fg: K.ink2),
              ]),
            ),
          for (final k in kuris!) ...[
            KuriCard(record: k, onTap: () => _open(k)),
            const SizedBox(height: Sp.md + 2),
          ],
        ],
      ),
    );
  }
}

/// One chit on the home screen: this month at a glance.
class KuriCard extends StatelessWidget {
  const KuriCard({super.key, required this.record, required this.onTap});
  final KuriRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final k = record.doc;
    final n = k.currentMonth();
    final m = k.months.isEmpty ? Month(n: 1) : k.months[n - 1];
    final got = k.paidSum(m);
    final paid = k.paidCount(m);
    final winner = m.winner;
    return KCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (k.group.trim().isNotEmpty)
                Text(k.group, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small.copyWith(color: K.green, fontWeight: FontWeight.w800)),
              Text(k.name, style: T.h2),
            ]),
          ),
          if (!record.isOwner) ...[const SizedBox(width: Sp.sm), Pill(s.roleAdmin, color: K.surface2, fg: K.ink2)],
        ]),
        const SizedBox(height: Sp.xs),
        Text(s.monthOfTotal(n, k.months.length, k.monthLabel(n)), style: T.small),
        const SizedBox(height: Sp.md + 2),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 6, children: [
              Text(k.money(got), style: T.h2.merge(T.tabular)),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(s.ofAmount(k.money(k.pot)), style: T.small),
              ),
            ]),
          ),
          const SizedBox(width: Sp.sm),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(s.paidOfTotal(paid, k.payers.length), style: T.small.copyWith(color: K.ink2, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: Sp.sm),
        ProgressLine(k.pot == 0 ? 0 : got / k.pot, color: K.leaf, track: K.surface2),
        const SizedBox(height: Sp.md),
        Row(children: [
          Icon(winner == null ? Icons.schedule_rounded : Icons.emoji_events_rounded, size: 17, color: winner == null ? K.muted : K.green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              winner == null ? s.collectionNote(k.collectDate(n).day, k.monthShort(n), k.nextNote(n)) : s.takesPotName(k.slotName(winner)),
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
  final s = S.of(context);
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
        decoration: InputDecoration(hintText: s.yourName, counterText: ''),
        onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
      ),
      const SizedBox(height: Sp.lg),
      KButton(label: s.save, icon: Icons.check_rounded, expand: true, onPressed: () => Navigator.of(ctx).pop(c.text.trim())),
    ]),
  );
}
