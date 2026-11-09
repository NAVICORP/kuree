// Chits with more slots than months: several slots take the pot each month.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/kuri.dart';
import 'package:kuree/core/messages.dart';

import 'support.dart';

KuriDoc doc({int slots = 20, int length = 10}) =>
    KuriDoc.fromJson(Map<String, dynamic>.from(multiChitJson(slots: slots, length: length)['data'] as Map));

/// A JSON copy, as the server keeps it.
Map<String, dynamic> wire(KuriDoc k) => jsonDecode(jsonEncode(k.toJson())) as Map<String, dynamic>;

void main() {
  group('how many take the pot each month', () {
    test('20 slots over 10 months: two every month', () {
      final k = doc();
      expect(k.months.length, 10);
      expect(k.multi, isTrue);
      expect([for (var n = 1; n <= 10; n++) k.winnersIn(n)], List.filled(10, 2));
      expect(k.plan, '2 people take the pot each month');
    });
    test('25 slots over 10 months: three in months 1 to 5, then two', () {
      final k = doc(slots: 25);
      expect([for (var n = 1; n <= 10; n++) k.winnersIn(n)], [3, 3, 3, 3, 3, 2, 2, 2, 2, 2]);
      expect(k.plan, '3 people take the pot in months 1 to 5, then 2');
      expect(KuriDoc.planText(21, 10), '3 people take the pot in month 1, then 2');
    });
    test('every slot gets exactly one place, whatever the length', () {
      for (var slots = 2; slots <= 60; slots++) {
        for (var len = KuriDoc.minLength(slots); len <= slots; len++) {
          final takers = [for (var n = 1; n <= len; n++) KuriDoc.takersIn(slots, len, n)];
          expect(takers.fold<int>(0, (a, b) => a + b), slots, reason: '$slots over $len');
          expect(takers.every((t) => t >= 1 && t <= KuriDoc.maxWinners), isTrue, reason: '$slots over $len');
          // never more in a later month than an earlier one
          for (var n = 1; n < takers.length; n++) {
            expect(takers[n] <= takers[n - 1], isTrue);
          }
        }
      }
      expect(KuriDoc.minLength(20), 4);
      expect(KuriDoc.minLength(21), 5);
      expect(KuriDoc.planText(13, 13), isNull);
    });
  });

  group('the money', () {
    test('an even split: the month\'s collection in equal parts', () {
      final k = doc();
      expect(k.pot, 100000);
      expect(k.payouts(k.months[0]), [50000, 50000]);
      // a late fine goes into that month's pot, shared too
      expect(k.fineSum(k.months[1]), 200);
      expect(k.monthTotal(k.months[1]), 100200);
      expect(k.payouts(k.months[1]), [50100, 50100]);
    });
    test('an uneven split: whole amounts that add up, months with fewer takers get more each', () {
      final k = doc(slots: 25);
      expect(k.pot, 125000);
      final three = k.payouts(k.months[0]);
      expect(three, [41667, 41667, 41666]);
      expect(three.fold<int>(0, (a, b) => a + b), 125000);
      expect(k.payouts(k.months[9]), [62500, 62500]);
      expect(k.payoutOf(k.months[0], 2), 41666);
      expect(KuriDoc.split(10, 3), [4, 3, 3]);
      expect(KuriDoc.split(65000, 1), [65000]);
    });
    test('shared parts: a shared slot pays its parts, and the pot is still every slot\'s share', () {
      final k = doc();
      final six = k.payersIn(6);
      expect(six.map((p) => p.amt), [2500, 2500]);
      expect(k.payers.fold<int>(0, (t, p) => t + p.amt), k.pot);
      expect(k.paidSum(k.months[0]), k.pot);
      // the third month: the first nine payers, slot 6 being two of them
      expect(k.paidSum(k.months[2]), 7 * 5000 + 2 * 2500);
      expect(k.slotName(6), 'Muhajir / Sinan KP');
    });
    test('one taker a month is exactly as before', () {
      final k = KuriDoc.fromJson(Map<String, dynamic>.from(demoChit().doc.toJson()));
      expect(k.length, k.slots);
      expect(k.multi, isFalse);
      expect(k.winnersIn(3), 1);
      expect(k.payouts(k.months[2]), [k.pot + 200]);
    });
  });

  group('who has taken the pot', () {
    test('every taker of every month is out of the draw', () {
      final k = doc();
      expect(k.drawn(), {4: 1, 11: 1, 8: 2, 15: 2});
      expect(k.waitingSlots().length, 16);
      expect(k.waitingSlots().contains(4), isFalse);
      expect(k.winnersName(k.months[0]), 'Ishaque and Mufaz');
      expect(k.months[1].fromBottle, isTrue);
      expect(k.months[0].fromBottle, isFalse);
    });
    test('a month is settled once everyone paid and every place is taken', () {
      final k = doc();
      final m = k.months[0];
      final later = k.collectDate(1).add(const Duration(days: 40));
      expect(k.state(m, later), MonthState.done);
      m.winners.removeLast();
      expect(k.openIn(m), 1);
      expect(k.state(m, later), MonthState.open);
    });
    test('the draw result names everyone and what each gets', () {
      final k = doc();
      final text = drawResult(k, 3, [2, 6], 16, DateTime(2026, 11, 20, 19, 31));
      expect(text, contains('2. Ramshad Ac\n6. Muhajir / Sinan KP'));
      expect(text, contains('₹50,000 each.'));
      expect(text, contains('16 names were in the bottle'));
    });
  });

  group('saved documents', () {
    test('a chit saved before lengths existed runs a month per slot, and saves as before', () {
      final j = demoChit().doc.toJson();
      expect(j.containsKey('length'), isFalse);
      final k = KuriDoc.fromJson(j);
      expect(k.length, 13);
      expect(k.months.length, 13);
      final again = wire(k);
      expect(again.containsKey('length'), isFalse);
      for (final m in again['months'] as List) {
        expect((m as Map).containsKey('winners'), isFalse);
        expect(m.containsKey('winner'), isTrue);
      }
      expect(KuriDoc.fromJson(again).toJson(), k.toJson());
    });
    test('several takers keep "winner" as the first, for older apps and the server', () {
      final j = wire(doc());
      expect(j['length'], 10);
      final m1 = (j['months'] as List).first as Map;
      expect(m1['winner'], 4);
      expect(m1['winners'], [4, 11]);
      final m3 = (j['months'] as List)[2] as Map;
      expect(m3['winner'], isNull);
      expect(m3.containsKey('winners'), isFalse);
      final draw = (j['months'] as List)[1]['draw'] as Map;
      expect(draw['picked'], 8);
      expect(draw['picks'], [8, 15]);
      expect(KuriDoc.fromJson(j).toJson(), doc().toJson());
    });
    test('an older app that changed or cleared "winner" alone is believed', () {
      final j = wire(doc());
      final months = j['months'] as List;
      (months[0] as Map)['winner'] = 5; // chose slot 5 instead of 4
      (months[1] as Map)['winner'] = null; // cleared month 2
      final k = KuriDoc.fromJson(j);
      expect(k.months[0].winners, [5, 11]);
      expect(k.months[1].winners, isEmpty);
    });
    test('the months an older app adds for every slot go again, the length stays', () {
      final j = wire(doc());
      final months = j['months'] as List;
      for (var n = months.length + 1; n <= 20; n++) {
        months.add({'n': n, 'winner': null, 'paid': {}, 'fines': {}, 'note': ''});
      }
      // what an older app keeps: "length" as an unknown field, "winners" in each month
      final k = KuriDoc.fromJson(j);
      expect(k.length, 10);
      expect(k.months.length, 10);
      expect(k.months[0].winners, [4, 11]);
    });
    test('a length past the slots, or none that makes sense, is a month per slot', () {
      final j = wire(doc());
      j['length'] = 40;
      expect(KuriDoc.fromJson(j).length, 20);
      j['length'] = 0;
      expect(KuriDoc.fromJson(j).length, 20);
    });
  });

  group('the bottle with several places', () {
    test('picks k different slips, all from the bottle', () {
      final waiting = doc().waitingSlots();
      for (var i = 0; i < 200; i++) {
        final got = pickSome(waiting, 3);
        expect(got.length, 3);
        expect(got.toSet().length, 3);
        expect(waiting.toSet().containsAll(got), isTrue);
      }
      expect(pickSome([1, 2], 5).toSet(), {1, 2});
    });
    test('takes them in turn: a pick from what is left each time', () {
      final seen = <int>[];
      final got = pickSome([10, 20, 30, 40], 3, (n) {
        seen.add(n);
        return 0;
      });
      expect(seen, [4, 3, 2]);
      expect(got, [10, 20, 30]);
    });
    test('every slip is as likely to come out', () {
      final counts = <int, int>{};
      for (var i = 0; i < 30000; i++) {
        for (final x in pickSome([1, 2, 3, 4, 5], 2)) {
          counts[x] = (counts[x] ?? 0) + 1;
        }
      }
      for (final c in counts.values) {
        expect(c, inInclusiveRange(11300, 12700));
      }
    });
  });
}
