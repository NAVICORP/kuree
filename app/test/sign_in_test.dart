// The sign-in screen: Apple, Google and email, and the email and password
// path the store review account uses.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/api.dart';
import 'package:kuree/core/social.dart';
import 'package:kuree/l10n/strings.dart';
import 'package:kuree/ui/sign_in.dart';
import 'package:kuree/ui/theme.dart';

import 'support.dart';

Widget app(Widget home) => MaterialApp(debugShowCheckedModeBanner: false, theme: kureeTheme(), home: home);

void main() {
  setUpAll(loadAppFonts);
  setUp(() => Api.instance.offline = true);
  tearDown(() => Api.instance.offline = false);
  final s = S.forCode('en');

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  test('no Apple on Android, and no Google without the client ids', () {
    // Tests run as Android, with no --dart-define.
    expect(SocialSignIn.appleAvailable, isFalse);
    expect(SocialSignIn.googleAvailable, isFalse);
  });

  testWidgets('without Apple or Google only email shows', (tester) async {
    await tester.pumpWidget(app(const SignInScreen()));
    await settle(tester);
    expect(find.text(s.continueApple), findsNothing);
    expect(find.text(s.continueGoogle), findsNothing);
    expect(find.text(s.continueEmail), findsOneWidget);
    expect(find.textContaining('WhatsApp'), findsNothing);
  });

  testWidgets('Apple first, then Google, then email', (tester) async {
    await tester.pumpWidget(app(const SignInScreen(apple: true, google: true)));
    await settle(tester);
    final apple = tester.getTopLeft(find.text(s.continueApple)).dy;
    final google = tester.getTopLeft(find.text(s.continueGoogle)).dy;
    final email = tester.getTopLeft(find.text(s.continueEmail)).dy;
    expect(apple, lessThan(google));
    expect(google, lessThan(email));
    expect(find.byType(GoogleLogo), findsOneWidget);
  });

  testWidgets('email and password, for the review account', (tester) async {
    await tester.pumpWidget(app(const SignInScreen(google: true)));
    await settle(tester);
    await tester.tap(find.text(s.continueEmail));
    await settle(tester);
    expect(find.text(s.emailMeCode), findsOneWidget);
    await tester.tap(find.text(s.usePassword));
    await settle(tester);
    await tester.enterText(find.byType(TextField).at(0), 'review@kureeapp.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text(s.signIn));
    await settle(tester);
    // Offline in tests: the call fails and the error shows on the card.
    expect(find.text(s.errOffline), findsOneWidget);
    // Back to the start, the other ways are there again.
    await tester.tap(find.text(s.emailCodeInstead));
    await settle(tester);
    await tester.tap(find.text(s.otherWays));
    await settle(tester);
    expect(find.text(s.continueGoogle), findsOneWidget);
  });
}
