import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/kuri.dart';
import 'package:kuree/core/reminders.dart';
import 'package:kuree/l10n/strings.dart';

/// A small chit: [slots] people paying 1000 each, from January 2026.
KuriRecord chit({
  String id = 'k1',
  String name = '5K Chit',
  String group = 'Riverside',
  int slots = 3,
  int collectDay = 20,
  int lastDay = 25,
  int startYear = 2026,
  int startMonth = 1,
  List<Map<String, dynamic>> months = const [],
}) {
  return KuriRecord.fromJson({
    'id': id,
    'role': 'owner',
    'share_token': 'tok',
    'data': {
      'name': name,
      'group': group,
      'share': 1000,
      'slots': slots,
      'startYear': startYear,
      'startMonth': startMonth,
      'collectDay': collectDay,
      'lastDay': lastDay,
      'people': [for (var i = 1; i <= slots; i++) {'id': 'm$i', 'name': 'Person $i'}],
      'payers': [for (var i = 1; i <= slots; i++) {'id': 'p$i', 'slot': i, 'person': 'm$i', 'amt': 1000}],
      'months': months,
    },
  });
}

void main() {
  final en = S.forCode('en');

  test('collection morning and the evening before the last day, for the next 60 days', () {
    final list = planReminders([chit()], DateTime(2026, 1, 10, 8), strings: en);
    expect([for (final r in list) (r.kind, r.month, r.at)], [
      (ReminderKind.collection, 1, DateTime(2026, 1, 20, 9)),
      (ReminderKind.lastDay, 1, DateTime(2026, 1, 24, 19)),
      (ReminderKind.collection, 2, DateTime(2026, 2, 20, 9)),
      (ReminderKind.lastDay, 2, DateTime(2026, 2, 24, 19)),
    ]);
    expect(list.first.body, 'Collection day for Riverside 5K Chit: 3 still to pay');
    expect(list[1].body, 'Last day to pay for Riverside 5K Chit is tomorrow: 3 still to pay');
    expect(list.every((r) => r.kuriId == 'k1'), isTrue);
  });

  test('counts the people still to pay, and skips months everyone paid', () {
    final k = chit(months: [
      {'n': 1, 'paid': {'p1': true, 'p2': true, 'p3': true}},
      {'n': 2, 'paid': {'p1': true}},
    ]);
    final list = planReminders([k], DateTime(2026, 1, 10, 8), strings: en);
    expect(list.map((r) => r.month).toSet(), {2});
    expect(list.first.body, 'Collection day for Riverside 5K Chit: 2 still to pay');
  });

  test('nothing in the past', () {
    final list = planReminders([chit()], DateTime(2026, 1, 20, 10), strings: en);
    expect(list.first.kind, ReminderKind.lastDay);
    expect(list.first.at, DateTime(2026, 1, 24, 19));
    expect(list.every((r) => r.at.isAfter(DateTime(2026, 1, 20, 10))), isTrue);
  });

  test('a chit that has ended has none', () {
    expect(planReminders([chit()], DateTime(2026, 6, 1), strings: en), isEmpty);
  });

  test('last day on the collection day: only the morning reminder', () {
    final list = planReminders([chit(lastDay: 20)], DateTime(2026, 1, 10), strings: en);
    expect(list.map((r) => r.kind).toSet(), {ReminderKind.collection});
  });

  test('a last day before the collection day falls in the month after', () {
    final list = planReminders([chit(collectDay: 25, lastDay: 5, slots: 1)], DateTime(2026, 1, 10), strings: en);
    expect([for (final r in list) (r.kind, r.at)], [
      (ReminderKind.collection, DateTime(2026, 1, 25, 9)),
      (ReminderKind.lastDay, DateTime(2026, 2, 4, 19)),
    ]);
  });

  test('a short month uses its last day', () {
    final list = planReminders([chit(collectDay: 31, lastDay: 31, startMonth: 2)], DateTime(2026, 2, 1), strings: en);
    expect(list.first.at, DateTime(2026, 2, 28, 9));
  });

  test('the last day on the 1st: the evening before is the last day of the month before', () {
    final list = planReminders([chit(collectDay: 28, lastDay: 1, slots: 1, startMonth: 2)], DateTime(2026, 2, 1), strings: en);
    expect([for (final r in list) (r.kind, r.at)], [
      (ReminderKind.collection, DateTime(2026, 2, 28, 9)),
      (ReminderKind.lastDay, DateTime(2026, 2, 28, 19)),
    ]);
  });

  test('no payers, no reminders', () {
    expect(planReminders([chit(slots: 0)], DateTime(2026, 1, 1), strings: en), isEmpty);
  });

  test('several chits: soonest first, never more than the phone keeps', () {
    final many = [
      for (var i = 0; i < 40; i++) chit(id: 'k${i.toString().padLeft(2, '0')}', collectDay: 1 + i % 28, lastDay: 1 + (i + 3) % 28, slots: 12),
    ];
    final list = planReminders(many, DateTime(2026, 1, 1), strings: en);
    expect(list.length, kMaxReminders);
    for (var i = 1; i < list.length; i++) {
      expect(list[i].at.isBefore(list[i - 1].at), isFalse);
    }
    expect(list.every((r) => !r.at.isAfter(DateTime(2026, 1, 1).add(kReminderWindow))), isTrue);
    expect(kMaxReminders, lessThan(64));
  });

  test('in the app language, without em dashes or middle dots', () {
    for (final code in S.codes) {
      final s = S.forCode(code);
      final list = planReminders([chit(group: '', name: 'Chit')], DateTime(2026, 1, 10), strings: s);
      expect(list, isNotEmpty);
      for (final r in list) {
        expect(r.body, contains('Chit'));
        expect(r.body, contains('3'));
        expect(r.body.contains('—') || r.body.contains('·'), isFalse);
      }
    }
    final ml = planReminders([chit()], DateTime(2026, 1, 10), strings: S.forCode('ml'));
    expect(ml.first.body, 'Riverside 5K Chit പിരിവ് ദിവസം: 3 പേർ ഇനിയും അടയ്ക്കാനുണ്ട്');
  });
}
