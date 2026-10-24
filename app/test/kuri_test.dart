import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/format.dart';
import 'package:kuree/core/kuri.dart';
import 'package:kuree/core/messages.dart';

/// The Boystown 5K Kuri as it stood on 23 Oct 2026 (month 5 partly paid).
KuriDoc boystown() {
  final names = ['Nazil', 'Ramshad Ac', 'Anees Muhammed', 'Ishaque', 'Ashif', 'Muhajir', 'Sinan KP', 'Naif', 'Farhan', 'Yasir', 'Anwar', 'Mufaz'];
  final people = [for (var i = 0; i < names.length; i++) {'id': 'm${i + 1}', 'name': names[i], 'phone': i == 7 ? '919000000008' : ''}];
  String id(String n) => people.firstWhere((p) => p['name'] == n)['id']!;
  final payers = [
    {'id': 'p1', 'slot': 1, 'person': id('Nazil'), 'amt': 5000},
    {'id': 'p2', 'slot': 2, 'person': id('Nazil'), 'amt': 5000},
    {'id': 'p3', 'slot': 3, 'person': id('Ramshad Ac'), 'amt': 5000},
    {'id': 'p4', 'slot': 4, 'person': id('Anees Muhammed'), 'amt': 5000},
    {'id': 'p5', 'slot': 5, 'person': id('Ishaque'), 'amt': 5000},
    {'id': 'p6', 'slot': 6, 'person': id('Ashif'), 'amt': 5000},
    {'id': 'p7', 'slot': 7, 'person': id('Muhajir'), 'amt': 5000},
    {'id': 'p8', 'slot': 8, 'person': id('Sinan KP'), 'amt': 5000},
    {'id': 'p9', 'slot': 9, 'person': id('Naif'), 'amt': 5000},
    {'id': 'p10a', 'slot': 10, 'person': id('Farhan'), 'amt': 2500},
    {'id': 'p10b', 'slot': 10, 'person': id('Yasir'), 'amt': 2500},
    {'id': 'p11', 'slot': 11, 'person': id('Anwar'), 'amt': 5000},
    {'id': 'p12', 'slot': 12, 'person': id('Mufaz'), 'amt': 5000},
    {'id': 'p13', 'slot': 13, 'person': id('Mufaz'), 'amt': 5000},
  ];
  final all = {for (final p in payers) p['id']: true};
  return KuriDoc.fromJson({
    'name': '5K Kuri', 'group': 'Boystown', 'share': 5000, 'slots': 13, 'startYear': 2026, 'startMonth': 6,
    'collectDay': 20, 'lastDay': 25, 'fine': 200, 'people': people, 'payers': payers,
    'months': [
      {'n': 1, 'winner': 4, 'paid': all, 'fines': {}},
      {'n': 2, 'winner': 11, 'paid': all, 'fines': {}},
      {'n': 3, 'winner': 8, 'paid': all, 'fines': {'p5': true}},
      {'n': 4, 'winner': 7, 'paid': all, 'fines': {}},
      {'n': 5, 'winner': 9, 'paid': {'p1': true, 'p2': true, 'p3': true, 'p4': true, 'p5': true, 'p6': true, 'p7': true, 'p8': true}, 'fines': {},
       'draw': {'how': 'bottle', 'at': '2026-10-20T14:01:43.581Z', 'by': 'Anees Muhammed', 'picked': 9, 'names': [1, 2, 3, 5, 6, 9, 10, 12, 13]}},
    ],
  });
}

void main() {
  group('money and words', () {
    test('Indian grouping', () {
      expect(money(65000), '₹65,000');
      expect(money(150000), '₹1,50,000');
      expect(money(200), '₹200');
      expect(money(12345678), '₹1,23,45,678');
    });
    test('ordinals', () {
      expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 25].map(ordinal).toList(),
          ['1st', '2nd', '3rd', '4th', '11th', '12th', '13th', '21st', '22nd', '25th']);
    });
    test('phone numbers', () {
      expect(phoneDigits('90721 50276'), '919072150276');
      expect(phoneDigits('+971 50 123 4567'), '971501234567');
      expect(phoneDigits('09072150276'), '919072150276');
      expect(prettyPhone('919072150276'), '+91 90721 50276');
    });
  });

  group('the Boystown 5K Kuri', () {
    final k = boystown();
    test('pot, months and dates', () {
      expect(k.pot, 65000);
      expect(k.months.length, 13);
      expect(k.monthLabel(1), 'June 2026');
      expect(k.monthLabel(13), 'June 2027');
      expect(k.collectDate(5), DateTime(2026, 10, 20));
      expect(k.deadline(5), DateTime(2026, 10, 25, 23, 59, 59));
      expect(k.currentMonth(DateTime(2026, 10, 24)), 5);
      expect(k.currentMonth(DateTime(2030, 1, 1)), 13);
    });
    test('who paid and who owes', () {
      final m = k.months[4];
      expect(k.paidCount(m), 8);
      expect(k.paidSum(m), 40000);
      final dues = k.dues(m);
      expect(dues.map((d) => d.person.name).toList(), ['Naif', 'Farhan', 'Yasir', 'Anwar', 'Mufaz']);
      expect(dues.last.amount, 10000); // two slots
      expect(k.paidNames(m).first, 'Nazil');
      expect(k.paidNames(m).where((n) => n == 'Nazil').length, 1);
      expect(k.fineSum(k.months[2]), 200);
      expect(k.allFines, 200);
    });
    test('slots', () {
      expect(k.slotName(10), 'Farhan / Yasir');
      expect(k.slotNameAnd(10), 'Farhan and Yasir');
      expect(k.partLabel(k.payers.firstWhere((p) => p.id == 'p10a')), '½ share');
      expect(k.waitingSlots(), [1, 2, 3, 5, 6, 10, 12, 13]);
      expect(k.drawn()[9], 5);
    });
    test('state and countdown', () {
      expect(k.state(k.months[0], DateTime(2026, 10, 24)), MonthState.done);
      expect(k.state(k.months[4], DateTime(2026, 10, 24)), MonthState.open);
      expect(k.state(k.months[5], DateTime(2026, 10, 24)), MonthState.soon);
      expect(k.nextNote(5, DateTime(2026, 10, 23)), '2 days left to pay');
      expect(k.nextNote(5, DateTime(2026, 10, 25, 9)), 'pay by midnight today');
      expect(k.nextNote(5, DateTime(2026, 10, 26)), 'deadline passed');
      expect(k.nextNote(6, DateTime(2026, 10, 26)), 'in 25 days');
    });
    test('survives a round trip, keeping unknown fields', () {
      final j = k.toJson()..['source'] = 'boystown-5k';
      final again = KuriDoc.fromJson(j);
      expect(again.toJson(), j);
      expect(again.months[4].draw!.names, [1, 2, 3, 5, 6, 9, 10, 12, 13]);
    });
    test('the reminders read as before', () {
      final m = k.months[4];
      final naif = k.dues(m).first;
      expect(reminderFor(k, m, naif),
          'Hi Naif, a reminder from Boystown: your 5K Kuri payment of ₹5,000 for month 5 (October 2026) is due by midnight on the 25th. '
          'After that there is a late fine of ₹200. Thank you.');
      final g = groupList(k, m, 'abc123abc123abc123');
      expect(g.split('\n').first, '*October : Paid*');
      expect(g.contains('✅ Ishaque'), isTrue);
      expect(g.contains('*October : Not paid yet*\n❌ Naif'), isTrue);
      expect(g.endsWith('\n\nhttps://kureeapp.com/k/abc123abc123abc123'), isTrue);
      expect(whatsApp('✅ hi', phone: '9072150276').toString(), startsWith('https://api.whatsapp.com/send?phone=919072150276&text='));
    });
  });

  group('dates in other months', () {
    test('a last day before the collection day falls in the next month', () {
      final k = KuriDoc(name: 'K', share: 1000, slots: 3, startYear: 2026, startMonth: 1, collectDay: 28, lastDay: 3);
      k.fitMonths();
      expect(k.deadline(1), DateTime(2026, 2, 3, 23, 59, 59));
    });
    test('the 31st in a short month is its last day', () {
      final k = KuriDoc(name: 'K', share: 1000, slots: 3, startYear: 2026, startMonth: 2, collectDay: 31, lastDay: 31);
      expect(k.collectDate(1), DateTime(2026, 2, 28));
    });
  });

  group('fairness', () {
    test('shuffles keep every slot once', () {
      final s = shuffled([1, 2, 3, 4, 5, 6, 7, 8]);
      expect(s.toSet(), {1, 2, 3, 4, 5, 6, 7, 8});
    });
    test('the pick is spread evenly', () {
      final counts = List.filled(5, 0);
      for (var i = 0; i < 50000; i++) {
        counts[fair(5)]++;
      }
      for (final c in counts) {
        expect(c, inInclusiveRange(9300, 10700));
      }
    });
  });
}
