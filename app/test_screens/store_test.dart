// The app screens for the App Store and Google Play pictures, with the
// made-up Riverside 10K Kuri (no real names). Drawn at the size of a 6.7"
// iPhone (1290 x 2796) with its notch and home bar space; the captions and
// frames are added afterwards (tools/store/make.cjs). Run with:
// flutter test test_screens --update-goldens
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/api.dart';
import 'package:kuree/core/kuri.dart';
import 'package:kuree/draw/scene.dart';
import 'package:kuree/ui/home.dart';
import 'package:kuree/ui/kuri_editor.dart';
import 'package:kuree/ui/kuri_screen.dart';
import 'package:kuree/ui/theme.dart';

Future<void> loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final l = FontLoader(name);
    for (final f in files) {
      l.addFont(rootBundle.load(f));
    }
    await l.load();
  }

  await family('Manrope', [for (final w in [500, 600, 700, 800]) 'assets/fonts/Manrope-$w.ttf']);
  await family('Bricolage', [for (final w in [600, 700, 800]) 'assets/fonts/BricolageGrotesque-$w.ttf']);
  // Material icons, from the Flutter SDK running the test.
  final roots = <String>[
    if (Platform.environment['FLUTTER_ROOT'] != null) Platform.environment['FLUTTER_ROOT']!,
    File(Platform.resolvedExecutable).parent.path,
  ];
  for (final r in roots) {
    var dir = Directory(r);
    for (var i = 0; i < 8; i++) {
      final f = File('${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
      final g = File('${dir.path}/artifacts/material_fonts/MaterialIcons-Regular.otf');
      for (final x in [f, g]) {
        if (x.existsSync()) {
          final l = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(x.readAsBytesSync().buffer)));
          await l.load();
          return;
        }
      }
      dir = dir.parent;
    }
  }
}

Widget phone(Widget child) => MaterialApp(debugShowCheckedModeBanner: false, theme: kureeTheme(), home: child);

Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      final w = e.widget as Image;
      await precacheImage(w.image, e);
    }
  });
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

/// The demo kuri, the same one as kureeapp.com/k/demo (server/demo.mjs):
/// Riverside 10K Kuri, made-up names. Month 5 is this month, collected two
/// days ago, with a few days left to pay.
KuriRecord riverside() {
  const names = ['Rahul', 'Fathima', 'Jibin', 'Shabna', 'Vishnu', 'Ann Mary', 'Salman', 'Meera', 'Anand', 'Riya', 'Jaseem', 'Aswathy', 'Faisal'];
  const slot = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 11, 12];
  const winners = [6, 2, 11, 8];
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 4, 1);
  final collect = (now.day - 2).clamp(1, 26);
  final people = [
    for (var i = 0; i < names.length; i++) {'id': 'p${i + 1}', 'name': names[i], if (i != 12) 'phone': '9190000000${i.toString().padLeft(2, '0')}'},
  ];
  final payers = [for (var i = 0; i < names.length; i++) {'id': 's${i + 1}', 'slot': slot[i], 'person': 'p${i + 1}', 'amt': slot[i] == 10 ? 5000 : 10000}];
  final all = {for (var i = 0; i < names.length; i++) 's${i + 1}': true};
  const unpaid = {'s5', 's9', 's11', 's13'};
  return KuriRecord.fromJson({
    'id': '00000000-0000-0000-0000-0000000000d1',
    'role': 'owner',
    'share_token': 'demo',
    'updated_at': now.subtract(const Duration(minutes: 4)).toUtc().toIso8601String(),
    'updated_by': 'Rahul',
    'data': {
      'name': '10K Chit', 'group': 'Riverside', 'share': 10000, 'slots': 12, 'startYear': start.year, 'startMonth': start.month,
      'collectDay': collect, 'lastDay': collect + 5, 'fine': 200, 'people': people, 'payers': payers,
      'months': [
        for (var n = 1; n <= 4; n++)
          {
            'n': n,
            'winner': winners[n - 1],
            'paid': all,
            if (n == 2) 'fines': {'s7': true},
            if (n == 4) 'fines': {'s3': true},
          },
        {'n': 5, 'winner': null, 'paid': {for (final k in all.keys) if (!unpaid.contains(k)) k: true}},
      ],
    },
  });
}

/// A second, smaller kuri for the home screen.
KuriRecord family() => KuriRecord.fromJson({
      'id': '00000000-0000-0000-0000-0000000000d2',
      'role': 'admin',
      'share_token': 'zyxwvutsrqponmlkjihgfedc',
      'data': {
        'name': 'Family Chit', 'group': '', 'share': 2000, 'slots': 6, 'startYear': DateTime.now().year, 'startMonth': DateTime.now().month,
        'collectDay': 5, 'lastDay': 10, 'fine': 0,
        'people': [for (var i = 1; i <= 6; i++) {'id': 'm$i', 'name': ['Amina', 'Joseph', 'Rafeek', 'Divya', 'Thomas', 'Nisha'][i - 1]}],
        'payers': [for (var i = 1; i <= 6; i++) {'id': 'p$i', 'slot': i, 'person': 'm$i', 'amt': 2000}],
        'months': [{'n': 1, 'paid': {'p1': true, 'p2': true, 'p3': true, 'p4': true}}],
      },
    });

Future<void> store(WidgetTester tester, String name) async {
  await settle(tester);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/store-$name.png'));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadFonts();
    Api.instance.offline = true;
  });

  void sized(WidgetTester tester) {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
  }

  testWidgets('store: the month', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(KuriScreen(record: riverside())));
    await store(tester, 'month');
    await tester.drag(find.byType(ListView).first, const Offset(0, -620));
    await store(tester, 'members');
  });

  testWidgets('store: reminders', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(KuriScreen(record: riverside())));
    await settle(tester);
    await tester.tap(find.text('Reminders'));
    await store(tester, 'reminders');
  });

  testWidgets('store: members link', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(KuriScreen(record: riverside())));
    await settle(tester);
    await tester.tap(find.byTooltip('Members\' link'));
    await store(tester, 'link');
  });

  testWidgets('store: draw the rest', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(KuriScreen(record: riverside())));
    await settle(tester);
    await tester.tap(find.byTooltip('More'));
    await settle(tester);
    await tester.tap(find.text('Draw the rest'));
    await store(tester, 'draw-rest');
  });

  testWidgets('store: home', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(HomeScreen(preview: ([riverside(), family()], {'display': 'Rahul', 'name': 'Rahul', 'can_import_boystown': false}))));
    await store(tester, 'home');
  });

  testWidgets('store: slots', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(KuriEditorScreen(record: riverside())));
    await settle(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1320)); // past the money card, which now starts with the currency
    await store(tester, 'slots-a');
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await store(tester, 'slots-b');
  });

  test('store: bottle draw frames', () async {
    final k = riverside().doc;
    final order = [for (final s in k.waitingSlots()) DrawEntry(s, k.slotName(s))];
    final pick = order.indexWhere((e) => e.slot == 3);
    final scene = BottleScene(
      order: order, pickIndex: pick < 0 ? 0 : pick, seed: 7, kicker: k.fullName.toUpperCase(), title: 'Month 5 draw',
      subtitle: '${k.monthLabel(5)}, pot ₹1,20,000', when: DateTime.now(),
    )..subtitlePot = '₹1,20,000';
    final p = scene.plan;
    final times = <String, double>{
      'draw-writing': p.writeAt[2] + p.writeD * 0.3,
      'draw-shaking': p.shake + p.shakeD * 0.42,
      'draw-result': p.reveal + 1800,
    };
    Directory('test_screens/shots').createSync(recursive: true);
    for (final e in times.entries) {
      scene.advanceTo(e.value);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      scene.paint(c, e.value);
      final img = await rec.endRecording().toImage(1080, 1920);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('test_screens/shots/store-${e.key}.png').writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
