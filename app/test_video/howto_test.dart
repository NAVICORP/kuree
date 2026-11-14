// The Malayalam how-to video's pictures: the real app screens, driven step
// by step with a made-up chit. Run with:
//   flutter test test_video --update-goldens
// The pictures land in test_video/shots/, with taps.json naming where each
// picture's next tap lands (in picture pixels).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/api.dart';
import 'package:kuree/core/format.dart';
import 'package:kuree/core/kuri.dart';
import 'package:kuree/draw/bottle_draw_screen.dart';
import 'package:kuree/draw/scene.dart';
import 'package:kuree/l10n/strings.dart';
import 'package:kuree/ui/home.dart';
import 'package:kuree/ui/kuri_editor.dart';
import 'package:kuree/ui/kuri_screen.dart';
import 'package:kuree/ui/language.dart';
import 'package:kuree/ui/sign_in.dart';
import 'package:kuree/ui/theme.dart';

const code = 'en';
final s = S.forCode(code);
final taps = <String, List<double>>{};

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
  for (final f in ['Manjari', 'NotoNaskhArabic', 'NotoSansTamil', 'NotoSansKannada', 'NotoSansDevanagari']) {
    await family(f, ['assets/fonts/$f-500.ttf', 'assets/fonts/$f-700.ttf']);
  }
  final roots = <String>[
    if (Platform.environment['FLUTTER_ROOT'] != null) Platform.environment['FLUTTER_ROOT']!,
    File(Platform.resolvedExecutable).parent.path,
  ];
  for (final r in roots) {
    var dir = Directory(r);
    for (var i = 0; i < 8; i++) {
      for (final x in [
        File('${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'),
        File('${dir.path}/artifacts/material_fonts/MaterialIcons-Regular.otf'),
      ]) {
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

const names = [
  'Rasheed', 'Suresh', 'Fathima', 'Joseph', 'Anitha', 'Muneer', 'Shibu', 'Lakshmi', 'Faisal', 'Reena',
  'Ajmal', 'Deepa', 'Noushad', 'Bindu', 'Sajeev', 'Haris', 'Remya', 'Jabir', 'Vinod', 'Sameera',
];

/// 20 slots of 2,000 over 8 months, two or three takers a month, the
/// organiser taking month 5. Month 2 is this month.
KuriRecord chit({List<int> m2winners = const [], bool m2allPaid = false}) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - 1, 1);
  final people = [for (var i = 0; i < names.length; i++) {'id': 'm${i + 1}', 'name': names[i], 'phone': '9190000000${i.toString().padLeft(2, '0')}'}];
  final payers = [for (var i = 1; i <= 20; i++) {'id': 'p$i', 'slot': i, 'person': 'm$i', 'amt': 2000}];
  final all = {for (var i = 1; i <= 20; i++) 'p$i': true};
  final some = {for (var i = 1; i <= 14; i++) 'p$i': true};
  return KuriRecord.fromJson({
    'id': '00000000-0000-0000-0000-0000000000a1',
    'role': 'owner',
    'share_token': 'abcdefghijklmnopqrstuvwx',
    'updated_at': now.subtract(const Duration(minutes: 3)).toUtc().toIso8601String(),
    'updated_by': 'Rasheed',
    'data': {
      'name': 'Friends Chit', 'group': 'Kannur', 'share': 2000, 'slots': 20, 'length': 9,
      'organiser': true, 'organiserMonth': 5,
      'startYear': start.year, 'startMonth': start.month,
      'collectDay': 10, 'lastDay': 15, 'fine': 100, 'people': people, 'payers': payers,
      'months': [
        {'n': 1, 'winners': [3, 12], 'winner': 3, 'paid': all},
        {'n': 2, 'winners': m2winners, if (m2winners.isNotEmpty) 'winner': m2winners.first, 'paid': m2allPaid ? all : some},
      ],
    },
  });
}

KuriRecord family() => KuriRecord.fromJson({
      'id': '00000000-0000-0000-0000-0000000000a2',
      'role': 'admin',
      'share_token': 'zyxwvutsrqponmlkjihgfedc',
      'data': {
        'name': 'Family Chit', 'group': '', 'share': 1000, 'slots': 6, 'startYear': DateTime.now().year, 'startMonth': DateTime.now().month,
        'collectDay': 5, 'lastDay': 10, 'fine': 0,
        'people': [for (var i = 1; i <= 6; i++) {'id': 'm$i', 'name': ['Umma', 'Shameer', 'Riyas', 'Faseela', 'Jasna', 'Nabeel'][i - 1]}],
        'payers': [for (var i = 1; i <= 6; i++) {'id': 'p$i', 'slot': i, 'person': 'm$i', 'amt': 1000}],
        'months': [{'n': 1, 'paid': {'p1': true, 'p2': true, 'p3': true}}],
      },
    });

const me = {'display': 'Rasheed', 'name': 'Rasheed'};

Widget phone(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kureeTheme(),
      locale: const Locale(code),
      supportedLocales: [for (final c in S.codes) Locale(c)],
      localizationsDelegates: const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: child,
    );

Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> shot(WidgetTester tester, String name) async {
  await settle(tester);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
}

/// Remembers where the finger lands on picture [name], then taps there.
Future<void> tapOn(WidgetTester tester, Finder f, String name) async {
  final c = tester.getCenter(f);
  taps[name] = [c.dx * 3, c.dy * 3];
  await tester.tap(f);
}

Future<void> pumpInTab(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(phone(HomeScreen(preview: ([chit(), family()], me))));
  await tester.pump();
  final chits = find.descendant(of: find.byType(HomeScreen), matching: find.byType(Navigator)).first;
  tester.state<NavigatorState>(chits).push(MaterialPageRoute<void>(builder: (_) => screen));
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadFonts();
    Api.instance.offline = true;
    S.current = s;
  });
  tearDownAll(() {
    Directory('test_video/shots').createSync(recursive: true);
    File('test_video/shots/taps.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(taps));
  });

  // An iPhone 16: 393 x 852 points, the Dynamic Island and home bar
  // insets at the top and bottom.
  void sized(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 177, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 177, bottom: 102);
    addTearDown(tester.view.reset);
  }

  testWidgets('a sign in', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(const SignInScreen(apple: true, google: true)));
    await shot(tester, 'a1-sign-in');
    await tapOn(tester, find.byType(LanguageChip), 'a1-sign-in');
    await shot(tester, 'a2-language');
  });

  testWidgets('b home', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(HomeScreen(preview: ([family()], me))));
    await shot(tester, 'b1-home-one');
  });

  testWidgets('c new chit', (tester) async {
    sized(tester);
    await pumpInTab(tester, const KuriEditorScreen());
    await shot(tester, 'c1-new');
    final fields = find.byType(TextField);
    taps['c1-new'] = [tester.getCenter(fields.at(0)).dx * 3, tester.getCenter(fields.at(0)).dy * 3];
    await tester.enterText(fields.at(0), 'Friends Chit');
    await tester.enterText(fields.at(1), 'Kannur');
    FocusManager.instance.primaryFocus?.unfocus();
    await shot(tester, 'c2-named');
    final list = find.byType(Scrollable).first;
    for (var i = 1; i <= 20; i++) {
      await tester.scrollUntilVisible(find.byKey(ValueKey('slot-$i-1')), 200, scrollable: list);
      await tester.enterText(find.byKey(ValueKey('slot-$i-1')), names[i - 1]);
      await tester.pump();
      if (i == 4) {
        FocusManager.instance.primaryFocus?.unfocus();
        await shot(tester, 'c4-names-4');
      }
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.drag(list, const Offset(0, 200));
    await shot(tester, 'c5-names-20');
    // Money: each slot pays, and how many months.
    await tester.scrollUntilVisible(find.text(s.chitLength), 200, scrollable: list);
    await tester.drag(list, const Offset(0, 220));
    await tester.pump();
    final share = find.widgetWithText(TextField, '5000');
    await tester.enterText(share.evaluate().isEmpty ? find.byType(TextField).at(find.byType(TextField).evaluate().length - 2) : share, '2000');
    FocusManager.instance.primaryFocus?.unfocus();
    await shot(tester, 'c6-share');
    await tapOn(tester, find.text(s.chitLength), 'c6-share');
    await shot(tester, 'c7-length-picker');
    final eight = find.text(s.monthsCount(8)).last;
    await tester.scrollUntilVisible(eight, 120, scrollable: find.byType(Scrollable).last);
    await tester.pump();
    await shot(tester, 'c7b-length-picker-8');
    await tapOn(tester, eight, 'c7b-length-picker-8');
    await settle(tester);
    await shot(tester, 'c8-length-8');
    // Dates and the organiser's month.
    await tester.scrollUntilVisible(find.text(s.organiserMonth), 200, scrollable: list);
    await tester.drag(list, const Offset(0, 260));
    await tester.pump();
    await shot(tester, 'c9-dates');
    await tapOn(tester, find.byType(Switch).first, 'c9-dates');
    await shot(tester, 'c10-organiser-on');
    await tapOn(tester, find.text(s.organiserMonthPick), 'c10-organiser-on');
    await shot(tester, 'c11-organiser-picker');
    await tapOn(tester, find.text(s.monthN(5)).last, 'c11-organiser-picker');
    await settle(tester);
    await shot(tester, 'c12-organiser-5');
    await tester.scrollUntilVisible(find.text(s.startTheChit), 200, scrollable: list);
    await tester.pump();
    await shot(tester, 'c13-start');
    taps['c13-start'] = [tester.getCenter(find.text(s.startTheChit)).dx * 3, tester.getCenter(find.text(s.startTheChit)).dy * 3];
  });

  testWidgets('d home with the chit', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(HomeScreen(preview: ([chit(), family()], me))));
    await shot(tester, 'd1-home');
    await tapOn(tester, find.text('Friends Chit').first, 'd1-home');
  });

  testWidgets('e a month', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: chit()));
    await shot(tester, 'e1-month');
    await tester.scrollUntilVisible(find.text('Haris'), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pump();
    await shot(tester, 'e2-members');
    await tapOn(tester, find.bySemanticsLabel(s.semPaid('Sajeev')), 'e2-members');
    await shot(tester, 'e3-marked');
    await tapOn(tester, find.bySemanticsLabel(s.semPaid('Haris')), 'e3-marked');
    await shot(tester, 'e4-marked-2');
    final save = find.text(s.save);
    if (save.evaluate().isNotEmpty) taps['e4-marked-2'] = [tester.getCenter(save.first).dx * 3, tester.getCenter(save.first).dy * 3];
  });

  testWidgets('f reminders and link', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: chit()));
    await settle(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'f1-bottom');
    await tapOn(tester, find.text(s.reminders), 'f1-bottom');
    await shot(tester, 'f2-reminders');
  });

  testWidgets('g members link', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: chit()));
    await shot(tester, 'g0-month');
    await tapOn(tester, find.byTooltip(s.membersLink), 'g0-month');
    await shot(tester, 'g1-link');
  });

  testWidgets('h draw', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: chit(m2allPaid: true)));
    await shot(tester, 'h1-all-paid');
    final b = find.text(s.bottleDraw);
    if (b.evaluate().isNotEmpty) taps['h1-all-paid'] = [tester.getCenter(b.first).dx * 3, tester.getCenter(b.first).dy * 3];
    final k = chit(m2allPaid: true).doc;
    await tester.pumpWidget(phone(BottleDrawScreen(
      title: k.fullName,
      month: 2,
      label: k.monthLabel(2),
      pot: k.pot,
      each: k.payout,
      count: 2,
      entries: [for (final w in k.waitingSlots()) DrawEntry(w, k.slotName(w))],
      resultText: (a, b, c) => '',
      onSave: (a, b) async => true,
      by: 'Rasheed',
    )));
    await shot(tester, 'h2-draw-ready');
    taps['h2-draw-ready'] = [tester.getCenter(find.text(s.startDraw)).dx * 3, tester.getCenter(find.text(s.startDraw)).dy * 3];
  });

  testWidgets('i after the draw: an extra draw', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: chit(m2winners: [6, 17], m2allPaid: true)));
    await shot(tester, 'i1-winners');
    await tester.scrollUntilVisible(find.text(s.extraDraw), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pump();
    await shot(tester, 'i2-extra');
    taps['i2-extra'] = [tester.getCenter(find.text(s.extraDraw)).dx * 3, tester.getCenter(find.text(s.extraDraw)).dy * 3];
  });

  testWidgets('j organiser month and to collect', (tester) async {
    sized(tester);
    final r = chit(m2winners: [6, 17], m2allPaid: true);
    await pumpInTab(tester, KuriScreen(record: r));
    await settle(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip(s.nextMonth));
      await settle(tester);
    }
    await shot(tester, 'j1-organiser-month');
    await tester.pumpWidget(phone(HomeScreen(preview: ([chit(), family()], me))));
    await settle(tester);
    await tester.tap(find.text(s.tabCollect).first);
    await shot(tester, 'j2-to-collect');
  });

  test('k draw frames', timeout: const Timeout(Duration(minutes: 40)), () async {
    final k = chit(m2allPaid: true).doc;
    final order = [for (final w in k.waitingSlots()) DrawEntry(w, k.slotName(w))];
    final scene = BottleScene(
      order: order, pickIndex: 5, seed: 21, kicker: k.fullName.toUpperCase(), title: s.drawTitle(2),
      subtitle: s.drawSubtitle(k.monthLabel(2), money(k.pot, 'INR')), when: DateTime.now(),
    )
      ..subtitlePot = money(k.payout, 'INR')
      ..round = s.drawPickOf(1, 2);
    final p = scene.plan;
    final dir = Directory('test_video/shots/draw')..createSync(recursive: true);
    var i = 0;
    for (var t = -2400.0; t <= p.reveal + 2400; t += 1000 / 30) {
      scene.advanceTo(t);
      final rec = ui.PictureRecorder();
      scene.paint(Canvas(rec), t);
      final img = await rec.endRecording().toImage(1080, 1920);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/${(i++).toString().padLeft(4, '0')}.png').writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
