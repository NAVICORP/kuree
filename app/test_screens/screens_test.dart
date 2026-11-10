// Renders every main screen to a picture, so the design can be checked
// without a phone. Run with: flutter test test_screens --update-goldens
// The pictures land in test_screens/shots/.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/api.dart';
import 'package:kuree/core/kuri.dart';
import 'package:kuree/draw/bottle_draw_screen.dart';
import 'package:kuree/draw/scene.dart';
import 'package:kuree/l10n/strings.dart';
import 'package:kuree/ui/account.dart';
import 'package:kuree/ui/code_boxes.dart';
import 'package:kuree/ui/connect_email.dart';
import 'package:kuree/ui/home.dart';
import 'package:kuree/ui/kuri_editor.dart';
import 'package:kuree/ui/language.dart';
import 'package:kuree/ui/kuri_screen.dart';
import 'package:kuree/ui/launch.dart';
import 'package:kuree/ui/sign_in.dart';
import 'package:kuree/ui/theme.dart';

import '../test/support.dart' show multiChit, multiChitJson;

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

KuriRecord boystown() {
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
  // Month 5 is always "this month" in the pictures.
  final start = DateTime(now.year, now.month - 4, 1);
  return KuriRecord.fromJson({
    'id': '00000000-0000-0000-0000-000000000001',
    'role': 'owner',
    'share_token': 'abcdefghijklmnopqrstuvwx',
    'updated_at': now.subtract(const Duration(minutes: 7)).toUtc().toIso8601String(),
    'updated_by': 'Anees Muhammed',
    'data': {
      'name': '5K Chit', 'group': 'Riverside', 'share': 5000, 'slots': 13, 'startYear': start.year, 'startMonth': start.month,
      'collectDay': 20, 'lastDay': 25, 'fine': 200, 'people': people, 'payers': payers,
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

KuriRecord small() => KuriRecord.fromJson({
      'id': '00000000-0000-0000-0000-000000000002',
      'role': 'admin',
      'share_token': 'zyxwvutsrqponmlkjihgfedc',
      'data': {
        'name': 'Family Chit', 'group': '', 'share': 2000, 'slots': 6, 'startYear': DateTime.now().year, 'startMonth': DateTime.now().month,
        'collectDay': 5, 'lastDay': 10, 'fine': 0,
        'people': [for (var i = 1; i <= 6; i++) {'id': 'm$i', 'name': ['Umma', 'Shameer', 'Riyas', 'Faseela', 'Jasna', 'Nabeel'][i - 1]}],
        'payers': [for (var i = 1; i <= 6; i++) {'id': 'p$i', 'slot': i, 'person': 'm$i', 'amt': 2000}],
        'months': [{'n': 1, 'paid': {'p1': true, 'p2': true}}],
      },
    });

Widget phone(Widget child, [String? code]) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kureeTheme(),
      locale: code == null ? null : Locale(code),
      supportedLocales: code == null ? const [Locale('en', 'US')] : [for (final c in S.codes) Locale(c)],
      localizationsDelegates: code == null
          ? null
          : const [S.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: child,
    );

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

Future<void> shot(WidgetTester tester, String name) async {
  await settle(tester);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
}

/// A screen as the app shows it: opened from the Chits tab, with the footer
/// below it and Chits chosen.
Future<void> pumpInTab(WidgetTester tester, Widget screen, [String? code]) async {
  await tester.pumpWidget(phone(HomeScreen(preview: ([boystown(), small()], {'display': 'Ishaque', 'name': 'Ishaque', 'can_import_boystown': false})), code));
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
  });
  tearDown(() => S.current = S.forCode('en'));

  void sized(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  // The loading screen, caught mid-motion: no settle() here, which would run
  // the intro to its end.
  Future<void> still(WidgetTester tester, String name) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));

  testWidgets('loading', (tester) async {
    sized(tester);
    await tester.runAsync(LaunchScreen.prepare);
    final never = Completer<void>();
    await tester.pumpWidget(phone(LaunchScreen(work: () => never.future, child: const SizedBox())));
    // The card lifting, the light crossing it, the ring taking shape.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await still(tester, '00-loading');
    // A finger dragging up and to the right: the card tilts towards it.
    await tester.pump(const Duration(milliseconds: 500));
    final g = await tester.startGesture(const Offset(195, 422));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(18, -22));
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pump(const Duration(milliseconds: 200));
    await still(tester, '00b-loading-tilt');
    await g.up();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 400));
    // "Still loading" came at 2.5 s; let it fade in.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 200));
    await still(tester, '00c-loading-still');
  });

  for (final code in ['en', 'ar']) {
    testWidgets('$code: loading offline', (tester) async {
      sized(tester);
      await tester.runAsync(LaunchScreen.prepare);
      final words = S.forCode(code);
      await tester.pumpWidget(phone(
        LaunchScreen(work: () async => throw ApiError(words.errNoConnection), child: const SizedBox()),
        code == 'en' ? null : code,
      ));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 500));
      await still(tester, code == 'en' ? '00d-loading-offline' : '$code-00d-loading-offline');
    });
  }

  testWidgets('sign in', (tester) async {
    sized(tester);
    // On iPhone: Apple, Google and email.
    await tester.pumpWidget(phone(const SignInScreen(apple: true, google: true)));
    await shot(tester, '01-sign-in');
    await tester.tap(find.text('Continue with email'));
    await shot(tester, '02-sign-in-email');
    await tester.tap(find.text('Use a password'));
    await shot(tester, '02-sign-in-password');
  });

  testWidgets('add your email (WhatsApp sign-in ended)', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(const ConnectEmailScreen()));
    await shot(tester, '04-add-email');
    await tester.pumpWidget(phone(const ConnectEmailScreen(key: ValueKey('code'), startWithCode: 'ibrahim@example.com')));
    await shot(tester, '04b-add-email-code');
  });

  testWidgets('sign in, language picker', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(const SignInScreen(apple: true, google: true)));
    await settle(tester);
    await tester.tap(find.byType(LanguageChip));
    await shot(tester, '03-language');
  });

  testWidgets('sign in, code boxes', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CodeBoxes(controller: TextEditingController(text: '482'), autofocus: false),
            const SizedBox(height: 24),
            CodeBoxes(controller: TextEditingController(text: '482019'), autofocus: false),
          ]),
        ),
      ),
    )));
    await shot(tester, '02-sign-in-code');
  });

  testWidgets('sign in on Android', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(const SignInScreen(google: true)));
    await shot(tester, '01-sign-in-android');
  });

  testWidgets('home', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(HomeScreen(preview: ([boystown(), small()], {'display': 'Ishaque', 'name': 'Ishaque'}))));
    await shot(tester, '03-home');
    await tester.tap(find.text('To collect').first);
    await shot(tester, '03b-to-collect');
    await tester.tap(find.text('Profile').first);
    await shot(tester, '03c-profile');
  });

  testWidgets('a month', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: boystown()));
    await shot(tester, '04-month');
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await shot(tester, '05-month-members');
    await tester.tap(find.bySemanticsLabel('Paid: Naif'));
    await shot(tester, '06-month-not-saved');
    await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Reminders'));
    await shot(tester, '07-reminders');
  });

  testWidgets('menu', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: boystown()));
    await settle(tester);
    await tester.tap(find.byTooltip('More'));
    await shot(tester, '08-menu');
  });

  testWidgets('members link', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: boystown()));
    await settle(tester);
    await tester.tap(find.byTooltip('Members\' link'));
    await shot(tester, '09-link');
  });

  testWidgets('draw the rest', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: boystown()));
    await settle(tester);
    await tester.tap(find.byTooltip('More'));
    await settle(tester);
    await tester.tap(find.text('Draw the rest'));
    await shot(tester, '09b-draw-the-rest');
  });

  testWidgets('choose who takes the pot', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: boystown()));
    await settle(tester);
    await tester.tap(find.text('Choose'));
    await shot(tester, '09c-choose');
  });

  testWidgets('new chit', (tester) async {
    sized(tester);
    await pumpInTab(tester, const KuriEditorScreen());
    await shot(tester, '10-new-chit');
  });

  testWidgets('new chit, names one at a time', (tester) async {
    sized(tester);
    await pumpInTab(tester, const KuriEditorScreen());
    await settle(tester);
    final list = find.byType(Scrollable).first;
    for (final (i, n) in [(1, 'Nazil'), (2, 'Ramshad Ac'), (3, 'Anees Muhammed')]) {
      await tester.scrollUntilVisible(find.byKey(ValueKey('slot-$i-1')), 200, scrollable: list);
      await tester.enterText(find.byKey(ValueKey('slot-$i-1')), n);
      await tester.pump();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('slot-4-1')), 200, scrollable: list);
    await tester.drag(list, const Offset(0, -120));
    await shot(tester, '10b-new-chit-names');
  });

  testWidgets('first month calendar', (tester) async {
    sized(tester);
    await pumpInTab(tester, const KuriEditorScreen());
    await settle(tester);
    await tester.scrollUntilVisible(find.text('First month'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(); // lay out the scroll first, so the tap lands on the row and not on Start the chit
    await tester.tap(find.text('First month'));
    await shot(tester, '10c-first-month');
  });

  testWidgets('collection day calendar', (tester) async {
    sized(tester);
    await pumpInTab(tester, const KuriEditorScreen());
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Collection day'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(); // lay out the scroll first, so the tap lands on the row and not on Start the chit
    await tester.tap(find.text('Collection day'));
    await shot(tester, '10d-collection-day');
  });

  testWidgets('late fine', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: boystown()));
    await settle(tester);
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Late fine ₹200'), 200, scrollable: list);
    await shot(tester, '09d-fine-button');
    await tester.tap(find.text('Late fine ₹200'));
    await shot(tester, '09e-fine-sheet');
  });

  testWidgets('edit chit', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriEditorScreen(record: boystown()));
    await settle(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1170));
    await shot(tester, '11-edit-slots');
    await tester.drag(find.byType(ListView).first, const Offset(0, -1300));
    await shot(tester, '12-edit-numbers');
  });

  testWidgets('account', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(const AccountScreen(me: {'name': 'Ishaque', 'display': 'Ishaque', 'phone': '919072150276', 'email': 'ishaque@skifi.co'})));
    await shot(tester, '13-account');
  });

  testWidgets('bottle draw, ready', (tester) async {
    sized(tester);
    final k = boystown().doc;
    await tester.pumpWidget(phone(BottleDrawScreen(
      title: k.fullName,
      month: 5,
      label: k.monthLabel(5),
      pot: k.pot,
      entries: [for (final s in k.waitingSlots()) DrawEntry(s, k.slotName(s))],
      resultText: (a, b, c) => '',
      onSave: (a, b) async => true,
      by: 'Ishaque',
    )));
    await shot(tester, '14-draw-ready');
  });

  // The main screens in Malayalam and Arabic, for checking the words fit.
  for (final code in ['ml', 'ar']) {
    final s = S.forCode(code);
    KuriRecord chit() {
      final r = boystown();
      if (code == 'ar') r.doc.currency = 'AED';
      return r;
    }

    testWidgets('$code: sign in', (tester) async {
      sized(tester);
      await tester.pumpWidget(phone(const SignInScreen(apple: true, google: true), code));
      await shot(tester, '$code-01-sign-in');
      await tester.tap(find.text(s.continueEmail));
      await shot(tester, '$code-02-sign-in-email');
    });

    testWidgets('$code: home', (tester) async {
      sized(tester);
      await tester.pumpWidget(phone(HomeScreen(preview: ([chit(), small()], {'display': 'Ishaque', 'name': 'Ishaque'})), code));
      await shot(tester, '$code-03-home');
    });

    testWidgets('$code: a month', (tester) async {
      sized(tester);
      await pumpInTab(tester, KuriScreen(record: chit()), code);
      await shot(tester, '$code-04-month');
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await shot(tester, '$code-05-month-members');
      await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(s.reminders));
      await shot(tester, '$code-07-reminders');
    });

    testWidgets('$code: menu', (tester) async {
      sized(tester);
      await pumpInTab(tester, KuriScreen(record: chit()), code);
      await settle(tester);
      await tester.tap(find.byTooltip(s.more));
      await shot(tester, '$code-08-menu');
    });

    testWidgets('$code: new chit', (tester) async {
      sized(tester);
      await pumpInTab(tester, const KuriEditorScreen(), code);
      await shot(tester, '$code-10-new-chit');
    });

    testWidgets('$code: account', (tester) async {
      sized(tester);
      await tester.pumpWidget(phone(const AccountScreen(me: {'name': 'Ishaque', 'display': 'Ishaque', 'phone': '919072150276'}), code));
      await shot(tester, '$code-13-account');
    });
  }

  // More slots than months: 20 slots over 10 months, two take the pot each
  // month; and 25 over 10, two in months 1 to 5, then three.
  for (final code in ['en', 'ar']) {
    final s = S.forCode(code);
    final pre = code == 'en' ? '' : '$code-';
    String? lang() => code == 'en' ? null : code;

    testWidgets('$code: several takers, a month', (tester) async {
      sized(tester);
      await pumpInTab(tester, KuriScreen(record: multiChit(currency: code == 'ar' ? 'AED' : 'INR')), lang());
      await shot(tester, '${pre}30-multi-month');
      await tester.tap(find.byTooltip(s.prevMonth));
      await shot(tester, '${pre}31-multi-month-taken');
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await shot(tester, '${pre}32-multi-members');
    });

    testWidgets('$code: several takers, length in the editor', (tester) async {
      sized(tester);
      await pumpInTab(tester, KuriEditorScreen(record: multiChit(slots: 25)), lang());
      await settle(tester);
      await tester.scrollUntilVisible(find.text(s.chitLength), 200, scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 160));
      await shot(tester, '${pre}35-multi-length-25');
      await tester.scrollUntilVisible(find.text(s.chitLength), 200, scrollable: find.byType(Scrollable).first);
      await tester.pump();
      await tester.tap(find.text(s.chitLength));
      await shot(tester, '${pre}36-multi-length-picker');
    });
  }

  testWidgets('several takers, choose by hand', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: multiChit()));
    await settle(tester);
    await tester.tap(find.text('Choose'));
    await settle(tester);
    await tester.tap(find.text('Ramshad Ac').last);
    await shot(tester, '33-multi-choose');
  });

  testWidgets('several takers, draw the rest', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: multiChit(slots: 25)));
    await settle(tester);
    await tester.tap(find.byTooltip('More'));
    await settle(tester);
    await tester.tap(find.text('Draw the rest'));
    await shot(tester, '34-multi-draw-rest');
  });

  // The organiser takes month 1 and pays nothing: 25 slots over 21 months,
  // one taker a month, two in the last five, every taker the same amount.
  KuriRecord organiserChit() {
    final j = Map<String, dynamic>.from(multiChitJson(slots: 25, length: 21));
    final d = Map<String, dynamic>.from(j['data'] as Map);
    final all = (d['months'] as List).first['paid'];
    d['organiser'] = true;
    d['months'] = [
      {'n': 1, 'paid': all},
      {'n': 2, 'winner': 4, 'paid': all},
    ];
    j['data'] = d;
    return KuriRecord.fromJson(j);
  }

  testWidgets('organiser month', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriScreen(record: organiserChit()));
    await settle(tester);
    await tester.tap(find.byTooltip(S.forCode('en').prevMonth));
    await shot(tester, '40-organiser-taker');
    await tester.tap(find.byTooltip(S.forCode('en').prevMonth));
    await shot(tester, '41-organiser-month');
  });

  testWidgets('organiser month, editor', (tester) async {
    sized(tester);
    await pumpInTab(tester, KuriEditorScreen(record: organiserChit()));
    await settle(tester);
    await tester.scrollUntilVisible(find.text(S.forCode('en').organiserMonth), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 260));
    await shot(tester, '42-organiser-editor');
  });

  testWidgets('several takers, home', (tester) async {
    sized(tester);
    await tester.pumpWidget(phone(HomeScreen(preview: ([multiChit(), boystown()], {'display': 'Ishaque', 'name': 'Ishaque'}))));
    await shot(tester, '39-multi-home');
  });

  testWidgets('several takers, bottle draw ready', (tester) async {
    sized(tester);
    final k = multiChit().doc;
    await tester.pumpWidget(phone(BottleDrawScreen(
      title: k.fullName,
      month: 3,
      label: k.monthLabel(3),
      pot: k.pot,
      each: k.payoutOf(k.months[2], 0),
      count: 2,
      entries: [for (final s in k.waitingSlots()) DrawEntry(s, k.slotName(s))],
      resultText: (a, b, c) => '',
      onSave: (a, b) async => true,
      by: 'Ishaque',
    )));
    await shot(tester, '37-multi-draw-ready');
  });

  test('several takers, bottle draw frames', () async {
    final k = multiChit().doc;
    final order = [for (final s in k.waitingSlots()) DrawEntry(s, k.slotName(s))];
    final scene = BottleScene(
      order: order, pickIndex: 3, seed: 7, kicker: k.fullName.toUpperCase(), title: 'Month 3 draw',
      subtitle: '${k.monthLabel(3)}, pot ₹1,00,000', when: DateTime(2026, 11, 20, 19, 31),
    )
      ..subtitlePot = '₹50,000'
      ..round = 'Pick 2 of 2';
    final p = scene.plan;
    Directory('test_screens/shots').createSync(recursive: true);
    for (final e in {'38-multi-draw-writing': p.writeAt[2] + p.writeD * 0.3, '38b-multi-draw-result': p.reveal + 1600}.entries) {
      scene.advanceTo(e.value);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.scale(0.5);
      scene.paint(c, e.value);
      final img = await rec.endRecording().toImage(540, 960);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('test_screens/shots/${e.key}.png').writeAsBytesSync(png!.buffer.asUint8List());
    }
  });

  test('bottle draw frames', () async {
    final k = boystown().doc;
    final order = [for (final s in k.waitingSlots()) DrawEntry(s, k.slotName(s))];
    final scene = BottleScene(
      order: order, pickIndex: 4, seed: 99, kicker: k.fullName.toUpperCase(), title: 'Month 5 draw',
      subtitle: '${k.monthLabel(5)}, pot ₹65,000', when: DateTime(2026, 10, 20, 19, 31),
    )..subtitlePot = '₹65,000';
    final p = scene.plan;
    final times = <String, double>{
      '15-draw-countdown': -2400,
      '16-draw-writing': p.writeAt[1] + p.writeD * 0.3,
      '17-draw-into-bottle': p.writeAt.last + p.writeD * 0.8,
      '18-draw-shaking': p.shake + p.shakeD * 0.4,
      '19-draw-picking': p.pick + p.pickD * 0.7,
      '20-draw-result': p.reveal + 1600,
    };
    Directory('test_screens/shots').createSync(recursive: true);
    for (final e in times.entries) {
      scene.advanceTo(e.value);
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.scale(0.5);
      scene.paint(c, e.value);
      final img = await rec.endRecording().toImage(540, 960);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('test_screens/shots/${e.key}.png').writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
