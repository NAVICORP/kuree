// The footer stays below a chit opened from a tab, like the tab bar on an
// iPhone: each tab keeps its own open screens, the tab on show tapped again
// goes back to its list, the back button and the back swipe close the open
// screen first, and sheets still cover the whole app, footer included.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/api.dart';
import 'package:kuree/l10n/strings.dart';
import 'package:kuree/ui/collect_screen.dart';
import 'package:kuree/ui/history_screen.dart';
import 'package:kuree/ui/home.dart';
import 'package:kuree/ui/kuri_editor.dart';
import 'package:kuree/ui/kuri_screen.dart';
import 'package:kuree/ui/theme.dart';
import 'package:kuree/ui/widgets.dart';

import 'support.dart';

Widget app(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kureeTheme(),
      locale: const Locale('en'),
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

  final s = S.forCode('en');

  /// An iPhone sized screen with a home bar inset at the bottom.
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
  }

  double screenHeight(WidgetTester tester) => tester.view.physicalSize.height / tester.view.devicePixelRatio;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Finder footerItem(String label) => find.descendant(of: find.byType(KNavBar), matching: find.text(label));

  int footerIndex(WidgetTester tester) => tester.widget<KNavBar>(find.byType(KNavBar)).index;

  Future<void> start(WidgetTester tester) async {
    phone(tester);
    await tester.pumpWidget(app(HomeScreen(preview: ([demoChit()], {'display': 'Ishaque', 'name': 'Ishaque'}))));
    await settle(tester);
  }

  Future<void> openChit(WidgetTester tester) async {
    await start(tester);
    await tester.tap(find.text('5K Chit'));
    await settle(tester);
    expect(find.byType(KuriScreen), findsOneWidget);
  }

  /// The phone's back button, as Android sends it.
  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMessageCodec().encodeMessage(<String, dynamic>{'method': 'popRoute'}),
      (_) {},
    );
  }

  void expectFooterBelowChit(WidgetTester tester) {
    expect(footerItem(s.tabChits).hitTestable(), findsOneWidget);
    expect(footerItem(s.tabCollect).hitTestable(), findsOneWidget);
    expect(footerItem(s.tabProfile).hitTestable(), findsOneWidget);
    final chit = tester.getRect(find.byType(KuriScreen));
    final footer = tester.getRect(find.byType(KNavBar));
    expect(chit.bottom, moreOrLessEquals(footer.top));
    expect(footer.bottom, moreOrLessEquals(screenHeight(tester)));
  }

  testWidgets('a chit opened from Chits keeps the footer below it', (tester) async {
    await openChit(tester);
    expectFooterBelowChit(tester);
    expect(footerIndex(tester), 0);
    expect(find.byType(KuriCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping Chits while a chit is open goes back to the list', (tester) async {
    await openChit(tester);
    await tester.tap(footerItem(s.tabChits));
    await settle(tester);
    expect(find.byType(KuriScreen), findsNothing);
    expect(find.byType(KuriCard), findsOneWidget);
    expect(footerIndex(tester), 0);
  });

  testWidgets('To collect and back again keeps the chit open', (tester) async {
    await openChit(tester);
    await tester.tap(footerItem(s.tabCollect));
    await settle(tester);
    expect(footerIndex(tester), 1);
    expect(find.byType(KuriScreen), findsNothing);
    expect(find.byType(CollectList), findsOneWidget);
    await tester.tap(footerItem(s.tabChits));
    await settle(tester);
    expect(footerIndex(tester), 0);
    expect(find.byType(KuriScreen), findsOneWidget);
    expect(find.byType(KuriCard), findsNothing);
    expectFooterBelowChit(tester);
  });

  testWidgets('the back button closes the chit and the footer stays', (tester) async {
    await openChit(tester);
    await systemBack(tester);
    await settle(tester);
    expect(find.byType(KuriScreen), findsNothing);
    expect(find.byType(KuriCard), findsOneWidget);
    expect(footerItem(s.tabChits).hitTestable(), findsOneWidget);
  });

  testWidgets('the arrow at the top closes the chit too', (tester) async {
    await openChit(tester);
    await tester.pageBack();
    await settle(tester);
    expect(find.byType(KuriScreen), findsNothing);
    expect(find.byType(KuriCard), findsOneWidget);
  });

  testWidgets('iPhone: the back swipe closes the chit and the footer stays', (tester) async {
    await openChit(tester);
    await tester.dragFrom(const Offset(4, 420), const Offset(380, 0));
    await settle(tester);
    expect(find.byType(KuriScreen), findsNothing);
    expect(find.byType(KuriCard), findsOneWidget);
    expect(footerItem(s.tabChits).hitTestable(), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a sheet covers the footer, and a screen picked from it opens in the tab', (tester) async {
    await openChit(tester);
    await tester.tap(find.byTooltip(s.more));
    await settle(tester);
    final sheet = tester.getRect(find.byType(BottomSheet));
    final footer = tester.getRect(find.byType(KNavBar));
    expect(sheet.bottom, moreOrLessEquals(footer.bottom));
    expect(footerItem(s.tabCollect).hitTestable(), findsNothing);
    // History, picked in the sheet: the sheet closes and History opens
    // inside the Chits tab, over the chit, with the footer still below.
    await tester.tap(find.text(s.history));
    await settle(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(footerItem(s.tabChits).hitTestable(), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    expect(find.byType(HistoryScreen), findsNothing);
    expectFooterBelowChit(tester);
  });

  testWidgets('unsaved changes ask first when Chits is tapped', (tester) async {
    await openChit(tester);
    final naif = find.bySemanticsLabel(s.semPaid('Naif'));
    await tester.ensureVisible(naif);
    await tester.pump();
    await tester.tap(naif, warnIfMissed: false);
    await settle(tester);
    expect(find.text(s.notSavedYet), findsOneWidget);
    // The Save bar sits above the footer.
    expect(tester.getRect(find.text(s.notSavedYet)).bottom, lessThanOrEqualTo(tester.getRect(find.byType(KNavBar)).top));
    await tester.tap(footerItem(s.tabChits));
    await settle(tester);
    expect(find.text(s.leaveTitle), findsOneWidget);
    expect(find.byType(KuriScreen), findsOneWidget);
    await tester.tap(find.text(s.leave));
    await settle(tester);
    expect(find.byType(KuriScreen), findsNothing);
    expect(find.byType(KuriCard), findsOneWidget);
  });

  testWidgets('a chit opened from To collect stays in that tab', (tester) async {
    await start(tester);
    await tester.tap(footerItem(s.tabCollect));
    await settle(tester);
    await tester.tap(find.text(s.open).first);
    await settle(tester);
    expect(find.byType(KuriScreen), findsOneWidget);
    expect(footerIndex(tester), 1);
    expectFooterBelowChit(tester);
    // Chits shows its own list, not the chit opened in To collect.
    await tester.tap(footerItem(s.tabChits));
    await settle(tester);
    expect(find.byType(KuriScreen), findsNothing);
    expect(find.byType(KuriCard), findsOneWidget);
    // To collect again: the chit, then its list.
    await tester.tap(footerItem(s.tabCollect));
    await settle(tester);
    expect(find.byType(KuriScreen), findsOneWidget);
    await tester.tap(footerItem(s.tabCollect));
    await settle(tester);
    expect(find.byType(KuriScreen), findsNothing);
    expect(find.byType(CollectList), findsOneWidget);
  });

  testWidgets('a new chit: Save above the footer, and the form ends at the keyboard', (tester) async {
    await start(tester);
    await tester.tap(find.text(s.newChit));
    await settle(tester);
    expect(find.byType(KuriEditorScreen), findsOneWidget);
    final footer = tester.getRect(find.byType(KNavBar));
    expect(tester.getRect(find.text(s.startTheChit)).bottom, lessThanOrEqualTo(footer.top));
    expect(footer.bottom, moreOrLessEquals(screenHeight(tester)));
    // The keyboard comes up over the footer (the phone drops the home bar
    // inset while it is up). The form stops right at its top edge.
    const keyboard = 336.0;
    tester.view.padding = const FakeViewPadding(top: 47 * 3);
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard * 3);
    await tester.pump();
    await tester.pump();
    final form = tester.getRect(find.descendant(of: find.byType(KuriEditorScreen), matching: find.byType(ListView)).first);
    expect(form.bottom, moreOrLessEquals(screenHeight(tester) - keyboard));
    expect(tester.getRect(find.byType(KNavBar)).bottom, moreOrLessEquals(screenHeight(tester)));
    expect(tester.takeException(), isNull);
  });
}
