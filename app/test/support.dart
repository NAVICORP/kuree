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
  for (final s in ['Arabic', 'Malayalam', 'Tamil', 'Kannada', 'Devanagari']) {
    await family('NotoSans$s', ['assets/fonts/NotoSans$s-500.ttf', 'assets/fonts/NotoSans$s-700.ttf']);
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
