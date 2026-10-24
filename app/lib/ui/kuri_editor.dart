import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/kuri.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

class _Holder {
  _Holder(String name, String amount, {this.id})
      : name = TextEditingController(text: name),
        amount = TextEditingController(text: amount);
  final TextEditingController name;
  final TextEditingController amount;
  final String? id;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

/// A new kuri, or changes to one: the name, the money, the dates, who holds
/// each slot and their numbers. Returns the saved kuri.
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
  late final _fine = TextEditingController(text: '${base.fine}');
  late int slots = base.slots;
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
  int get fine => int.tryParse(_fine.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  void initState() {
    super.initState();
    for (final p in base.people) {
      if (p.phone.isNotEmpty) phones[nameKey(p.name)] = p.phone;
    }
    for (var s = 1; s <= slots; s++) {
      rows.add(_rowFor(s));
    }
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

  void _setSlots(int n) {
    setState(() {
      slots = n.clamp(2, 60);
      while (rows.length < slots) {
        rows.add(_rowFor(rows.length + 1));
      }
      while (rows.length > slots) {
        for (final h in rows.removeLast()) {
          h.dispose();
        }
      }
    });
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
    if (name.isEmpty) throw ApiError('Give the kuri a name, like 5K Kuri.');
    if (share <= 0) throw ApiError('Enter how much each slot pays a month.');
    final doc = base.copy()
      ..name = name
      ..group = _group.text.trim()
      ..share = share
      ..fine = fine
      ..startYear = startYear
      ..startMonth = startMonth
      ..collectDay = collectDay
      ..lastDay = lastDay;

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

    final payers = <Payer>[];
    final usedIds = <String>{};
    for (var i = 0; i < slots; i++) {
      final s = i + 1;
      final r = rows[i].where((h) => h.name.text.trim().isNotEmpty).toList();
      if (r.isEmpty) throw ApiError('Slot $s needs a name.');
      if (r.length > 1) {
        final total = r.fold<int>(0, (t, h) => t + (int.tryParse(h.amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0));
        if (total != share) throw ApiError('Slot $s: the parts add up to ${money(total)}, but a slot pays ${money(share)}.');
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
        if (amt <= 0) throw ApiError('Slot $s: enter what each person pays.');
        payers.add(Payer(id: id, slot: s, person: personFor(h.name.text.trim().replaceAll(RegExp(r'\s+'), ' ')).id, amt: amt));
      }
    }

    // Months: one for every slot. Months being dropped must still be empty.
    if (doc.months.length > slots) {
      for (final m in doc.months.sublist(slots)) {
        if (m.paid.isNotEmpty || m.fines.isNotEmpty || m.winner != null) {
          throw ApiError('Month ${m.n} already has payments or a taker, so the kuri cannot have fewer than ${m.n} slots.');
        }
      }
    }
    for (final m in doc.months) {
      if (m.winner != null && m.winner! > slots) {
        throw ApiError('Slot ${m.winner} took the pot in month ${m.n}, so the kuri needs at least ${m.winner} slots.');
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
    // Ticks for someone no longer in the kuri go.
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
      setState(() => error = e.isConflict ? 'Another admin saved this kuri a moment ago. Go back, reload it, then make your changes again.' : e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final options = <PickOption<int>>[];
    for (var i = -18; i <= 12; i++) {
      final d = DateTime(now.year, now.month + i, 1);
      options.add(PickOption(d.year * 100 + d.month, '${kMonths[d.month - 1]} ${d.year}'));
    }
    final picked = await showPicker<int>(context, title: 'First month', options: options, selected: startYear * 100 + startMonth);
    if (picked != null) {
      setState(() {
        startYear = picked.value ~/ 100;
        startMonth = picked.value % 100;
      });
    }
  }

  Future<int?> _pickDay(String title, int current) async {
    final picked = await showPicker<int>(context,
        title: title, selected: current, options: [for (var d = 1; d <= 31; d++) PickOption(d, ordinal(d), sub: d > 28 ? 'Shorter months use their last day' : null)]);
    return picked?.value;
  }

  @override
  Widget build(BuildContext context) {
    final names = _names;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'New kuri' : 'Edit kuri')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
        children: [
          const SectionTitle('Kuri'),
          KCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _field('Name', _name, hint: '5K Kuri', caps: TextCapitalization.words),
              const SizedBox(height: 14),
              _field('Group', _group, hint: 'Riverside', caps: TextCapitalization.words),
            ]),
          ),
          const SectionTitle('Money'),
          KCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _field('Each slot pays a month', _share, hint: '5000', money: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Late fine', _fine, hint: '200', money: true)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                const Expanded(child: Text('Slots', style: T.label)),
                RoundIcon(Icons.remove_rounded, onTap: slots > 2 ? () => _setSlots(slots - 1) : null, size: 38),
                SizedBox(width: 52, child: Text('$slots', textAlign: TextAlign.center, style: T.h2.merge(T.tabular))),
                RoundIcon(Icons.add_rounded, onTap: slots < 60 ? () => _setSlots(slots + 1) : null, size: 38),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: K.brand100, borderRadius: BorderRadius.circular(14)),
                child: Text(
                  share > 0 ? 'Pot ${money(share * slots)} a month, for $slots months' : 'One slot takes the pot each month, for $slots months',
                  style: T.label.copyWith(color: K.brand600),
                ),
              ),
            ]),
          ),
          const SectionTitle('Dates'),
          KCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _choice('First month', '${kMonths[startMonth - 1]} $startYear', _pickStart),
              const Divider(),
              _choice('Collection day', '${ordinal(collectDay)} of every month', () async {
                final d = await _pickDay('Collection day', collectDay);
                if (d != null) setState(() => collectDay = d);
              }),
              const Divider(),
              _choice('Last day to pay', '${ordinal(lastDay)}, by midnight${lastDay < collectDay ? ', the month after' : ''}', () async {
                final d = await _pickDay('Last day to pay', lastDay);
                if (d != null) setState(() => lastDay = d);
              }),
            ]),
          ),
          SectionTitle('Slots', trailing: Text('One name per slot', style: T.small)),
          for (var i = 0; i < rows.length; i++) ...[
            _slotRow(i),
            const SizedBox(height: 10),
          ],
          SectionTitle('Numbers for reminders', trailing: Text('${phones.entries.where((e) => names.any((n) => nameKey(n) == e.key)).length} of ${names.length}', style: T.small)),
          KCard(
            padding: EdgeInsets.zero,
            child: names.isEmpty
                ? Padding(padding: const EdgeInsets.all(18), child: Text('Add names to the slots first.', style: T.small))
                : Column(children: [
                    for (var i = 0; i < names.length; i++) ...[
                      if (i > 0) const Divider(),
                      _phoneRow(names[i]),
                    ],
                  ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Numbers are only for WhatsApp reminders. They never show on the members\' link.', style: T.small),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: K.surface, border: Border(top: BorderSide(color: K.border))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (error != null) ...[Notice(error!), const SizedBox(height: 10)],
              KButton(label: isNew ? 'Start the kuri' : 'Save changes', icon: Icons.check_rounded, expand: true, busy: busy, onPressed: _save),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {String? hint, bool money = false, TextCapitalization caps = TextCapitalization.none}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: T.label),
      const SizedBox(height: 8),
      TextField(
        controller: c,
        keyboardType: money ? TextInputType.number : TextInputType.text,
        textCapitalization: caps,
        inputFormatters: money ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)] : null,
        style: T.bodyStrong,
        decoration: InputDecoration(hintText: hint, prefixText: money ? '₹ ' : null, prefixStyle: T.bodyStrong.copyWith(color: K.muted)),
      ),
    ]);
  }

  Widget _choice(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: T.small),
              const SizedBox(height: 2),
              Text(value, style: T.bodyStrong),
            ]),
          ),
          const Icon(Icons.expand_more_rounded, color: K.muted),
        ]),
      ),
    );
  }

  Widget _slotRow(int i) {
    final r = rows[i];
    final split = r.length > 1;
    return KCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 6), child: SlotBadge('${i + 1}', size: 38)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var j = 0; j < r.length; j++)
              Padding(
                padding: EdgeInsets.only(bottom: j < r.length - 1 ? 8 : 0),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: r[j].name,
                      textCapitalization: TextCapitalization.words,
                      style: T.bodyStrong,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(hintText: split ? 'Name ${j + 1}' : 'Name', isDense: true),
                    ),
                  ),
                  if (split) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 96,
                      child: TextField(
                        controller: r[j].amount,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
                        style: T.bodyStrong,
                        decoration: const InputDecoration(
                          prefixText: '₹',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _unsplit(i, j),
                      icon: const Icon(Icons.close_rounded, size: 19, color: K.muted),
                    ),
                  ],
                ]),
              ),
          ]),
        ),
        if (r.length < 4)
          IconButton(
            tooltip: 'Share this slot between people',
            visualDensity: VisualDensity.compact,
            onPressed: () => _split(i),
            icon: const Icon(Icons.call_split_rounded, color: K.green),
          ),
      ]),
    );
  }

  Widget _phoneRow(String name) {
    final p = phones[nameKey(name)] ?? '';
    return InkWell(
      onTap: () async {
        final got = await askPhone(context, name, p);
        if (got != null) setState(() => phones[nameKey(name)] = got);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
        child: Row(children: [
          Expanded(child: Text(name, style: T.bodyStrong)),
          Text(p.isEmpty ? 'Add number' : prettyPhone(p), style: T.small.copyWith(color: p.isEmpty ? K.green : K.ink2, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Icon(p.isEmpty ? Icons.add_rounded : Icons.edit_outlined, size: 18, color: K.muted),
        ]),
      ),
    );
  }
}
