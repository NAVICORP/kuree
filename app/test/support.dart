// Shared by the widget tests: the app's fonts (so text is measured as on a
// phone) and a made-up chit.
import 'package:flutter/services.dart';
import 'package:kuree/core/kuri.dart';

/// Loads the fonts the app ships, Noto scripts included, into the test.
Future<void> loadAppFonts() async {
  Future<void> family(String name, List<String> files) async {
    final l = FontLoader(name);
    for (final f in files) {
      l.addFont(rootBundle.load(f));
    }
    await l.load();
  }

  await family('Manrope', [for (final w in [500, 600, 700, 800]) 'assets/fonts/Manrope-$w.ttf']);
  await family('Bricolage', [for (final w in [600, 700, 800]) 'assets/fonts/BricolageGrotesque-$w.ttf']);
  for (final f in ['Manjari', 'NotoNaskhArabic', 'NotoSansTamil', 'NotoSansKannada', 'NotoSansDevanagari']) {
    await family(f, ['assets/fonts/$f-500.ttf', 'assets/fonts/$f-700.ttf']);
  }
}

/// A made-up 13 slot chit, five months in, with a shared slot, two slots for
/// one person, a late fine and someone without a number.
KuriRecord demoChit({String currency = 'INR'}) {
  final names = ['Nazil', 'Ramshad Ac', 'Anees Muhammed', 'Ishaque', 'Ashif', 'Muhajir', 'Sinan KP', 'Naif', 'Farhan', 'Yasir', 'Anwar', 'Mufaz'];
  final people = [for (var i = 0; i < names.length; i++) {'id': 'm${i + 1}', 'name': names[i], 'phone': i == 9 ? '' : '9190000000${i.toString().padLeft(2, '0')}'}];
  String id(String n) => people.firstWhere((p) => p['name'] == n)['id']!;
  const r = [
    ['p1', 1, 'Nazil', 5000], ['p2', 2, 'Nazil', 5000], ['p3', 3, 'Ramshad Ac', 5000], ['p4', 4, 'Anees Muhammed', 5000],
    ['p5', 5, 'Ishaque', 5000], ['p6', 6, 'Ashif', 5000], ['p7', 7, 'Muhajir', 5000], ['p8', 8, 'Sinan KP', 5000],
    ['p9', 9, 'Naif', 5000], ['p10a', 10, 'Farhan', 2500], ['p10b', 10, 'Yasir', 2500], ['p11', 11, 'Anwar', 5000],
    ['p12', 12, 'Mufaz', 5000], ['p13', 13, 'Mufaz', 5000],
  ];
  final payers = [for (final x in r) {'id': x[0], 'slot': x[1], 'person': id(x[2] as String), 'amt': x[3]}];
  final all = {for (final x in r) x[0] as String: true};
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 4, 1);
  return KuriRecord.fromJson({
    'id': '00000000-0000-0000-0000-000000000001',
    'role': 'owner',
    'share_token': 'abcdefghijklmnopqrstuvwx',
    'updated_at': now.subtract(const Duration(minutes: 7)).toUtc().toIso8601String(),
    'updated_by': 'Anees Muhammed',
    'data': {
      'name': '5K Chit', 'group': 'Riverside', 'share': 5000, 'slots': 13, 'startYear': start.year, 'startMonth': start.month,
      'collectDay': 20, 'lastDay': 25, 'fine': 200, 'currency': currency, 'people': people, 'payers': payers,
      'months': [
        {'n': 1, 'winner': 4, 'paid': all},
        {'n': 2, 'winner': 11, 'paid': all},
        {'n': 3, 'winner': 8, 'paid': all, 'fines': {'p5': true}},
        {'n': 4, 'winner': 7, 'paid': all},
        {'n': 5, 'winner': null, 'paid': {for (final k in ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8']) k: true}, 'fines': {'p6': true}},
      ],
    },
  });
}

/// A made-up chit with more slots than months: [slots] slots over [length]
/// months (20 over 10 by default, two takers a month), three months in.
/// Slot 6 is shared by two people.
KuriRecord multiChit({int slots = 20, int length = 10, String currency = 'INR'}) => KuriRecord.fromJson(multiChitJson(slots: slots, length: length, currency: currency));

Map<String, dynamic> multiChitJson({int slots = 20, int length = 10, String currency = 'INR'}) {
  const names = [
    'Nazil', 'Ramshad Ac', 'Anees Muhammed', 'Ishaque', 'Ashif', 'Muhajir', 'Sinan KP', 'Naif', 'Farhan', 'Yasir', 'Anwar',
    'Mufaz', 'Shameer', 'Riyas', 'Faseela', 'Jasna', 'Nabeel', 'Salman', 'Meera', 'Anand', 'Riya', 'Jaseem', 'Aswathy', 'Faisal',
    'Rahul', 'Fathima',
  ];
  final people = [for (var i = 0; i < names.length; i++) {'id': 'm${i + 1}', 'name': names[i]}];
  final payers = <Map<String, dynamic>>[];
  var who = 0;
  for (var s = 1; s <= slots; s++) {
    if (s == 6) {
      payers.add({'id': 'p6a', 'slot': 6, 'person': 'm${++who}', 'amt': 2500});
      payers.add({'id': 'p6b', 'slot': 6, 'person': 'm${++who}', 'amt': 2500});
    } else {
      payers.add({'id': 'p$s', 'slot': s, 'person': 'm${++who}', 'amt': 5000});
    }
  }
  final all = {for (final p in payers) p['id'] as String: true};
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 2, 1);
  return {
    'id': '00000000-0000-0000-0000-000000000003',
    'role': 'owner',
    'share_token': 'mmmmmmmmmmmmmmmmmmmmmmmm',
    'updated_at': now.subtract(const Duration(minutes: 3)).toUtc().toIso8601String(),
    'updated_by': 'Ishaque',
    'data': {
      'name': '5K Chit', 'group': 'Hilltop', 'share': 5000, 'slots': slots, 'length': length, 'startYear': start.year,
      'startMonth': start.month, 'collectDay': 20, 'lastDay': 25, 'fine': 200, 'currency': currency, 'people': people, 'payers': payers,
      'months': [
        {'n': 1, 'winner': 4, 'winners': [4, 11], 'paid': all},
        {'n': 2, 'winner': 8, 'winners': [8, 15], 'paid': all, 'fines': {'p3': true},
         'draw': {'how': 'bottle', 'at': '2026-10-20T14:01:43.581Z', 'by': 'Ishaque', 'picked': 8, 'picks': [8, 15], 'names': [for (var s = 1; s <= slots; s++) if (s != 4 && s != 11) s]}},
        {'n': 3, 'winner': null, 'paid': {for (final p in payers.take(9)) p['id'] as String: true}},
      ],
    },
  };
}
