import 'dart:math';

import 'format.dart';

/// Someone in the kuri. One person can hold several slots, and a slot can be
/// shared by several people.
class Person {
  Person({required this.id, required this.name, this.phone = '', Map<String, dynamic>? extra}) : extra = extra ?? {};
  String id;
  String name;

  /// Digits with the country code, for reminders. Never shown to members.
  String phone;
  final Map<String, dynamic> extra;

  factory Person.fromJson(Map<String, dynamic> j) {
    final extra = Map<String, dynamic>.from(j)..remove('id')..remove('name')..remove('phone');
    return Person(id: '${j['id'] ?? ''}', name: '${j['name'] ?? ''}'.trim(), phone: '${j['phone'] ?? ''}', extra: extra);
  }

  Map<String, dynamic> toJson() => {...extra, 'id': id, 'name': name, if (phone.isNotEmpty) 'phone': phone};
}

/// One person's part of one slot: who pays how much each month.
class Payer {
  Payer({required this.id, required this.slot, required this.person, required this.amt, Map<String, dynamic>? extra})
      : extra = extra ?? {};
  String id;
  int slot;
  String person;
  int amt;
  final Map<String, dynamic> extra;

  factory Payer.fromJson(Map<String, dynamic> j) {
    final extra = Map<String, dynamic>.from(j)..remove('id')..remove('slot')..remove('person')..remove('amt');
    return Payer(
      id: '${j['id'] ?? ''}',
      slot: _int(j['slot'], 1),
      person: '${j['person'] ?? ''}',
      amt: _int(j['amt'], 0),
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => {...extra, 'id': id, 'slot': slot, 'person': person, 'amt': amt};
}

/// How a month's taker was chosen with the bottle draw.
class DrawInfo {
  DrawInfo({required this.at, required this.by, required this.picked, required this.names, this.how = 'bottle'});
  String how;
  String at;
  String by;
  int picked;
  List<int> names;

  factory DrawInfo.fromJson(Map<String, dynamic> j) => DrawInfo(
        how: '${j['how'] ?? 'bottle'}',
        at: '${j['at'] ?? ''}',
        by: '${j['by'] ?? ''}',
        picked: _int(j['picked'], 0),
        names: (j['names'] is List ? j['names'] as List : const []).map((e) => _int(e, 0)).where((e) => e > 0).toList(),
      );

  Map<String, dynamic> toJson() => {'how': how, 'at': at, 'by': by, 'picked': picked, 'names': names};
}

class Month {
  Month({required this.n, this.winner, Map<String, bool>? paid, Map<String, bool>? fines, this.note = '', this.draw, Map<String, dynamic>? extra})
      : paid = paid ?? {},
        fines = fines ?? {},
        extra = extra ?? {};
  int n;
  int? winner;
  final Map<String, bool> paid;
  final Map<String, bool> fines;
  String note;
  DrawInfo? draw;
  final Map<String, dynamic> extra;

  bool isPaid(String id) => paid[id] == true;
  bool isFined(String id) => fines[id] == true;

  factory Month.fromJson(Map<String, dynamic> j) {
    final extra = Map<String, dynamic>.from(j)
      ..remove('n')..remove('winner')..remove('paid')..remove('fines')..remove('note')..remove('draw');
    final w = j['winner'];
    return Month(
      n: _int(j['n'], 1),
      winner: w == null ? null : (_int(w, 0) > 0 ? _int(w, 0) : null),
      paid: _flags(j['paid']),
      fines: _flags(j['fines']),
      note: '${j['note'] ?? ''}',
      draw: j['draw'] is Map ? DrawInfo.fromJson(Map<String, dynamic>.from(j['draw'] as Map)) : null,
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => {
        ...extra,
        'n': n,
        'winner': winner,
        'paid': {for (final e in paid.entries) if (e.value) e.key: true},
        'fines': {for (final e in fines.entries) if (e.value) e.key: true},
        'note': note,
        if (draw != null) 'draw': draw!.toJson(),
      };
}

enum MonthState { done, open, soon }

/// Who still owes for a month, one line per person (two slots add up).
class Due {
  Due(this.person, this.amount);
  final Person person;
  int amount;
}

/// A whole kuri: the settings, the people, the slots and every month. Saved
/// as one document on the server.
class KuriDoc {
  KuriDoc({
    required this.name,
    this.group = '',
    required this.share,
    required this.slots,
    required this.startYear,
    required this.startMonth,
    this.collectDay = 20,
    this.lastDay = 25,
    this.fine = 200,
    List<Person>? people,
    List<Payer>? payers,
    List<Month>? months,
    this.updated = '',
    Map<String, dynamic>? extra,
  })  : people = people ?? [],
        payers = payers ?? [],
        months = months ?? [],
        extra = extra ?? {};

  String name;
  String group;

  /// Each slot pays this every month.
  int share;
  int slots;
  int startYear;
  int startMonth;

  /// Collection day, and the last day to pay before the late fine.
  int collectDay;
  int lastDay;
  int fine;

  final List<Person> people;
  final List<Payer> payers;
  final List<Month> months;
  String updated;
  final Map<String, dynamic> extra;

  // 'groupLang' was a setting for the group message's language; the message
  // is English now, so an old value is read and dropped.
  static const _known = {
    'v', 'name', 'group', 'share', 'slots', 'startYear', 'startMonth', 'collectDay', 'lastDay', 'fine',
    'groupLang', 'people', 'payers', 'months', 'updated',
  };

  factory KuriDoc.fromJson(Map<String, dynamic> j) {
    final extra = Map<String, dynamic>.from(j)..removeWhere((k, _) => _known.contains(k));
    List<Map<String, dynamic>> list(String k) =>
        (j[k] is List ? j[k] as List : const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final doc = KuriDoc(
      name: '${j['name'] ?? 'Kuri'}',
      group: '${j['group'] ?? ''}',
      share: _int(j['share'], 0),
      slots: _int(j['slots'], 0),
      startYear: _int(j['startYear'], DateTime.now().year),
      startMonth: _int(j['startMonth'], DateTime.now().month).clamp(1, 12),
      collectDay: _int(j['collectDay'], 20).clamp(1, 31),
      lastDay: _int(j['lastDay'], 25).clamp(1, 31),
      fine: _int(j['fine'], 0),
      people: list('people').map(Person.fromJson).toList(),
      payers: list('payers').map(Payer.fromJson).toList(),
      months: list('months').map(Month.fromJson).toList(),
      updated: '${j['updated'] ?? ''}',
      extra: extra,
    );
    if (doc.slots <= 0) doc.slots = doc.payers.fold<int>(0, (m, p) => max(m, p.slot));
    doc.months.sort((a, b) => a.n.compareTo(b.n));
    doc.fitMonths();
    return doc;
  }

  Map<String, dynamic> toJson() => {
        ...extra,
        'v': 1,
        'name': name,
        'group': group,
        'share': share,
        'slots': slots,
        'startYear': startYear,
        'startMonth': startMonth,
        'collectDay': collectDay,
        'lastDay': lastDay,
        'fine': fine,
        'people': people.map((p) => p.toJson()).toList(),
        'payers': payers.map((p) => p.toJson()).toList(),
        'months': months.map((m) => m.toJson()).toList(),
        'updated': updated,
      };

  KuriDoc copy() => KuriDoc.fromJson(Map<String, dynamic>.from(_deep(toJson()) as Map));

  /// One month for every slot, numbered from 1.
  void fitMonths() {
    for (var i = 0; i < months.length; i++) {
      months[i].n = i + 1;
    }
    while (months.length < slots) {
      months.add(Month(n: months.length + 1));
    }
    if (months.length > slots) months.removeRange(slots, months.length);
  }

  // ---------------------------------------------------------------- money

  int get pot => share * slots;

  int paidSum(Month m) => payers.where((p) => m.isPaid(p.id)).fold(0, (t, p) => t + p.amt);

  int paidCount(Month m) => payers.where((p) => m.isPaid(p.id)).length;

  int fineCount(Month m) => payers.where((p) => m.isFined(p.id)).length;

  int fineSum(Month m) => fineCount(m) * fine;

  int get allFines => months.fold(0, (t, m) => t + fineSum(m));

  bool allPaid(Month m) => payers.isNotEmpty && payers.every((p) => m.isPaid(p.id));

  // ---------------------------------------------------------------- dates

  DateTime _inMonth(int n, int day, {int addMonths = 0}) {
    final base = DateTime(startYear, startMonth + (n - 1) + addMonths, 1);
    return DateTime(base.year, base.month, min(day, daysInMonth(base.year, base.month)));
  }

  /// The collection day of month n.
  DateTime collectDate(int n) => _inMonth(n, collectDay);

  /// The last moment to pay for month n without a fine (midnight at the end
  /// of the last day). A last day before the collection day falls in the
  /// month after.
  DateTime deadline(int n) {
    final d = _inMonth(n, lastDay, addMonths: lastDay < collectDay ? 1 : 0);
    return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }

  String monthLabel(int n) {
    final d = collectDate(n);
    return '${kMonths[d.month - 1]} ${d.year}';
  }

  String monthShort(int n) => kMonthsShort[collectDate(n).month - 1];

  /// The month whose collection falls in this calendar month, kept inside the kuri.
  int currentMonth([DateTime? now]) {
    final t = now ?? DateTime.now();
    final n = (t.year * 12 + t.month) - (startYear * 12 + startMonth) + 1;
    return n.clamp(1, max(1, months.length));
  }

  MonthState state(Month m, [DateTime? now]) {
    if (allPaid(m) && m.winner != null) return MonthState.done;
    return !(now ?? DateTime.now()).isBefore(collectDate(m.n)) ? MonthState.open : MonthState.soon;
  }

  int firstOpen([DateTime? now]) {
    for (final m in months) {
      if (state(m, now) != MonthState.done) return m.n;
    }
    return max(1, months.length);
  }

  int doneCount([DateTime? now]) => months.where((m) => state(m, now) == MonthState.done).length;

  /// Counts to the collection day; once it has passed, to the last day to pay.
  String nextNote(int n, [DateTime? now]) {
    final t = now ?? DateTime.now();
    int daysTo(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(t.year, t.month, t.day)).inDays;
    final dc = daysTo(collectDate(n));
    if (dc > 1) return 'in $dc days';
    if (dc == 1) return 'tomorrow';
    if (dc == 0) return 'today';
    final dd = daysTo(deadline(n));
    if (dd > 1) return '$dd days left to pay';
    if (dd == 1) return 'last day tomorrow';
    if (dd == 0) return 'pay by midnight today';
    return 'deadline passed';
  }

  // ---------------------------------------------------------------- people and slots

  Person? personById(String id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  String nameOf(Payer p) => personById(p.person)?.name ?? 'Someone';

  List<Payer> payersIn(int slot) => payers.where((p) => p.slot == slot).toList();

  /// "Farhan / Yasir"
  String slotName(int slot) {
    final names = payersIn(slot).map(nameOf).toList();
    return names.isEmpty ? 'Slot $slot' : names.join(' / ');
  }

  /// "Farhan and Yasir"
  String slotNameAnd(int slot) {
    final names = payersIn(slot).map(nameOf).toList();
    if (names.isEmpty) return 'Slot $slot';
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
  }

  /// "½ share" for half of a slot, or the amount for any other part.
  String? partLabel(Payer p) {
    if (p.amt >= share || share <= 0) return null;
    if (p.amt * 2 == share) return '½ share';
    if (p.amt * 3 == share) return '⅓ share';
    if (p.amt * 4 == share) return '¼ share';
    return '${money(p.amt)} share';
  }

  /// slot -> the month it took the pot
  Map<int, int> drawn() => {for (final m in months) if (m.winner != null) m.winner!: m.n};

  /// Slots that have not taken the pot yet.
  List<int> waitingSlots() {
    final w = drawn();
    return [for (var s = 1; s <= slots; s++) if (!w.containsKey(s)) s];
  }

  List<int> slotsOf(Person person) => payers.where((p) => p.person == person.id).map((p) => p.slot).toList()..sort();

  /// Who still owes for a month, one line per person, in slot order.
  List<Due> dues(Month m) {
    final byPerson = <String, Due>{};
    final order = <Due>[];
    for (final p in payers) {
      if (m.isPaid(p.id)) continue;
      final person = personById(p.person) ?? Person(id: p.person, name: 'Someone');
      final d = byPerson.putIfAbsent(person.id, () {
        final x = Due(person, 0);
        order.add(x);
        return x;
      });
      d.amount += p.amt;
    }
    return order;
  }

  /// Everyone who has paid for a month, each name once.
  List<String> paidNames(Month m) {
    final out = <String>[];
    for (final p in payers) {
      if (!m.isPaid(p.id)) continue;
      final n = nameOf(p);
      if (!out.contains(n)) out.add(n);
    }
    return out;
  }

  /// The name the group goes by in messages: the group, or the kuri itself.
  String get displayGroup => group.trim().isEmpty ? name : group.trim();

  /// "Boystown 5K Kuri"
  String get fullName => group.trim().isEmpty ? name : '${group.trim()} $name';
}

int _int(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v.trim()) ?? fallback;
  return fallback;
}

Map<String, bool> _flags(dynamic v) {
  if (v is! Map) return {};
  return {for (final e in v.entries) if (e.value == true) '${e.key}': true};
}

dynamic _deep(dynamic v) {
  if (v is Map) return {for (final e in v.entries) '${e.key}': _deep(e.value)};
  if (v is List) return v.map(_deep).toList();
  return v;
}

/// A kuri as the server keeps it: the document plus who may do what.
class KuriRecord {
  KuriRecord({required this.id, required this.doc, required this.role, required this.shareToken, this.updatedAt, this.updatedBy});
  final String id;
  KuriDoc doc;
  final String role;
  String shareToken;
  DateTime? updatedAt;
  String? updatedBy;

  /// The updated_at exactly as the server sent it, for the next save.
  String? updatedAtRaw;

  bool get isOwner => role == 'owner';

  factory KuriRecord.fromJson(Map<String, dynamic> j) {
    final rec = KuriRecord(
      id: '${j['id']}',
      doc: KuriDoc.fromJson(j['data'] is Map ? Map<String, dynamic>.from(j['data'] as Map) : <String, dynamic>{}),
      role: '${j['role'] ?? 'admin'}',
      shareToken: '${j['share_token'] ?? ''}',
      updatedAt: DateTime.tryParse('${j['updated_at'] ?? ''}')?.toLocal(),
      updatedBy: j['updated_by'] as String?,
    );
    rec.updatedAtRaw = j['updated_at'] as String?;
    return rec;
  }
}
