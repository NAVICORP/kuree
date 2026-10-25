import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/kuri.dart';
import '../l10n/strings.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

class _Holder {
  _Holder(String name, String amount, {this.id})
      : name = TextEditingController(text: name),
        amount = TextEditingController(text: amount);
  final TextEditingController name;
  final TextEditingController amount;
  final FocusNode focus = FocusNode();
  final String? id;

  void dispose() {
    name.dispose();
    amount.dispose();
    focus.dispose();
  }
}

/// The most slots a chit can have: five years of months.
const kMaxSlots = 60;

/// A new chit, or changes to one: the name, the money and its currency, the
/// dates, who holds each slot and their numbers. Returns the saved chit.
class KuriEditorScreen extends StatefulWidget {
  const KuriEditorScreen({super.key, this.record});
  final KuriRecord? record;

  @override
  State<KuriEditorScreen> createState() => _KuriEditorScreenState();
}

class _KuriEditorScreenState extends State<KuriEditorScreen> {
  late final bool isNew = widget.record == null;
  late final KuriDoc base = widget.record?.doc.copy() ?? _blank();
  late final _name = TextEditingController(text: isNew ? '' : base.name);
  late final _group = TextEditingController(text: base.group);
  late final _share = TextEditingController(text: isNew ? '' : '${base.share}');
  late final _fine = TextEditingController(text: base.fine > 0 ? '${base.fine}' : '');
  late String currency = base.currency;
  late int startYear = base.startYear;
  late int startMonth = base.startMonth;
  late int collectDay = base.collectDay;
  late int lastDay = base.lastDay;
  final List<List<_Holder>> rows = [];
  final Map<String, String> phones = {};
  String? error;
  bool busy = false;

  static KuriDoc _blank() {
    final now = DateTime.now();
    return KuriDoc(name: '', share: 0, slots: 10, startYear: now.year, startMonth: now.month, fine: 0);
  }

  int get share => int.tryParse(_share.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// One row per slot, then one empty row to add the next name. The slots
  /// are the rows before that empty one.
  int get slots => rows.isNotEmpty && _isEmpty(rows.last) ? rows.length - 1 : rows.length;

  static bool _isEmpty(List<_Holder> r) => r.length == 1 && r.first.name.text.trim().isEmpty;
  int get fine => int.tryParse(_fine.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  void initState() {
    super.initState();
    for (final p in base.people) {
      if (p.phone.isNotEmpty) phones[nameKey(p.name)] = p.phone;
    }
    // A new chit starts with one empty row; a saved one with its slots.
    for (var s = 1; s <= (isNew ? 0 : base.slots); s++) {
      rows.add(_rowFor(s));
    }
    _tidy();
    _share.addListener(() => setState(() {}));
  }

  List<_Holder> _rowFor(int s) {
    final ps = base.payersIn(s);
    if (ps.isEmpty) return [_Holder('', '')];
    return [for (final p in ps) _Holder(base.nameOf(p), ps.length > 1 ? '${p.amt}' : '', id: p.id)];
  }

  @override
  void dispose() {
    for (final c in [_name, _group, _share, _fine]) {
      c.dispose();
    }
    for (final r in rows) {
      for (final h in r) {
        h.dispose();
      }
    }
    super.dispose();
  }

  /// Keeps exactly one empty row at the end: a name typed into it brings the
  /// next one, and clearing the last name takes the spare row away again.
  void _tidy() {
    if ((rows.isEmpty || !_isEmpty(rows.last)) && rows.length < kMaxSlots) {
      rows.add([_Holder('', '')]);
    }
    while (rows.length >= 2 && _isEmpty(rows.last) && _isEmpty(rows[rows.length - 2])) {
      for (final h in rows.removeLast()) {
        h.dispose();
      }
    }
  }

  /// Next on the keyboard goes on to the next slot's name.
  void _next(int i) {
    if (i + 1 < rows.length) {
      rows[i + 1].first.focus.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void _split(int i) {
    setState(() {
      final r = rows[i];
      final each = share > 0 ? share ~/ (r.length + 1) : 0;
      for (final h in r) {
        h.amount.text = each > 0 ? '$each' : '';
      }
      r.add(_Holder('', each > 0 ? '${share - each * r.length}' : ''));
    });
  }

  void _unsplit(int i, int j) {
    setState(() {
      rows[i].removeAt(j).dispose();
      if (rows[i].length == 1) rows[i].first.amount.text = '';
    });
  }

  /// The people, in slot order, each once.
  List<String> get _names {
    final seen = <String>{};
    final out = <String>[];
    for (final r in rows) {
      for (final h in r) {
        final n = h.name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (n.isEmpty || !seen.add(nameKey(n))) continue;
        out.add(n);
      }
    }
    return out;
  }

  KuriDoc _build() {
    final name = _name.text.trim();
    final t = S.current;
    if (name.isEmpty) throw ApiError(t.errNeedName);
    if (share <= 0) throw ApiError(t.errNeedShare);
    final doc = base.copy()
      ..name = name
      ..currency = currency
      ..group = _group.text.trim()
      ..share = share
      ..startYear = startYear
      ..startMonth = startMonth
      ..collectDay = collectDay
      ..lastDay = lastDay;
    doc.setFine(fine);

    // People: the same name in two slots is the same person.
    final byKey = {for (final p in base.people) nameKey(p.name): p};
    final people = <Person>[];
    final used = <String>{for (final p in base.people) p.id};
    var next = 1;
    String newId() {
      while (used.contains('m$next')) {
        next++;
      }
      used.add('m$next');
      return 'm$next';
    }

    Person personFor(String n) {
      final key = nameKey(n);
      for (final p in people) {
        if (nameKey(p.name) == key) return p;
      }
      final old = byKey[key];
      final p = Person(id: old?.id ?? newId(), name: n, phone: phones[key] ?? '', extra: old?.extra);
      people.add(p);
      return p;
    }

    // At least two slots: with fewer, the first empty one is the one to fill.
    if (slots < 2) throw ApiError(t.errSlotName(slots + 1));
    final payers = <Payer>[];
    final usedIds = <String>{};
    for (var i = 0; i < slots; i++) {
      final s = i + 1;
      final r = rows[i].where((h) => h.name.text.trim().isNotEmpty).toList();
      if (r.isEmpty) throw ApiError(t.errSlotName(s));
      if (r.length > 1) {
        final total = r.fold<int>(0, (sum, h) => sum + (int.tryParse(h.amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0));
        if (total != share) throw ApiError(t.errPartsSum(s, money(total, currency), money(share, currency)));
      }
      final letters = 'abcdefghij';
      for (var j = 0; j < r.length; j++) {
        final h = r[j];
        var id = h.id ?? (r.length == 1 ? 'p$s' : 'p$s${letters[min(j, letters.length - 1)]}');
        while (usedIds.contains(id)) {
          id = '${id}x';
        }
        usedIds.add(id);
        final amt = r.length == 1 ? share : int.tryParse(h.amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (amt <= 0) throw ApiError(t.errPartAmount(s));
        payers.add(Payer(id: id, slot: s, person: personFor(h.name.text.trim().replaceAll(RegExp(r'\s+'), ' ')).id, amt: amt));
      }
    }

    // Months: one for every slot. Months being dropped must still be empty.
    if (doc.months.length > slots) {
      for (final m in doc.months.sublist(slots)) {
        if (m.paid.isNotEmpty || m.fines.isNotEmpty || m.winner != null) {
          throw ApiError(t.errFewerSlots(m.n));
        }
      }
    }
    for (final m in doc.months) {
      if (m.winner != null && m.winner! > slots) {
        throw ApiError(t.errTakerSlot(m.winner!, m.n));
      }
    }
    doc.slots = slots;
    doc.people
      ..clear()
      ..addAll(people);
    doc.payers
      ..clear()
      ..addAll(payers);
    doc.fitMonths();
    // Ticks for someone no longer in the chit go.
    for (final m in doc.months) {
      m.paid.removeWhere((k, _) => !usedIds.contains(k));
      m.fines.removeWhere((k, _) => !usedIds.contains(k));
    }
    doc.updated = DateTime.now().toIso8601String().substring(0, 10);
    return doc;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final doc = _build();
      final dynamic j = isNew
          ? await Api.instance.rpc('create_kuri', {'data': doc.toJson()})
          : await Api.instance.rpc('save_kuri', {'id': widget.record!.id, 'data': doc.toJson(), 'expected': widget.record!.updatedAtRaw});
      if (!mounted) return;
      Navigator.of(context).pop(KuriRecord.fromJson(Map<String, dynamic>.from(j as Map)));
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => error = e.isConflict ? S.of(context).errConflictEditor : e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final options = <PickOption<int>>[];
    for (var i = -18; i <= 12; i++) {
      final d = DateTime(now.year, now.month + i, 1);
      options.add(PickOption(d.year * 100 + d.month, '${monthName(d.month)} ${d.year}'));
    }
    final picked = await showPicker<int>(context, title: S.of(context).firstMonth, options: options, selected: startYear * 100 + startMonth);
    if (picked != null) {
      setState(() {
        startYear = picked.value ~/ 100;
        startMonth = picked.value % 100;
      });
    }
  }

  Future<int?> _pickDay(String title, int current) async {
    final s = S.of(context);
    final picked = await showPicker<int>(context,
        title: title, selected: current, options: [for (var d = 1; d <= 31; d++) PickOption(d, dayOf(d), sub: d > 28 ? s.shorterMonths : null)]);
    return picked?.value;
  }

  Future<void> _pickCurrency() async {
    final s = S.of(context);
    final picked = await showPicker<String>(context, title: s.currency, selected: currency, options: [
      for (final c in kCurrencies) PickOption(c.code, c.name, sub: c.format(5000), trailing: c.code),
    ]);
    if (picked != null) setState(() => currency = picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final names = _names;
    final cur = currencyOf(currency);
    final withNumber = phones.entries.where((e) => names.any((n) => nameKey(n) == e.key)).length;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? s.newChit : s.editChit)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xs, Sp.page, 130),
        children: [
          SectionTitle(s.sectionChit),
          KCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _field(s.fieldName, _name, hint: s.nameHint, caps: TextCapitalization.words),
              const SizedBox(height: Sp.lg),
              _field(s.fieldGroup, _group, hint: s.groupHint, caps: TextCapitalization.words),
            ]),
          ),
          SectionTitle(s.sectionMoney),
          KCard(
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              KChoice(label: s.currency, value: '${cur.name} (${cur.code})', icon: Icons.payments_outlined, onTap: _pickCurrency),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(Sp.lg + 2),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(child: _field(s.eachSlotPays, _share, hint: '5000', money: true)),
                    const SizedBox(width: Sp.md),
                    Expanded(child: _field(s.lateFine, _fine, hint: s.fineNone, money: true)),
                  ]),
                  const SizedBox(height: Sp.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: K.brand100, borderRadius: BorderRadius.circular(K.rSm)),
                    child: Text(
                      slots == 0
                          ? s.slotsFromNames
                          : share > 0
                              ? s.potSummary(money(share * slots, currency), slots)
                              : s.potSummaryNone(slots),
                      style: T.label.copyWith(color: K.brand600),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          SectionTitle(s.sectionDates),
          KCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              KChoice(label: s.firstMonth, value: '${monthName(startMonth)} $startYear', icon: Icons.event_outlined, onTap: _pickStart),
              const Divider(),
              KChoice(
                label: s.collectionDay,
                value: s.everyMonthDay(dayOf(collectDay)),
                icon: Icons.savings_outlined,
                onTap: () async {
                  final d = await _pickDay(s.collectionDay, collectDay);
                  if (d != null) setState(() => collectDay = d);
                },
              ),
              const Divider(),
              KChoice(
                label: s.lastDayToPay,
                value: lastDay < collectDay ? s.byMidnightNext(dayOf(lastDay)) : s.byMidnight(dayOf(lastDay)),
                icon: Icons.schedule_rounded,
                onTap: () async {
                  final d = await _pickDay(s.lastDayToPay, lastDay);
                  if (d != null) setState(() => lastDay = d);
                },
              ),
            ]),
          ),
          SectionTitle(
            s.slots,
            trailing: slots == 0 ? Text(s.oneNamePerSlot, style: T.small) : Pill('$slots', color: K.surface2, fg: K.ink2),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            _slotRow(i, s, cur),
            const SizedBox(height: Sp.md - 2),
          ],
          SectionTitle(s.numbersForReminders, trailing: Pill(s.countOf(withNumber, names.length), color: K.surface2, fg: K.ink2)),
          KCard(
            padding: EdgeInsets.zero,
            child: names.isEmpty
                ? Padding(padding: const EdgeInsets.all(Sp.lg + 2), child: Text(s.addNamesFirst, style: T.small))
                : Column(children: [
                    for (var i = 0; i < names.length; i++) ...[
                      if (i > 0) const Divider(),
                      _phoneRow(names[i], s),
                    ],
                  ]),
          ),
          const SizedBox(height: Sp.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
            child: Text(s.numbersNote, style: T.small),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: K.surface, border: Border(top: BorderSide(color: K.border))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Sp.page, Sp.md, Sp.page, Sp.md),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (error != null) ...[Notice(error!), const SizedBox(height: Sp.md - 2)],
              KButton(label: isNew ? s.startTheChit : s.saveChanges, icon: Icons.check_rounded, expand: true, busy: busy, onPressed: _save),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {String? hint, bool money = false, TextCapitalization caps = TextCapitalization.none}) {
    final cur = currencyOf(currency);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: T.label),
      const SizedBox(height: Sp.sm),
      TextField(
        controller: c,
        keyboardType: money ? TextInputType.number : TextInputType.text,
        textCapitalization: caps,
        inputFormatters: money ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)] : null,
        style: T.bodyStrong,
        decoration: InputDecoration(hintText: hint, prefixText: money ? '${cur.symbol} ' : null, prefixStyle: T.bodyStrong.copyWith(color: K.muted)),
      ),
    ]);
  }

  Widget _slotRow(int i, S s, Currency cur) {
    final r = rows[i];
    final split = r.length > 1;
    // The empty row at the end, for the next name.
    final spare = i == rows.length - 1 && _isEmpty(r);
    Widget name(int j) => TextField(
          key: ValueKey('slot-${i + 1}-${j + 1}'),
          controller: r[j].name,
          focusNode: r[j].focus,
          textCapitalization: TextCapitalization.words,
          textInputAction: split ? TextInputAction.done : TextInputAction.next,
          onSubmitted: split ? null : (_) => _next(i),
          style: T.bodyStrong,
          onChanged: (_) => setState(_tidy),
          decoration: InputDecoration(
            hintText: split ? s.nameN(j + 1) : s.fieldName,
            isDense: true,
            suffixIcon: split
                ? IconButton(
                    tooltip: s.remove,
                    onPressed: () => _unsplit(i, j),
                    icon: const Icon(Icons.close_rounded, size: 20, color: K.muted),
                  )
                : null,
          ),
        );
    return KCard(
      padding: EdgeInsetsDirectional.fromSTEB(12, 12, split ? 12 : 4, split ? 6 : 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 6), child: SlotBadge('${i + 1}', size: 38)),
        const SizedBox(width: Sp.md - 2),
        Expanded(
          child: split
              // A shared slot: one line per person, each with their part.
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var j = 0; j < r.length; j++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Sp.sm),
                      child: Row(children: [
                        Expanded(child: name(j)),
                        const SizedBox(width: Sp.sm),
                        SizedBox(
                          width: cur.symbol.length > 1 ? 120 : 104,
                          child: TextField(
                            controller: r[j].amount,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
                            style: T.bodyStrong,
                            decoration: InputDecoration(
                              prefixText: cur.symbol.length > 1 ? '${cur.symbol} ' : cur.symbol,
                              prefixStyle: T.bodyStrong.copyWith(color: K.muted),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  if (r.length < 4)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => _split(i),
                        style: TextButton.styleFrom(
                          foregroundColor: K.green,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                          shape: const StadiumBorder(),
                          textStyle: T.label,
                        ),
                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                        label: Text(s.addPerson),
                      ),
                    ),
                ])
              : name(0),
        ),
        if (!split && !spare)
          IconButton(
            tooltip: s.splitSlot,
            onPressed: () => _split(i),
            icon: const Icon(Icons.group_add_outlined, color: K.green),
          )
        else if (spare)
          // Keeps the empty row the same height and width as the others.
          const SizedBox(width: 48, height: 48),
      ]),
    );
  }

  Widget _phoneRow(String name, S s) {
    final p = phones[nameKey(name)] ?? '';
    return InkWell(
      onTap: () async {
        final got = await askPhone(context, name, p);
        if (got != null) setState(() => phones[nameKey(name)] = got);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 14, 12),
          child: Row(children: [
            Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.bodyStrong)),
            const SizedBox(width: Sp.sm),
            Text(p.isEmpty ? s.addNumber : prettyPhone(p),
                textDirection: p.isEmpty ? null : TextDirection.ltr,
                style: T.small.copyWith(color: p.isEmpty ? K.green : K.ink2, fontWeight: FontWeight.w700)),
            const SizedBox(width: Sp.xs),
            Icon(p.isEmpty ? Icons.add_rounded : Icons.edit_outlined, size: 18, color: K.muted),
          ]),
        ),
      ),
    );
  }
}
