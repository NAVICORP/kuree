import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/config.dart';
import '../core/format.dart';
import '../core/kuri.dart';
import '../core/messages.dart';
import '../draw/bottle_draw_screen.dart';
import '../l10n/strings.dart';
import 'admins_screen.dart';
import 'glass.dart';
import 'history_screen.dart';
import 'kuri_editor.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Filter { all, due, paid }

/// One chit, a month at a time: who paid, late fines, who takes the pot.
/// Changes are made here and published with Save.
class KuriScreen extends StatefulWidget {
  const KuriScreen({super.key, required this.record});
  final KuriRecord record;

  @override
  State<KuriScreen> createState() => _KuriScreenState();
}

class _KuriScreenState extends State<KuriScreen> {
  late KuriRecord rec = widget.record;
  late KuriDoc doc = rec.doc.copy();
  late int sel = doc.currentMonth() - 1;
  _Filter filter = _Filter.all;
  final Set<int> unfolded = {};
  bool dirty = false;
  bool saving = false;

  Month get m => doc.months[sel.clamp(0, doc.months.length - 1)];

  @override
  void initState() {
    super.initState();
    _reload(quiet: true);
  }

  Future<void> _reload({bool quiet = false}) async {
    try {
      final j = await Api.instance.rpc('get_kuri', {'id': rec.id});
      if (!mounted || j is! Map) return;
      if (dirty && quiet) return;
      setState(() {
        rec = KuriRecord.fromJson(Map<String, dynamic>.from(j));
        doc = rec.doc.copy();
        dirty = false;
        if (sel >= doc.months.length) sel = doc.months.length - 1;
      });
    } on ApiError catch (e) {
      if (!quiet && mounted) toast(context, e.message, bad: true);
      if (e.status == 403 || e.code == '42501') {
        if (mounted) Navigator.of(context).maybePop();
      }
    }
  }

  void _change(VoidCallback fn) {
    setState(() {
      fn();
      dirty = true;
    });
  }

  /// Publishes the working copy. Returns true when it saved.
  Future<bool> _save({String? done}) async {
    if (saving) return false;
    setState(() => saving = true);
    try {
      doc.updated = DateTime.now().toIso8601String().substring(0, 10);
      final j = await Api.instance.rpc('save_kuri', {'id': rec.id, 'data': doc.toJson(), 'expected': rec.updatedAtRaw});
      if (!mounted) return true;
      setState(() {
        rec = KuriRecord.fromJson(Map<String, dynamic>.from(j as Map));
        doc = rec.doc.copy();
        dirty = false;
      });
      HapticFeedback.mediumImpact();
      toast(context, done ?? S.of(context).savedMembersSee);
      return true;
    } on ApiError catch (e) {
      if (!mounted) return false;
      if (e.isConflict) {
        final s = S.of(context);
        final reload = await confirm(context, title: s.conflictTitle, text: s.conflictText, yes: s.reload);
        if (reload) {
          setState(() => dirty = false);
          await _reload();
        }
      } else {
        toast(context, e.message, bad: true);
      }
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ---------------------------------------------------------------- who takes the pot

  Future<void> _choose() async {
    final t = S.of(context);
    final w = doc.drawn();
    final k = doc.winnersIn(m.n);
    if (k > 1) {
      final picked = await showWinnersPicker(context, doc, m);
      if (picked == null) return;
      _change(() {
        m.winners
          ..clear()
          ..addAll(picked);
        if (m.draw != null && !m.fromBottle) m.draw = null;
      });
      return;
    }
    final options = <PickOption<int>>[
      for (var s = 1; s <= doc.slots; s++)
        if (!w.containsKey(s) || w[s] == m.n) PickOption(s, doc.slotName(s), sub: t.slotN(s), badge: '$s'),
      if (m.hasWinner) PickOption(0, t.nobodyYet, sub: t.clearChoice, icon: Icons.close_rounded),
    ];
    final picked = await showPicker<int>(context, title: t.takesPotInMonth(m.n), options: options, selected: m.hasWinner ? m.winners.first : null);
    if (picked == null) return;
    _change(() {
      m.winners
        ..clear()
        ..addAll([if (picked.value != 0) picked.value]);
      if (m.draw != null && !m.fromBottle) m.draw = null;
    });
  }

  /// The bottle draw for the month's open places, or [extra] more taken
  /// with money kept in hand.
  /// One more taker this month, chosen by hand, paid from money in hand.
  Future<void> _chooseExtra() async {
    final t = S.of(context);
    final options = [for (final s in doc.waitingSlots()) PickOption(s, doc.slotName(s), sub: t.slotN(s), badge: '$s')];
    final picked = await showPicker<int>(context, title: t.extraChooseTitle(m.n), options: options);
    if (picked == null) return;
    _change(() => m.winners.add(picked.value));
  }

  Future<void> _bottle({int extra = 0}) async {
    final waiting = doc.waitingSlots();
    final month = m;
    final count = extra > 0 ? extra : doc.openIn(month);
    if (count < 1) return;
    if (waiting.length <= count) {
      final s = S.of(context);
      toast(
        context,
        waiting.isEmpty ? s.allSlotsTaken : (waiting.length == 1 ? s.onlyOneLeft(doc.slotName(waiting.first)) : s.onlyFewLeft(doc.slotsName(waiting))),
        bad: true,
      );
      return;
    }
    final kept = List<int>.of(month.winners);
    final each = doc.payoutOf(month, kept.length);
    // The draw fills the whole screen, over the footer.
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BottleDrawScreen(
        title: doc.fullName,
        month: month.n,
        label: doc.monthLabel(month.n),
        pot: doc.pot,
        each: doc.winnersIn(month.n) > 1 || extra > 0 || each != doc.pot ? each : null,
        count: count,
        currency: doc.currency,
        entries: [for (final s in waiting) DrawEntry(s, doc.slotName(s))],
        resultText: (slots, names, when) => drawResult(doc, month.n, slots, names, when),
        onSave: (slots, info) async {
          final before = (List<int>.of(month.winners), month.draw);
          setState(() {
            month.winners
              ..clear()
              ..addAll([...kept, ...slots]);
            month.draw = info;
            dirty = true;
          });
          final ok = await _save(done: S.current.savedMonthGoesTo(month.n, doc.slotsName(slots)));
          if (!ok) {
            setState(() {
              month.winners
                ..clear()
                ..addAll(before.$1);
              month.draw = before.$2;
            });
          }
          return ok;
        },
        by: Api.instance.name,
      ),
    ));
  }

  Future<void> _drawRest() async {
    final now = doc.currentMonth();
    final order = await showDrawRestSheet(context, doc, now);
    if (order == null || !mounted) return;
    _change(() {
      order.forEach((n, slots) => doc.months[n - 1].winners.addAll(slots));
    });
    toast(context, S.of(context).drawDonePressSave);
  }

  // ---------------------------------------------------------------- the rest of the menu

  Future<void> _reminders() async {
    await showRemindersSheet(context, doc, m, rec.shareToken, onAddNumber: (person) async {
      final phone = await askPhone(context, person.name, person.phone);
      if (phone == null) return;
      _change(() => person.phone = phone);
      if (mounted) toast(context, S.of(context).numberAddedPressSave);
    });
  }

  Future<void> _link() async {
    final reset = await showLinkSheet(context, doc, rec.shareToken);
    if (reset != true || !mounted) return;
    final s = S.of(context);
    if (!await confirm(context, title: s.newLinkTitle, text: s.newLinkText, yes: s.newLinkYes)) {
      return;
    }
    try {
      final j = await Api.instance.rpc('reset_share_link', {'id': rec.id});
      if (!mounted) return;
      setState(() => rec.shareToken = '${(j as Map)['share_token']}');
      await showLinkSheet(context, doc, rec.shareToken);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    }
  }

  Future<void> _report() async {
    toast(context, S.of(context).makingSheet);
    try {
      final bytes = await Api.instance.download(reportUrl(rec.shareToken));
      final dir = await getTemporaryDirectory();
      final safe = doc.fullName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '').toLowerCase();
      final f = File('${dir.path}/${safe.isEmpty ? 'chit' : safe}.xlsx');
      await f.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], title: doc.fullName));
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    }
  }

  /// The chit's late fine, changed here without opening Edit.
  Future<void> _editFine() async {
    final value = await askFine(context, doc.fine, doc.currency);
    if (value == null || value == doc.fine || !mounted) return;
    _change(() => doc.setFine(value));
    final s = S.of(context);
    toast(context, value > 0 ? s.fineChangedPressSave(doc.money(value)) : s.fineOffPressSave);
  }

  Future<void> _edit() async {
    final s = S.of(context);
    if (dirty && !await confirm(context, title: s.saveFirstTitle, text: s.saveFirstText, yes: s.save)) return;
    if (dirty && !await _save()) return;
    if (!mounted) return;
    final updated = await Navigator.of(context).push<KuriRecord>(MaterialPageRoute(builder: (_) => KuriEditorScreen(record: rec)));
    if (updated == null || !mounted) return;
    setState(() {
      rec = updated;
      doc = rec.doc.copy();
      dirty = false;
      if (sel >= doc.months.length) sel = doc.months.length - 1;
    });
  }

  Future<void> _delete() async {
    final s = S.of(context);
    final ok = await confirm(context, title: s.deleteChitTitle(doc.name), text: s.deleteChitText, yes: s.delete, danger: true);
    if (!ok) return;
    try {
      await Api.instance.rpc('delete_kuri', {'id': rec.id});
      if (mounted) Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    }
  }

  Future<void> _menu() async {
    final s = S.of(context);
    final pick = await showPicker<String>(context, title: doc.name, options: [
      PickOption('link', s.membersLink, sub: s.membersLinkSub, icon: Icons.link_rounded),
      PickOption('rest', s.drawRest, sub: s.drawRestSub, icon: Icons.shuffle_rounded),
      PickOption('report', s.spreadsheet, sub: s.spreadsheetSub, icon: Icons.table_chart_outlined),
      PickOption('history', s.history, sub: s.historySub, icon: Icons.history_rounded),
      PickOption('admins', s.admins, sub: s.adminsSub, icon: Icons.admin_panel_settings_outlined),
      PickOption('fine', s.lateFine, sub: doc.fine > 0 ? s.fineEach(doc.money(doc.fine)) : s.addLateFine, icon: Icons.schedule_rounded),
      PickOption('edit', s.editChit, sub: s.editChitSub, icon: Icons.tune_rounded),
      if (rec.isOwner) PickOption('delete', s.deleteChit, icon: Icons.delete_outline_rounded),
    ]);
    if (!mounted || pick == null) return;
    switch (pick.value) {
      case 'link':
        await _link();
      case 'rest':
        await _drawRest();
      case 'report':
        await _report();
      case 'history':
        final restored = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => HistoryScreen(record: rec, current: doc)));
        if (restored == true) await _reload();
      case 'admins':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminsScreen(record: rec)));
      case 'fine':
        await _editFine();
      case 'edit':
        await _edit();
      case 'delete':
        await _delete();
    }
  }

  // ---------------------------------------------------------------- the page

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirm(context, title: s.leaveTitle, text: s.leaveText, yes: s.leave, danger: true);
        if (leave && context.mounted) {
          setState(() => dirty = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBody: MediaQuery.viewInsetsOf(context).bottom == 0,
        appBar: AppBar(
          titleSpacing: Sp.xs,
          title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (doc.group.trim().isNotEmpty)
              Text(doc.group, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small.copyWith(color: K.green, fontWeight: FontWeight.w800)),
            Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.h3.copyWith(fontSize: 17)),
          ]),
          actions: [
            RoundIcon(Icons.link_rounded, tooltip: s.membersLink, onTap: _link),
            RoundIcon(Icons.more_horiz_rounded, tooltip: s.more, onTap: _menu),
            const SizedBox(width: Sp.xs),
          ],
        ),
        // The body runs under the footer and the Save bar; its own padding
        // says how much of its bottom they cover.
        body: Builder(
          builder: (context) => RefreshIndicator(
            color: K.green,
            onRefresh: () async {
              if (dirty) {
                toast(context, s.saveChangesFirst);
                return;
              }
              await _reload();
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(Sp.page, Sp.xs, Sp.page, 32 + MediaQuery.paddingOf(context).bottom),
              children: [
                _hero(s),
                const SizedBox(height: Sp.md + 2),
                _winner(s),
                const SizedBox(height: Sp.md + 2),
                _actions(s),
                const SizedBox(height: Sp.md + 2),
                _members(s),
                const SizedBox(height: Sp.xl),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.history_rounded, size: 16, color: K.muted),
                  const SizedBox(width: 6),
                  Flexible(child: Text(s.historyKept, style: T.small, textAlign: TextAlign.center)),
                ]),
                if (rec.updatedBy != null && rec.updatedAt != null) ...[
                  const SizedBox(height: Sp.xs),
                  Text(s.lastSavedBy(rec.updatedBy!, ago(rec.updatedAt!)), style: T.small, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (c, a) => SizeTransition(sizeFactor: a, child: c),
          // With nothing to save, an empty strip the height of the footer
          // still tells the list how much of its bottom the glass covers.
          child: dirty ? _saveBar(s) : SizedBox(key: const ValueKey('none'), height: MediaQuery.paddingOf(context).bottom),
        ),
      ),
    );
  }

  /// Unsaved changes: a glass bar floats over the bottom of the chit, just
  /// above the footer, with Undo and Save.
  Widget _saveBar(S s) {
    return KeyedSubtree(
      key: const ValueKey('save'),
      child: GlassBar(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 2),
          child: Row(children: [
            const Icon(Icons.edit_note_rounded, color: K.warn),
            const SizedBox(width: Sp.sm),
            Expanded(child: Text(s.notSavedYet, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.label.copyWith(color: K.ink))),
            Flexible(
              child: KButton(
                label: s.undo,
                kind: KButtonKind.ghost,
                small: true,
                onPressed: saving
                    ? null
                    : () => setState(() {
                          doc = rec.doc.copy();
                          dirty = false;
                        }),
              ),
            ),
            const SizedBox(width: Sp.xs),
            Flexible(
              flex: 2,
              child: KButton(label: s.save, icon: Icons.check_rounded, busy: saving, onPressed: () => _save()),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _hero(S s) {
    final got = doc.paidSum(m), fines = doc.fineSum(m), paid = doc.paidCount(m), n = doc.payers.length;
    final pct = doc.pot == 0 ? 0.0 : got / doc.pot;
    final deadline = doc.deadline(m.n);
    return HeroCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          RoundIcon(Icons.chevron_left_rounded, dark: true, tooltip: s.prevMonth, onTap: sel > 0 ? () => setState(() => sel--) : null),
          Expanded(
            child: Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pickMonth,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.emoji_events_rounded, size: 17, color: K.heroText),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(s.monthNLabel(m.n, doc.monthLabel(m.n)),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label.copyWith(color: K.heroText, fontSize: 14.5)),
                    ),
                    const Icon(Icons.expand_more_rounded, size: 18, color: K.heroText),
                  ]),
                ),
              ),
            ),
          ),
          RoundIcon(Icons.chevron_right_rounded,
              dark: true, tooltip: s.nextMonth, onTap: sel < doc.months.length - 1 ? () => setState(() => sel++) : null),
        ]),
        const SizedBox(height: Sp.lg),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(doc.money(got), style: T.amount),
        ),
        const SizedBox(height: Sp.xs),
        Text(fines > 0 ? s.collectedOfFines(doc.money(doc.pot), doc.money(fines)) : s.collectedOf(doc.money(doc.pot)),
            style: T.small.copyWith(color: K.heroText, fontWeight: FontWeight.w600)),
        const SizedBox(height: Sp.md + 2),
        ProgressLine(pct),
        const SizedBox(height: Sp.md),
        Row(children: [
          Expanded(child: Text(s.paidOfTotal(paid, n), maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label.copyWith(color: Colors.white))),
          const SizedBox(width: Sp.sm),
          Text(n - paid > 0 ? s.toGo(n - paid) : s.everyonePaid, style: T.small.copyWith(color: K.heroText)),
        ]),
        const SizedBox(height: Sp.md),
        Container(height: 1, color: const Color(0x1FFFFFFF)),
        const SizedBox(height: Sp.md),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.schedule_rounded, size: 15, color: K.heroText)),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Text(
              s.heroCollection(doc.collectDate(m.n).day, doc.monthShort(m.n), deadline.day, monthShortName(deadline.month), doc.nextNote(m.n)),
              style: T.small.copyWith(color: K.heroText),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _pickMonth() async {
    final s = S.of(context);
    final picked = await showPicker<int>(context, title: s.month, selected: m.n, options: [
      for (final x in doc.months)
        PickOption(x.n, doc.monthLabel(x.n),
            badge: '${x.n}',
            sub: switch (doc.state(x)) {
              MonthState.done => s.settled,
              MonthState.open => !x.hasWinner ? s.inProgress : _takes(s.inProgressTakes, s.inProgressTake, x),
              MonthState.soon => !x.hasWinner ? s.upcoming : _takes(s.upcomingTakes, s.upcomingTake, x),
            }),
    ]);
    if (picked != null) setState(() => sel = picked.value - 1);
  }

  /// "In progress, Nazil takes the pot", or with several takers "In
  /// progress, Nazil and Anwar take the pot".
  String _takes(String Function(Object) one, String Function(Object) many, Month x) =>
      x.winners.length > 1 ? many(doc.winnersName(x)!) : one(doc.winnersName(x)!);

  /// The organiser's month: no draw, the collection goes to the organiser.
  Widget _organiser(S s) => KCard(
        padding: const EdgeInsets.all(Sp.lg),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: K.sun, shape: BoxShape.circle),
            child: const Icon(Icons.workspace_premium_rounded, color: K.deep, size: 22),
          ),
          const SizedBox(width: Sp.md + 2),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.organiserMonth, style: T.h3),
              const SizedBox(height: 2),
              Text(
                  doc.organiserName.isEmpty
                      ? s.organiserTakes(doc.money(doc.monthTotal(m)))
                      : s.organiserTakesNamed(doc.organiserName, doc.money(doc.monthTotal(m))),
                  style: T.small.copyWith(color: K.brand600, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      );

  /// What this month keeps in hand for later months, or takes from it, in a
  /// chit whose takers are not the same every month. Null when it is even.
  String? _keptNote(S s) {
    final kept = doc.keptIn(m.n);
    if (kept == 0) return null;
    final hand = doc.money(doc.inHandAfter(m.n));
    return kept > 0 ? s.keptForLater(doc.money(kept), hand) : s.fromKept(doc.money(-kept), hand);
  }

  /// When the money in hand covers one more payout: a draw for one more
  /// taker this month. Nothing otherwise.
  List<Widget> _extraStrip(S s) {
    if (!doc.canDrawExtra(m)) return const [];
    return [
      const SizedBox(height: Sp.md + 2),
      Container(
        padding: const EdgeInsets.all(Sp.md + 2),
        decoration: BoxDecoration(color: K.brand100, borderRadius: BorderRadius.circular(K.rSm)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(s.extraDrawTitle, style: T.bodyStrong),
          const SizedBox(height: 2),
          Text(s.extraDrawText(doc.money(doc.inHandAfter(m.n)), doc.money(doc.payout)), style: T.small),
          const SizedBox(height: Sp.md),
          Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
            KButton(label: s.extraDraw, icon: Icons.casino_outlined, kind: KButtonKind.sun, small: true, onPressed: () => _bottle(extra: 1)),
            KButton(label: s.choose, icon: Icons.touch_app_outlined, kind: KButtonKind.secondary, small: true, onPressed: _chooseExtra),
          ]),
        ]),
      ),
    ];
  }

  Widget _winner(S s) {
    if (doc.isOrganiserMonth(m.n)) return _organiser(s);
    if (doc.winnersIn(m.n) > 1) return _winners(s);
    final fines = doc.fineSum(m);
    final fromBottle = m.fromBottle;
    final winner = m.hasWinner ? m.winners.first : null;
    final paid = doc.payoutOf(m, 0);
    var amount = fines > 0 ? s.winnerAmountFine(doc.money(paid), doc.money(fines)) : doc.money(paid);
    final kept = _keptNote(s);
    if (fromBottle) amount = s.pickedFromBottle(amount);
    return KCard(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: winner == null ? K.surface2 : K.sun, shape: BoxShape.circle),
            child: Icon(Icons.emoji_events_rounded, color: winner == null ? K.muted : K.deep, size: 22),
          ),
          const SizedBox(width: Sp.md + 2),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.takesPotThisMonth, style: T.small),
              const SizedBox(height: 2),
              Text(winner == null ? s.notDecided : '$winner. ${doc.slotName(winner)}', style: T.h3),
              if (winner != null) ...[
                const SizedBox(height: 2),
                Text(amount, style: T.small.copyWith(color: K.brand600, fontWeight: FontWeight.w700)),
              ],
              if (kept != null) ...[
                const SizedBox(height: 2),
                Text(kept, style: T.small),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: Sp.md + 2),
        Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
          if (winner == null) KButton(label: s.bottleDraw, icon: Icons.casino_outlined, kind: KButtonKind.sun, small: true, onPressed: _bottle),
          KButton(
            label: winner == null ? s.choose : s.change,
            icon: winner == null ? Icons.touch_app_outlined : Icons.swap_horiz_rounded,
            kind: KButtonKind.secondary,
            small: true,
            onPressed: _choose,
          ),
        ]),
        ..._extraStrip(s),
      ]),
    );
  }

  /// A month with several takers: each one with what they get, the places
  /// still open, and the draw for those.
  Widget _winners(S s) {
    final k = doc.winnersIn(m.n), fines = doc.fineSum(m), open = doc.openIn(m);
    final pays = doc.payouts(m);
    final even = pays.every((x) => x == pays.first);
    var note = fines > 0 ? s.eachTakesFine(doc.money(pays.first), doc.money(fines)) : s.eachTakes(doc.money(pays.first));
    if (m.fromBottle) note = s.pickedFromBottle(note);
    final kept = _keptNote(s);
    Widget row(Widget badge, String title, String? amount) => Padding(
          padding: const EdgeInsets.only(top: Sp.sm),
          child: Row(children: [
            badge,
            const SizedBox(width: Sp.md),
            Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.bodyStrong)),
            if (amount != null) ...[
              const SizedBox(width: Sp.sm),
              Text(amount, style: T.label.merge(T.tabular).copyWith(color: K.brand600)),
            ],
          ]),
        );
    return KCard(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: m.hasWinner ? K.sun : K.surface2, shape: BoxShape.circle),
            child: Icon(Icons.emoji_events_rounded, color: m.hasWinner ? K.deep : K.muted, size: 22),
          ),
          const SizedBox(width: Sp.md + 2),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.takePotThisMonthN(k), style: T.h3),
              const SizedBox(height: 2),
              Text(note, style: T.small.copyWith(color: K.brand600, fontWeight: FontWeight.w700)),
              if (kept != null) ...[
                const SizedBox(height: 2),
                Text(kept, style: T.small),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: Sp.xs),
        for (var i = 0; i < m.winners.length; i++)
          row(SlotBadge('${m.winners[i]}', size: 32, style: SlotBadgeStyle.sun), doc.slotName(m.winners[i]), even ? null : doc.money(pays[i])),
        for (var i = 0; i < open; i++)
          row(
            const SlotBadge('?', size: 32),
            s.notDecided,
            even ? null : doc.money(pays[min(m.winners.length + i, pays.length - 1)]),
          ),
        const SizedBox(height: Sp.md + 2),
        Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
          if (open > 0)
            KButton(
              label: open == k ? s.bottleDraw : s.bottleDrawMore(open),
              icon: Icons.casino_outlined,
              kind: KButtonKind.sun,
              small: true,
              onPressed: _bottle,
            ),
          KButton(
            label: m.hasWinner ? s.change : s.choose,
            icon: m.hasWinner ? Icons.swap_horiz_rounded : Icons.touch_app_outlined,
            kind: KButtonKind.secondary,
            small: true,
            onPressed: _choose,
          ),
        ]),
        ..._extraStrip(s),
      ]),
    );
  }

  Widget _actions(S s) {
    final everyone = doc.allPaid(m);
    return Row(children: [
      if (!everyone) ...[
        Expanded(
          child: KButton(
            label: s.allPaid,
            icon: Icons.done_all_rounded,
            kind: KButtonKind.secondary,
            expand: true,
            onPressed: () => _change(() {
              for (final p in doc.payers) {
                m.paid[p.id] = true;
              }
            }),
          ),
        ),
        const SizedBox(width: Sp.md - 2),
      ],
      Expanded(
        child: KButton(label: s.reminders, icon: Icons.chat_outlined, kind: KButtonKind.secondary, expand: true, onPressed: _reminders),
      ),
    ]);
  }

  Widget _members(S s) {
    final n = doc.payers.length, paid = doc.paidCount(m);
    final everyone = n > 0 && paid >= n;
    if (everyone && !unfolded.contains(m.n)) {
      return KCard(
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, color: K.leaf, size: 26),
          const SizedBox(width: Sp.md),
          Expanded(child: Text(s.everyonePaidFor(m.n), style: T.bodyStrong)),
          KButton(label: s.showList, small: true, kind: KButtonKind.ghost, onPressed: () => setState(() => unfolded.add(m.n))),
        ]),
      );
    }
    final w = doc.drawn();
    final rows = <Widget>[];
    for (final p in doc.payers) {
      final isPaid = m.isPaid(p.id);
      if (filter == _Filter.due && isPaid) continue;
      if (filter == _Filter.paid && !isPaid) continue;
      rows.add(_MemberRow(
        doc: doc,
        payer: p,
        month: m,
        tookIn: w[p.slot],
        onPaid: () => _change(() {
          if (m.isPaid(p.id)) {
            m.paid.remove(p.id);
            m.fines.remove(p.id);
          } else {
            m.paid[p.id] = true;
          }
        }),
        onLate: () => _change(() {
          if (m.isFined(p.id)) {
            m.fines.remove(p.id);
          } else {
            m.fines[p.id] = true;
            m.paid[p.id] = true;
          }
        }),
      ));
    }
    return KCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 10),
          child: Row(children: [
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: KSegmented<_Filter>(
                  value: filter,
                  onChanged: (v) => setState(() => filter = v),
                  items: [(_Filter.all, s.filterAll(n)), (_Filter.due, s.filterDue(n - paid)), (_Filter.paid, s.filterPaid(paid))],
                ),
              ),
            ),
            if (everyone) KButton(label: s.hideList, small: true, kind: KButtonKind.ghost, onPressed: () => setState(() => unfolded.remove(m.n))),
          ]),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.tickHelp, style: T.small),
            const SizedBox(height: Sp.sm),
            // The fine a Late adds, and the way to change it.
            KButton(
              label: doc.fine > 0 ? s.fineChip(doc.money(doc.fine)) : s.addLateFine,
              icon: doc.fine > 0 ? Icons.edit_outlined : Icons.add_rounded,
              kind: KButtonKind.secondary,
              small: true,
              onPressed: _editFine,
            ),
          ]),
        ),
        const Divider(),
        if (rows.isEmpty)
          EmptyState(
            icon: Icons.check_rounded,
            text: filter == _Filter.due ? s.everyonePaidMonth(m.n) : s.nobodyPaidMonth(m.n),
          ),
        for (var i = 0; i < rows.length; i++) ...[if (i > 0) const Divider(), rows[i]],
      ]),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.doc, required this.payer, required this.month, required this.tookIn, required this.onPaid, required this.onLate});
  final KuriDoc doc;
  final Payer payer;
  final Month month;
  final int? tookIn;
  final VoidCallback onPaid;
  final VoidCallback onLate;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final paid = month.isPaid(payer.id), late = month.isFined(payer.id), won = month.takes(payer.slot);
    final part = doc.partLabel(payer);
    var status = paid ? s.statusPaid(doc.money(payer.amt)) : s.statusPending(doc.money(payer.amt));
    if (late) status = s.statusLateFine(status, doc.money(doc.fineFor(month)));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: won
            ? const LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [K.brand100, Color(0x00E4F1E8)],
                stops: [0, 0.7],
              )
            : null,
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 10, 10),
      child: Row(children: [
        SlotBadge('${payer.slot}', style: won ? SlotBadgeStyle.winner : (paid ? SlotBadgeStyle.paid : SlotBadgeStyle.plain)),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(doc.nameOf(payer), style: T.bodyStrong),
              if (part != null) Pill(part),
            ]),
            const SizedBox(height: 2),
            Wrap(spacing: 8, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(status, style: T.small.copyWith(color: paid ? K.brand600 : K.muted, fontWeight: paid ? FontWeight.w700 : FontWeight.w600)),
              if (tookIn != null) Pill(s.monthN(tookIn!), icon: Icons.emoji_events_rounded, color: K.sunSoft, fg: K.warn),
            ]),
          ]),
        ),
        const SizedBox(width: Sp.xs),
        _LateButton(on: late, onTap: onLate, name: doc.nameOf(payer)),
        const SizedBox(width: Sp.xs),
        _Tick(on: paid, onTap: onPaid, name: doc.nameOf(payer)),
      ]),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.on, required this.onTap, required this.name});
  final bool on;
  final VoidCallback onTap;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: on,
      label: S.of(context).semPaid(name),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: on ? K.green : K.surface,
            shape: BoxShape.circle,
            border: Border.all(color: on ? K.green : K.border2, width: 2),
          ),
          child: Icon(Icons.check_rounded, color: on ? Colors.white : K.border2, size: 21),
        ),
      ),
    );
  }
}

class _LateButton extends StatelessWidget {
  const _LateButton({required this.on, required this.onTap, required this.name});
  final bool on;
  final VoidCallback onTap;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: on,
      label: S.of(context).semLate(name),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        // 48 tall to tap, 36 tall to see.
        child: SizedBox(
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: on ? K.badBg : K.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? K.badBg : K.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.schedule_rounded, size: 14, color: on ? K.bad : K.muted),
                const SizedBox(width: 4),
                Text(S.of(context).lateButton, style: T.label.copyWith(fontSize: 12, color: on ? K.bad : K.muted)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a link outside the app.
Future<void> openOutside(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) toast(context, S.of(context).couldNotOpen, bad: true);
}

/// Copies text and says so.
Future<void> copyText(BuildContext context, String text, [String? said]) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) toast(context, said ?? S.of(context).copied);
}

String linkFor(String token) => shareUrl(token);
