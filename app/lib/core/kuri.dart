import 'dart:math';

import '../l10n/strings.dart';
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

/// How a month's takers were chosen with the bottle draw.
class DrawInfo {
  DrawInfo({required this.at, required this.by, required this.picked, required this.names, List<int>? picks, this.how = 'bottle', Map<String, dynamic>? extra})
      : picks = picks ?? [picked],
        extra = extra ?? {};
  String how;
  String at;
  String by;

  /// The first slip out of the bottle.
  int picked;

  /// Every slip out of the bottle, in order (one for a month with one taker).
  List<int> picks;
  List<int> names;
  final Map<String, dynamic> extra;

  factory DrawInfo.fromJson(Map<String, dynamic> j) {
    final extra = Map<String, dynamic>.from(j)..remove('how')..remove('at')..remove('by')..remove('picked')..remove('names')..remove('picks');
    final picked = _int(j['picked'], 0);
    final picks = _slotList(j['picks']);
    return DrawInfo(
      how: '${j['how'] ?? 'bottle'}',
      at: '${j['at'] ?? ''}',
      by: '${j['by'] ?? ''}',
      picked: picked,
      // An older app keeps "picked" alone; "picks" must start with it.
      picks: picks.isNotEmpty && picks.first == picked ? picks : [picked],
      names: _slotList(j['names'], unique: false),
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => {
        ...extra,
        'how': how,
        'at': at,
        'by': by,
        'picked': picked,
        if (picks.length > 1) 'picks': picks,
        'names': names,
      };
}

class Month {
  Month({required this.n, List<int>? winners, Map<String, bool>? paid, Map<String, bool>? fines, this.fineAmt, this.note = '', this.draw, Map<String, dynamic>? extra})
      : winners = winners ?? [],
        paid = paid ?? {},
        fines = fines ?? {},
        extra = extra ?? {};
  int n;

  /// The slots taking the pot this month, in the order they were chosen.
  /// One for a chit with as many months as slots. Saved as "winner" (the
  /// first, which older apps read) and, when there are more, "winners".
  final List<int> winners;
  final Map<String, bool> paid;
  final Map<String, bool> fines;

  /// The fine for each late payment this month, kept when the chit's fine
  /// changed after these fines were marked. Null: the chit's fine.
  int? fineAmt;
  String note;
  DrawInfo? draw;
  final Map<String, dynamic> extra;

  bool isPaid(String id) => paid[id] == true;
  bool isFined(String id) => fines[id] == true;
  bool takes(int slot) => winners.contains(slot);
  bool get hasWinner => winners.isNotEmpty;

  /// The month's takers from the bottle, when the bottle chose all of them.
  bool get fromBottle {
    final d = draw;
    if (d == null || winners.isEmpty || d.picks.length != winners.length) return false;
    return d.picks.toSet().containsAll(winners);
  }

  factory Month.fromJson(Map<String, dynamic> j) {
    final extra = Map<String, dynamic>.from(j)
      ..remove('n')..remove('winner')..remove('winners')..remove('paid')..remove('fines')..remove('fineAmt')..remove('note')..remove('draw');
    final w = _int(j['winner'], 0);
    final first = w > 0 ? w : null;
    var winners = _slotList(j['winners']);
    if (j['winners'] is! List) {
      winners = [if (first != null) first];
    } else if (winners.isEmpty ? first != null : winners.first != first) {
      // An older app changed "winner" alone: it chose another taker for the
      // month, or cleared it.
      winners = first == null ? [] : [first, ...winners.skip(1).where((x) => x != first)];
    }
    return Month(
      n: _int(j['n'], 1),
      winners: winners,
      paid: _flags(j['paid']),
      fines: _flags(j['fines']),
      fineAmt: j['fineAmt'] == null ? null : _int(j['fineAmt'], 0),
      note: '${j['note'] ?? ''}',
      draw: j['draw'] is Map ? DrawInfo.fromJson(Map<String, dynamic>.from(j['draw'] as Map)) : null,
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => {
        ...extra,
        'n': n,
        'winner': winners.isEmpty ? null : winners.first,
        if (winners.length > 1) 'winners': winners,
        'paid': {for (final e in paid.entries) if (e.value) e.key: true},
        'fines': {for (final e in fines.entries) if (e.value) e.key: true},
        if (fineAmt != null) 'fineAmt': fineAmt,
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
    int? length,
    this.organiser = false,
    required this.startYear,
    required this.startMonth,
    this.collectDay = 20,
    this.lastDay = 25,
    this.fine = 200,
    this.currency = 'INR',
    List<Person>? people,
    List<Payer>? payers,
    List<Month>? months,
    this.updated = '',
    Map<String, dynamic>? extra,
  })  : length = length ?? slots,
        people = people ?? [],
        payers = payers ?? [],
        months = months ?? [],
        extra = extra ?? {};

  String name;
  String group;

  /// Each slot pays this every month.
  int share;
  int slots;

  /// How many months the chit runs. The same as the slots unless the chit
  /// ends sooner, with more than one slot taking the pot each month (and one
  /// more when the organiser takes the first month).
  int length;

  /// The organiser takes the first month's collection. The organiser is not
  /// one of the slots and pays nothing; the slots take the pot in the months
  /// after.
  bool organiser;
  int startYear;
  int startMonth;

  /// Collection day, and the last day to pay before the late fine.
  int collectDay;
  int lastDay;
  int fine;

  /// The chit's currency code: "INR" unless chosen otherwise.
  String currency;

  final List<Person> people;
  final List<Payer> payers;
  final List<Month> months;
  String updated;
  final Map<String, dynamic> extra;

  // 'groupLang' was a setting for the group message's language; messages now
  // follow the app's language, so an old value is read and dropped.
  static const _known = {
    'v', 'name', 'group', 'share', 'slots', 'length', 'organiser', 'startYear', 'startMonth', 'collectDay', 'lastDay', 'fine',
    'currency', 'groupLang', 'people', 'payers', 'months', 'updated',
  };

  factory KuriDoc.fromJson(Map<String, dynamic> j) {
    final extra = Map<String, dynamic>.from(j)..removeWhere((k, _) => _known.contains(k));
    List<Map<String, dynamic>> list(String k) =>
        (j[k] is List ? j[k] as List : const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final doc = KuriDoc(
      name: '${j['name'] ?? 'Chit'}',
      group: '${j['group'] ?? ''}',
      share: _int(j['share'], 0),
      slots: _int(j['slots'], 0),
      startYear: _int(j['startYear'], DateTime.now().year),
      startMonth: _int(j['startMonth'], DateTime.now().month).clamp(1, 12),
      collectDay: _int(j['collectDay'], 20).clamp(1, 31),
      lastDay: _int(j['lastDay'], 25).clamp(1, 31),
      fine: _int(j['fine'], 0),
      currency: currencyOf(j['currency'] as String?).code,
      people: list('people').map(Person.fromJson).toList(),
      payers: list('payers').map(Payer.fromJson).toList(),
      months: list('months').map(Month.fromJson).toList(),
      updated: '${j['updated'] ?? ''}',
      extra: extra,
    );
    if (doc.slots <= 0) doc.slots = doc.payers.fold<int>(0, (m, p) => max(m, p.slot));
    doc.organiser = j['organiser'] == true;
    final org = doc.organiser ? 1 : 0;
    // Chits saved before the length existed run a month per slot.
    doc.length = j['length'] == null ? doc.slots + org : _int(j['length'], doc.slots + org);
    if (doc.length > doc.slots + org || doc.length < 1 + org) doc.length = doc.slots + org;
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
        if (length != slots) 'length': length,
        if (organiser) 'organiser': true,
        'startYear': startYear,
        'startMonth': startMonth,
        'collectDay': collectDay,
        'lastDay': lastDay,
        'fine': fine,
        'currency': currency,
        'people': people.map((p) => p.toJson()).toList(),
        'payers': payers.map((p) => p.toJson()).toList(),
        'months': months.map((m) => m.toJson()).toList(),
        'updated': updated,
      };

  KuriDoc copy() => KuriDoc.fromJson(Map<String, dynamic>.from(_deep(toJson()) as Map));

  /// One month for every month of the chit, numbered from 1. (An older app
  /// adds a month for every slot; the ones past the end go again here.)
  void fitMonths() {
    for (var i = 0; i < months.length; i++) {
      months[i].n = i + 1;
    }
    while (months.length < length) {
      months.add(Month(n: months.length + 1));
    }
    if (months.length > length) months.removeRange(length, months.length);
  }

  // ---------------------------------------------------------------- takers each month

  /// The most slots that can take the pot in one month.
  static const maxWinners = 5;

  /// The shortest a chit of this many slots can run (a month longer with
  /// the organiser's month).
  static int minLength(int slots, [bool organiser = false]) =>
      max(1, (slots + maxWinners - 1) ~/ maxWinners) + (organiser ? 1 : 0);

  /// The longest: a month per slot, and the organiser's month.
  static int maxLength(int slots, [bool organiser = false]) => slots + (organiser ? 1 : 0);

  /// The months in which slots take the pot: all of them, or all but the
  /// organiser's first month.
  int get payoutMonths => max(1, length - (organiser ? 1 : 0));

  /// Month n is the organiser's.
  bool isOrganiserMonth(int n) => organiser && n == 1;

  /// More than one slot takes the pot in some month.
  bool get multi => payoutMonths < slots;

  /// How many slots take the pot in month n by the plan alone, before any
  /// extra draws (none in the organiser's month).
  int plannedIn(int n) {
    if (isOrganiserMonth(n)) return 0;
    return takersIn(slots, payoutMonths, organiser ? n - 1 : n);
  }

  /// How many slots take the pot in month n: the plan, with extra draws.
  /// A month can take one more when the money in hand covers a payout (see
  /// [canDrawExtra]); each extra taker then comes off the last months that
  /// still have places, so every slot still takes the pot once.
  int winnersIn(int n) {
    final p = takersPlan;
    return n >= 1 && n <= p.length ? p[n - 1] : 0;
  }

  /// The takers of every month, with extra draws moved in from the end.
  List<int> get takersPlan => adjustPlan(
        [for (var n = 1; n <= length; n++) plannedIn(n)],
        [for (var n = 1; n <= length; n++) n <= months.length ? months[n - 1].winners.length : 0],
      );

  /// [base] takers each month, and [got] chosen so far: a month with more
  /// chosen than planned keeps them, and that many places come off the last
  /// months that still have room. Where no month has room the extra stays,
  /// and the plan then adds up to more than the slots.
  static List<int> adjustPlan(List<int> base, List<int> got) {
    final plan = [for (var i = 0; i < base.length; i++) max(base[i], i < got.length ? got[i] : 0)];
    var extra = 0;
    for (var i = 0; i < base.length; i++) {
      extra += max(0, (i < got.length ? got[i] : 0) - base[i]);
    }
    for (var i = base.length - 1; i >= 0 && extra > 0; i--) {
      final room = plan[i] - (i < got.length ? got[i] : 0);
      final cut = min(room, extra);
      plan[i] -= cut;
      extra -= cut;
    }
    return plan;
  }

  /// Month m can draw one more taker from the money kept in hand: its own
  /// places are filled, there is enough in hand after it for one more
  /// payout, a later month still has a place to give up, and someone is
  /// still waiting.
  bool canDrawExtra(Month m) {
    if (isOrganiserMonth(m.n) || !multi) return false;
    if (m.winners.length < winnersIn(m.n)) return false;
    if (inHandAfter(m.n) < payout) return false;
    if (waitingSlots().isEmpty) return false;
    final p = takersPlan;
    for (var n = m.n + 1; n <= p.length; n++) {
      if (p[n - 1] > (n <= months.length ? months[n - 1].winners.length : 0)) return true;
    }
    return false;
  }

  /// Takers in month m beyond the plan: chosen with money kept in hand.
  int extraIn(Month m) => max(0, m.winners.length - plannedIn(m.n));

  /// How many slots take the pot in the k-th of `months` payout months: the
  /// slots over the months, and when that does not divide evenly the last
  /// months take one more (25 slots over 10 months: 2 in months 1 to 5, then
  /// 3). Every taker gets the same amount, so the months with fewer takers
  /// keep money in hand for the months with more.
  static int takersIn(int slots, int months, int k) {
    if (months <= 0 || k < 1 || k > months) return 0;
    return slots ~/ months + (k > months - slots % months ? 1 : 0);
  }

  /// How the takers fall over the months, in words: "2 people take the pot
  /// each month", or "3 people take the pot in each of the last 5 months, 2
  /// in the others". Null
  /// when one slot takes it each month.
  static String? planText(int slots, int months) {
    if (months <= 0 || months >= slots) return null;
    final s = S.current, base = slots ~/ months, extra = slots % months;
    if (extra == 0) return s.planEven(base);
    if (extra == 1) return s.planUnevenOne(base + 1, base);
    return s.planUneven(base + 1, extra, base);
  }

  String? get plan => planText(slots, payoutMonths);

  /// Places still open in month m.
  int openIn(Month m) => max(0, winnersIn(m.n) - m.winners.length);

  /// What a month collects: every slot's share, and the late fines.
  int monthTotal(Month m) => pot + fineSum(m);

  /// What every taker gets: each slot's share for each month the slots take
  /// the pot. With one taker a month that is the month's pot; in every chit
  /// it adds up to what the slots pay in (after the organiser's month).
  int get payout => share * payoutMonths;

  /// What each taker of month m gets: the payout, and the month's late fines
  /// in equal whole parts (any remainder a unit at a time to the first
  /// chosen).
  List<int> payouts(Month m) {
    final k = max(1, max(winnersIn(m.n), m.winners.length));
    final f = split(fineSum(m), k);
    return [for (var i = 0; i < k; i++) payout + f[i]];
  }

  /// What one taker of month m gets, the i-th chosen.
  int payoutOf(Month m, int i) {
    final p = payouts(m);
    return p[i.clamp(0, p.length - 1)];
  }

  /// total in k whole parts as equal as can be, the bigger ones first.
  static List<int> split(int total, int k) {
    if (k <= 1) return [total];
    final base = total ~/ k, rest = total - base * k;
    return [for (var i = 0; i < k; i++) base + (i < rest ? 1 : 0)];
  }

  /// What month n keeps in hand (more than it pays out) or, below zero,
  /// takes from what earlier months kept. Fines go out the month they come
  /// in, so they leave it as it is. Zero in the organiser's month.
  int keptIn(int n) => isOrganiserMonth(n) ? 0 : pot - winnersIn(n) * payout;

  /// The money in hand after month n, by the plan.
  int inHandAfter(int n) {
    var t = 0;
    for (var i = 1; i <= n && i <= length; i++) {
      t += keptIn(i);
    }
    return t;
  }

  // ---------------------------------------------------------------- money

  int get pot => share * slots;

  /// An amount in this chit's currency: ₹65,000 or AED 65,000.
  String money(num value) => currencyOf(currency).format(value);

  int paidSum(Month m) => payers.where((p) => m.isPaid(p.id)).fold(0, (t, p) => t + p.amt);

  int paidCount(Month m) => payers.where((p) => m.isPaid(p.id)).length;

  int fineCount(Month m) => payers.where((p) => m.isFined(p.id)).length;

  /// The fine for each late payment in month m.
  int fineFor(Month m) => m.fineAmt ?? fine;

  int fineSum(Month m) => fineCount(m) * fineFor(m);

  /// A new fine for the chit. Fines already marked keep the amount they were
  /// marked at; every other late payment takes the new one.
  void setFine(int value) {
    if (value == fine) return;
    for (final m in months) {
      if (m.fineAmt == null && m.fines.values.any((v) => v)) m.fineAmt = fine;
      if (m.fineAmt == value) m.fineAmt = null;
    }
    fine = value;
  }

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
    return '${monthName(d.month)} ${d.year}';
  }

  String monthShort(int n) => monthShortName(collectDate(n).month);

  /// The month whose collection falls in this calendar month, kept inside the kuri.
  int currentMonth([DateTime? now]) {
    final t = now ?? DateTime.now();
    final n = (t.year * 12 + t.month) - (startYear * 12 + startMonth) + 1;
    return n.clamp(1, max(1, months.length));
  }

  MonthState state(Month m, [DateTime? now]) {
    if (allPaid(m) && (m.hasWinner || isOrganiserMonth(m.n)) && m.winners.length >= winnersIn(m.n)) return MonthState.done;
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
    final s = S.current;
    final dc = daysTo(collectDate(n));
    if (dc > 1) return s.noteInDays(dc);
    if (dc == 1) return s.noteTomorrow;
    if (dc == 0) return s.noteToday;
    final dd = daysTo(deadline(n));
    if (dd > 1) return s.noteDaysLeft(dd);
    if (dd == 1) return s.noteLastDayTomorrow;
    if (dd == 0) return s.notePayToday;
    return s.noteDeadlinePassed;
  }

  // ---------------------------------------------------------------- people and slots

  Person? personById(String id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  String nameOf(Payer p) => personById(p.person)?.name ?? S.current.someone;

  List<Payer> payersIn(int slot) => payers.where((p) => p.slot == slot).toList();

  /// "Farhan / Yasir"
  String slotName(int slot) {
    final names = payersIn(slot).map(nameOf).toList();
    return names.isEmpty ? S.current.slotN(slot) : names.join(' / ');
  }

  /// "Farhan and Yasir"
  String slotNameAnd(int slot) {
    final names = payersIn(slot).map(nameOf).toList();
    if (names.isEmpty) return S.current.slotN(slot);
    if (names.length == 1) return names.first;
    return S.current.andJoin(names.sublist(0, names.length - 1).join(', '), names.last);
  }

  /// Several slots' names: "Nazil", "Nazil and Farhan / Yasir",
  /// "Nazil, Anwar and Mufaz".
  String slotsName(List<int> slots) {
    final names = slots.map(slotName).toList();
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    return S.current.andJoin(names.sublist(0, names.length - 1).join(', '), names.last);
  }

  /// The takers of month m by name, or null when there are none yet.
  String? winnersName(Month m) => m.winners.isEmpty ? null : slotsName(m.winners);

  /// "½ share" for half of a slot, or the amount for any other part.
  String? partLabel(Payer p) {
    if (p.amt >= share || share <= 0) return null;
    final s = S.current;
    if (p.amt * 2 == share) return s.shareHalf;
    if (p.amt * 3 == share) return s.shareThird;
    if (p.amt * 4 == share) return s.shareQuarter;
    return s.shareAmount(money(p.amt));
  }

  /// slot -> the month it took the pot
  Map<int, int> drawn() => {for (final m in months) for (final w in m.winners) w: m.n};

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
      final person = personById(p.person) ?? Person(id: p.person, name: S.current.someone);
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

/// Slot numbers from a saved list, each once, in order.
List<int> _slotList(dynamic v, {bool unique = true}) {
  if (v is! List) return [];
  final out = <int>[];
  for (final e in v) {
    final x = _int(e, 0);
    if (x > 0 && (!unique || !out.contains(x))) out.add(x);
  }
  return out;
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
