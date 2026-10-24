import 'dart:io';

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
import 'admins_screen.dart';
import 'history_screen.dart';
import 'kuri_editor.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Filter { all, due, paid }

/// One kuri, a month at a time: who paid, late fines, who takes the pot.
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
      toast(context, done ?? 'Saved. Members see it now.');
      return true;
    } on ApiError catch (e) {
      if (!mounted) return false;
      if (e.isConflict) {
        final reload = await confirm(context,
            title: 'Someone else saved this',
            text: 'Another admin saved this kuri a moment ago. Reload to see their change, then make yours again.',
            yes: 'Reload');
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
    final w = doc.drawn();
    final options = <PickOption<int>>[
      for (var s = 1; s <= doc.slots; s++)
        if (!w.containsKey(s) || w[s] == m.n) PickOption(s, doc.slotName(s), sub: 'Slot $s', badge: '$s'),
      if (m.winner != null) const PickOption(0, 'Nobody yet', sub: 'Clear the choice', icon: Icons.close_rounded),
    ];
    final picked = await showPicker<int>(context, title: 'Takes the pot in month ${m.n}', options: options, selected: m.winner);
    if (picked == null) return;
    _change(() {
      m.winner = picked.value == 0 ? null : picked.value;
      if (m.draw != null && m.draw!.picked != m.winner) m.draw = null;
    });
  }

  Future<void> _bottle() async {
    final waiting = doc.waitingSlots();
    if (waiting.length < 2) {
      toast(context,
          waiting.isEmpty ? 'Every slot has already taken the pot.' : 'Only ${doc.slotName(waiting.first)} is left, so there is nothing to draw. Use Choose.',
          bad: true);
      return;
    }
    final month = m;
    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BottleDrawScreen(
        title: doc.fullName,
        month: month.n,
        label: doc.monthLabel(month.n),
        pot: doc.pot,
        entries: [for (final s in waiting) DrawEntry(s, doc.slotName(s))],
        resultText: (slot, names, when) => drawResult(doc, month.n, slot, names, when),
        onSave: (slot, info) async {
          final before = (month.winner, month.draw);
          setState(() {
            month.winner = slot;
            month.draw = info;
            dirty = true;
          });
          final ok = await _save(done: 'Saved. Month ${month.n} goes to ${doc.slotName(slot)}.');
          if (!ok) {
            setState(() {
              month.winner = before.$1;
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
    if (order == null) return;
    _change(() {
      order.forEach((n, slot) => doc.months[n - 1].winner = slot);
    });
    toast(context, 'Draw done. Press Save to publish it.');
  }

  // ---------------------------------------------------------------- the rest of the menu

  Future<void> _reminders() async {
    await showRemindersSheet(context, doc, m, rec.shareToken, onAddNumber: (person) async {
      final phone = await askPhone(context, person.name, person.phone);
      if (phone == null) return;
      _change(() => person.phone = phone);
      if (mounted) toast(context, 'Number added. Press Save to keep it.');
    });
  }

  Future<void> _link() async {
    final reset = await showLinkSheet(context, doc, rec.shareToken);
    if (reset != true || !mounted) return;
    if (!await confirm(context,
        title: 'Make a new link?',
        text: 'The old link stops working straight away. Share the new one in the group.',
        yes: 'Make a new link')) {
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
    toast(context, 'Making the spreadsheet…');
    try {
      final bytes = await Api.instance.download(reportUrl(rec.shareToken));
      final dir = await getTemporaryDirectory();
      final safe = doc.fullName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '').toLowerCase();
      final f = File('${dir.path}/${safe.isEmpty ? 'kuri' : safe}.xlsx');
      await f.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], title: doc.fullName));
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    }
  }

  Future<void> _edit() async {
    if (dirty && !await confirm(context, title: 'Save first?', text: 'Save this month\'s changes before editing the kuri.', yes: 'Save')) return;
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
    final ok = await confirm(context,
        title: 'Delete ${doc.name}?',
        text: 'The kuri, its history and the members\' link are deleted for good. This cannot be undone.',
        yes: 'Delete',
        danger: true);
    if (!ok) return;
    try {
      await Api.instance.rpc('delete_kuri', {'id': rec.id});
      if (mounted) Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, bad: true);
    }
  }

  Future<void> _menu() async {
    final pick = await showPicker<String>(context, title: doc.name, options: [
      const PickOption('link', 'Members\' link', sub: 'Share it in the group', icon: Icons.link_rounded),
      const PickOption('rest', 'Draw the rest', sub: 'Shuffle every month still open', icon: Icons.shuffle_rounded),
      const PickOption('report', 'Spreadsheet', sub: 'Every month, every member', icon: Icons.table_chart_outlined),
      const PickOption('history', 'History', sub: 'Every earlier version', icon: Icons.history_rounded),
      const PickOption('admins', 'Admins', sub: 'Who runs this kuri', icon: Icons.admin_panel_settings_outlined),
      const PickOption('edit', 'Edit kuri', sub: 'Name, amounts, dates, slots, people', icon: Icons.tune_rounded),
      if (rec.isOwner) const PickOption('delete', 'Delete kuri', icon: Icons.delete_outline_rounded),
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
      case 'edit':
        await _edit();
      case 'delete':
        await _delete();
    }
  }

  // ---------------------------------------------------------------- the page

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirm(context, title: 'Leave without saving?', text: 'Your changes to this month are not saved yet.', yes: 'Leave', danger: true);
        if (leave && context.mounted) {
          setState(() => dirty = false);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 4,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (doc.group.trim().isNotEmpty) Text(doc.group, style: T.small.copyWith(color: K.green, fontWeight: FontWeight.w800)),
            Text(doc.name, style: T.h3.copyWith(fontSize: 19)),
          ]),
          actions: [
            IconButton(tooltip: 'Members\' link', icon: const Icon(Icons.link_rounded), onPressed: _link),
            IconButton(tooltip: 'More', icon: const Icon(Icons.more_horiz_rounded), onPressed: _menu),
            const SizedBox(width: 6),
          ],
        ),
        body: RefreshIndicator(
          color: K.green,
          onRefresh: () async {
            if (dirty) {
              toast(context, 'Save your changes first.');
              return;
            }
            await _reload();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            children: [
              _hero(),
              const SizedBox(height: 14),
              _winner(),
              const SizedBox(height: 14),
              _actions(),
              const SizedBox(height: 14),
              _members(),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.history_rounded, size: 16, color: K.muted),
                const SizedBox(width: 6),
                Flexible(child: Text('Every save is kept in History, so nothing is lost.', style: T.small, textAlign: TextAlign.center)),
              ]),
              if (rec.updatedBy != null && rec.updatedAt != null) ...[
                const SizedBox(height: 4),
                Text('Last saved by ${rec.updatedBy}, ${ago(rec.updatedAt!)}', style: T.small, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
        bottomNavigationBar: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (c, a) => SizeTransition(sizeFactor: a, axisAlignment: -1, child: c),
          child: dirty ? _saveBar() : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _saveBar() {
    return Container(
      key: const ValueKey('save'),
      decoration: const BoxDecoration(
        color: K.surface,
        border: Border(top: BorderSide(color: K.border)),
        boxShadow: [BoxShadow(color: Color(0x14032A09), blurRadius: 20, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
          child: Row(children: [
            const Icon(Icons.edit_note_rounded, color: K.warn),
            const SizedBox(width: 8),
            const Expanded(child: Text('Not saved yet', style: T.bodyStrong)),
            KButton(
              label: 'Undo',
              kind: KButtonKind.ghost,
              small: true,
              onPressed: saving
                  ? null
                  : () => setState(() {
                        doc = rec.doc.copy();
                        dirty = false;
                      }),
            ),
            const SizedBox(width: 4),
            KButton(label: 'Save', icon: Icons.check_rounded, busy: saving, onPressed: () => _save()),
          ]),
        ),
      ),
    );
  }

  Widget _hero() {
    final got = doc.paidSum(m), fines = doc.fineSum(m), paid = doc.paidCount(m), n = doc.payers.length;
    final pct = doc.pot == 0 ? 0.0 : got / doc.pot;
    final deadline = doc.deadline(m.n);
    return HeroCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          RoundIcon(Icons.chevron_left_rounded, dark: true, tooltip: 'Previous month', onTap: sel > 0 ? () => setState(() => sel--) : null),
          Expanded(
            child: GestureDetector(
              onTap: _pickMonth,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.emoji_events_rounded, size: 17, color: K.heroText),
                const SizedBox(width: 7),
                Flexible(
                  child: Text('Month ${m.n}, ${doc.monthLabel(m.n)}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label.copyWith(color: K.heroText, fontSize: 14.5)),
                ),
                const Icon(Icons.expand_more_rounded, size: 18, color: K.heroText),
              ]),
            ),
          ),
          RoundIcon(Icons.chevron_right_rounded,
              dark: true, tooltip: 'Next month', onTap: sel < doc.months.length - 1 ? () => setState(() => sel++) : null),
        ]),
        const SizedBox(height: 16),
        Text(money(got), style: T.amount),
        const SizedBox(height: 4),
        Text('of ${money(doc.pot)} collected${fines > 0 ? ', plus ${money(fines)} in fines' : ''}',
            style: T.small.copyWith(color: K.heroText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        ProgressLine(pct),
        const SizedBox(height: 12),
        Row(children: [
          Text('$paid of $n paid', style: T.label.copyWith(color: Colors.white)),
          const Spacer(),
          Text(n - paid > 0 ? '${n - paid} to go' : 'Everyone paid', style: T.small.copyWith(color: K.heroText)),
        ]),
        const SizedBox(height: 10),
        Container(height: 1, color: const Color(0x1FFFFFFF)),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.schedule_rounded, size: 15, color: K.heroText),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Collection ${doc.collectDate(m.n).day} ${doc.monthShort(m.n)}, pay by ${deadline.day} ${kMonthsShort[deadline.month - 1]}: ${doc.nextNote(m.n)}',
              style: T.small.copyWith(color: K.heroText),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showPicker<int>(context, title: 'Month', selected: m.n, options: [
      for (final x in doc.months)
        PickOption(x.n, doc.monthLabel(x.n),
            badge: '${x.n}',
            sub: switch (doc.state(x)) {
              MonthState.done => 'Settled',
              MonthState.open => x.winner == null ? 'In progress' : 'In progress, ${doc.slotName(x.winner!)} takes the pot',
              MonthState.soon => x.winner == null ? 'Upcoming' : 'Upcoming, ${doc.slotName(x.winner!)} takes the pot',
            }),
    ]);
    if (picked != null) setState(() => sel = picked.value - 1);
  }

  Widget _winner() {
    final fines = doc.fineSum(m);
    final fromBottle = m.draw != null && m.draw!.picked == m.winner;
    return KCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: m.winner == null ? K.surface2 : K.sun, shape: BoxShape.circle),
            child: Icon(Icons.emoji_events_rounded, color: m.winner == null ? K.muted : K.deep, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Takes the pot this month', style: T.small),
              Text(m.winner == null ? 'Not decided yet' : '${m.winner}. ${doc.slotName(m.winner!)}', style: T.h3),
              if (m.winner != null)
                Text(
                  '${money(doc.pot + fines)}${fines > 0 ? ' (pot plus ${money(fines)} fine)' : ''}${fromBottle ? ', picked from the bottle' : ''}',
                  style: T.small.copyWith(color: K.brand600, fontWeight: FontWeight.w700),
                ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (m.winner == null) KButton(label: 'Bottle draw', icon: Icons.casino_outlined, kind: KButtonKind.sun, small: true, onPressed: _bottle),
          KButton(
            label: m.winner == null ? 'Choose' : 'Change',
            icon: m.winner == null ? Icons.touch_app_outlined : Icons.swap_horiz_rounded,
            kind: KButtonKind.secondary,
            small: true,
            onPressed: _choose,
          ),
        ]),
      ]),
    );
  }

  Widget _actions() {
    final everyone = doc.allPaid(m);
    return Row(children: [
      if (!everyone) ...[
        Expanded(
          child: KButton(
            label: 'All paid',
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
        const SizedBox(width: 10),
      ],
      Expanded(
        child: KButton(label: 'Reminders', icon: Icons.chat_outlined, kind: KButtonKind.secondary, expand: true, onPressed: _reminders),
      ),
    ]);
  }

  Widget _members() {
    final n = doc.payers.length, paid = doc.paidCount(m);
    final everyone = n > 0 && paid >= n;
    if (everyone && !unfolded.contains(m.n)) {
      return KCard(
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, color: K.leaf, size: 26),
          const SizedBox(width: 12),
          Expanded(child: Text('Everyone paid for month ${m.n}', style: T.bodyStrong)),
          KButton(label: 'Show', small: true, kind: KButtonKind.ghost, onPressed: () => setState(() => unfolded.add(m.n))),
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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: KSegmented<_Filter>(
                  value: filter,
                  onChanged: (v) => setState(() => filter = v),
                  items: [(_Filter.all, 'All $n'), (_Filter.due, 'To pay ${n - paid}'), (_Filter.paid, 'Paid $paid')],
                ),
              ),
            ),
            if (everyone) KButton(label: 'Hide', small: true, kind: KButtonKind.ghost, onPressed: () => setState(() => unfolded.remove(m.n))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Text('Tap the tick when someone pays. Tap Late if they paid after the last date.', style: T.small),
        ),
        const Divider(),
        if (rows.isEmpty)
          EmptyState(
            icon: Icons.check_rounded,
            text: filter == _Filter.due ? 'Everyone has paid for month ${m.n}.' : 'Nobody has paid for month ${m.n} yet.',
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
    final paid = month.isPaid(payer.id), late = month.isFined(payer.id), won = month.winner == payer.slot;
    final part = doc.partLabel(payer);
    var status = paid ? 'Paid ${money(payer.amt)}' : 'Pending ${money(payer.amt)}';
    if (late) status += ', late fine ${money(doc.fine)}';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: won ? const LinearGradient(colors: [K.brand100, Color(0x00E4F1E8)], stops: [0, 0.7]) : null,
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(children: [
        SlotBadge('${payer.slot}', style: won ? SlotBadgeStyle.winner : (paid ? SlotBadgeStyle.paid : SlotBadgeStyle.plain)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(doc.nameOf(payer), style: T.bodyStrong.copyWith(fontSize: 16)),
              if (part != null) Pill(part),
            ]),
            const SizedBox(height: 2),
            Wrap(spacing: 8, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(status, style: T.small.copyWith(color: paid ? K.brand600 : K.muted, fontWeight: paid ? FontWeight.w700 : FontWeight.w600)),
              if (tookIn != null) Pill('Month $tookIn', icon: Icons.emoji_events_rounded, color: K.sunSoft, fg: K.warn),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        _LateButton(on: late, onTap: onLate, name: doc.nameOf(payer)),
        const SizedBox(width: 8),
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
      label: 'Paid: $name',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: on ? K.green : K.surface,
            shape: BoxShape.circle,
            border: Border.all(color: on ? K.green : K.border2, width: 2),
          ),
          child: Icon(Icons.check_rounded, color: on ? Colors.white : K.border2, size: 24),
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
      label: 'Late fine, $name',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: on ? K.badBg : K.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? Colors.transparent : K.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.schedule_rounded, size: 15, color: on ? K.bad : K.muted),
            const SizedBox(width: 4),
            Text('Late', style: T.label.copyWith(fontSize: 13, color: on ? K.bad : K.muted)),
          ]),
        ),
      ),
    );
  }
}

/// Opens a link outside the app.
Future<void> openOutside(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) toast(context, 'Could not open that. Is WhatsApp installed?', bad: true);
}

/// Copies text and says so.
Future<void> copyText(BuildContext context, String text, [String said = 'Copied']) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) toast(context, said);
}

String linkFor(String token) => shareUrl(token);
