import 'dart:math' as math;

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

  /// Opens a chit inside a footer tab (Chits unless told otherwise), so the
  /// footer stays below it. The list refreshes when it closes.
  Future<void> _open(KuriRecord k, [int inTab = 0]) async {
    final nav = _navs[inTab].currentState;
    if (nav == null) return;
    await nav.push(MaterialPageRoute<void>(builder: (_) => KuriScreen(record: k)));
    _load();
  }

  Future<void> _create() async {
    final nav = _navs[0].currentState;
    if (nav == null) return;
    final made = await nav.push<KuriRecord>(MaterialPageRoute(builder: (_) => const KuriEditorScreen()));
    if (made == null || !mounted) return;
    await _open(made);
  }


  /// The footer tab on show: 0 chits, 1 to collect, 2 profile.
  int tab = 0;

  /// Each footer tab has its own pile of open screens, like the tab bar on an
  /// iPhone: a chit opened from a tab opens inside it, with the footer still
  /// below, and the tab keeps it open while another tab is looked at.
  final List<GlobalKey<NavigatorState>> _navs = List.generate(3, (i) => GlobalKey<NavigatorState>(debugLabel: 'tab $i'));

  /// Another tab: shows it as it was left. The tab already on show: back to
  /// its first screen. A chit with unsaved changes asks before it closes.
  void _tap(int i) {
    if (i != tab) {
      setState(() => tab = i);
      return;
    }
    final nav = _navs[i].currentState;
    if (nav == null || !nav.canPop()) return;
    nav.popUntil((r) => r.isFirst || r.popDisposition == RoutePopDisposition.doNotPop);
    if (nav.canPop()) nav.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _TabShell(
      body: IndexedStack(
        index: tab,
        sizing: StackFit.expand,
        children: [_stack(0, _chitsTab(s)), _stack(1, _collectTab(s)), _stack(2, _profileTab())],
      ),
      footer: KNavBar(
        index: tab,
        onTap: _tap,
        items: [
          KNavItem(Icons.savings_outlined, Icons.savings_rounded, s.tabChits),
          KNavItem(Icons.payments_outlined, Icons.payments_rounded, s.tabCollect),
          KNavItem(Icons.person_outline_rounded, Icons.person_rounded, s.tabProfile),
        ],
      ),
    );
  }

  /// One tab's own navigator. Its first screen is a page, so it is rebuilt
  /// whenever the chits or the person change. The phone's back button and the
  /// back swipe close the tab's open screens first, then leave the app.
  Widget _stack(int i, Widget first) {
    return NavigatorPopHandler<Object?>(
      enabled: i == tab,
      onPopWithResult: (_) {
        if (i == tab) _navs[i].currentState?.maybePop();
      },
      child: Navigator(
        key: _navs[i],
        pages: [MaterialPage<void>(key: ValueKey('tab-$i'), child: first)],
        onDidRemovePage: (_) {},
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
          : CollectList(kuris: kuris!, onOpen: (k) => _open(k, 1), onRefresh: _load),
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
    return RefreshIndicator(
      color: K.green,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xs, Sp.page, 112),
        children: [
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

/// The tab on show above, the footer below. Not a Scaffold: each screen in a
/// tab is its own Scaffold, so its messages still pop up just above its own
/// bottom bar (Save, Start the chit). The screens are told that the footer
/// takes the phone's bottom inset, and that the keyboard, which slides up
/// over the footer, covers only as much as rises above it.
class _TabShell extends StatelessWidget {
  const _TabShell({required this.body, required this.footer});
  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final under = KNavBar.height + mq.padding.bottom;
    final inner = mq.removePadding(removeBottom: true).copyWith(
          viewInsets: mq.viewInsets.copyWith(bottom: math.max(0.0, mq.viewInsets.bottom - under)),
        );
    return Material(
      color: K.paper,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: MediaQuery(data: inner, child: body)),
        footer,
      ]),
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
