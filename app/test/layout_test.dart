// The main screens at 360 dp wide (a small Android phone) in Malayalam and
// Arabic, the two languages that run longest and right to left. A Row that
// spills out of its card fails the test.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/api.dart';
import 'package:kuree/draw/bottle_draw_screen.dart';
import 'package:kuree/l10n/strings.dart';
import 'package:kuree/ui/account.dart';
import 'package:kuree/ui/home.dart';
import 'package:kuree/ui/kuri_editor.dart';
import 'package:kuree/ui/kuri_screen.dart';
import 'package:kuree/ui/sign_in.dart';
import 'package:kuree/ui/theme.dart';

import 'support.dart';

Widget app(Widget home, String code) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kureeTheme(),
      locale: Locale(code),
      supportedLocales: [for (final c in S.codes) Locale(c)],
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

void main() {
  setUpAll(loadAppFonts);
  setUp(() => Api.instance.offline = true);
  tearDown(() {
    Api.instance.offline = false;
    S.current = S.forCode('en');
  });

  void small(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// Scrolls the first list to its end, a step at a time, so every row is
  /// built and laid out.
  Future<void> scrollThrough(WidgetTester tester) async {
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 10; i++) {
      await tester.drag(list, const Offset(0, -350), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text).first;
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f, warnIfMissed: false);
    await settle(tester);
  }

  for (final code in ['ml', 'ar']) {
    final s = S.forCode(code);
    final chit = demoChit(currency: code == 'ar' ? 'AED' : 'INR');

    group('$code at 360 dp', () {
      testWidgets('sign in', (tester) async {
        small(tester);
        await tester.pumpWidget(app(const SignInScreen(), code));
        await settle(tester);
        expect(tester.takeException(), isNull);
        if (code == 'ar') expect(Directionality.of(tester.element(find.byType(SignInScreen))), TextDirection.rtl);
        await tapText(tester, s.continueWa);
        expect(tester.takeException(), isNull);
      });

      testWidgets('home', (tester) async {
        small(tester);
        await tester.pumpWidget(app(HomeScreen(preview: ([chit, demoChit(currency: 'USD')], {'display': 'Ishaque', 'name': 'Ishaque'})), code));
        await settle(tester);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a month, its members and reminders', (tester) async {
        small(tester);
        await tester.pumpWidget(app(KuriScreen(record: chit), code));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.bySemanticsLabel(s.semPaid('Naif')));
        await tester.pump();
        await tester.tap(find.bySemanticsLabel(s.semPaid('Naif')), warnIfMissed: false);
        await settle(tester);
        expect(tester.takeException(), isNull);
        // The Reminders button sits near the top; after scrolling down the
        // list no longer builds it, so scroll back up to it first.
        await tester.scrollUntilVisible(find.text(s.reminders), -300, scrollable: find.byType(Scrollable).first);
        await tapText(tester, s.reminders);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the menu and draw the rest', (tester) async {
        small(tester);
        await tester.pumpWidget(app(KuriScreen(record: chit), code));
        await settle(tester);
        await tester.tap(find.byTooltip(s.more));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tapText(tester, s.drawRest);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the members link', (tester) async {
        small(tester);
        await tester.pumpWidget(app(KuriScreen(record: chit), code));
        await settle(tester);
        await tester.tap(find.byTooltip(s.membersLink));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a new chit', (tester) async {
        small(tester);
        await tester.pumpWidget(app(const KuriEditorScreen(), code));
        await settle(tester);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('editing a chit', (tester) async {
        small(tester);
        await tester.pumpWidget(app(KuriEditorScreen(record: chit), code));
        await settle(tester);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('account', (tester) async {
        small(tester);
        await tester.pumpWidget(app(const AccountScreen(me: {'name': 'Anees Muhammed', 'display': 'Anees Muhammed', 'phone': '919072150276', 'email': 'anees@example.com'}), code));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the bottle draw', (tester) async {
        small(tester);
        final k = chit.doc;
        await tester.pumpWidget(app(
          BottleDrawScreen(
            title: k.fullName,
            month: 5,
            label: k.monthLabel(5),
            pot: k.pot,
            currency: k.currency,
            entries: [for (final x in k.waitingSlots()) DrawEntry(x, k.slotName(x))],
            resultText: (a, b, c) => '',
            onSave: (a, b) async => true,
            by: 'Ishaque',
          ),
          code,
        ));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
