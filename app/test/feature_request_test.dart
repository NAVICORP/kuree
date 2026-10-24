import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/api.dart';
import 'package:kuree/ui/feature_request_screen.dart';
import 'package:kuree/ui/theme.dart';

void main() {
  setUp(() => Api.instance.offline = true);
  tearDown(() => Api.instance.offline = false);

  Widget app(Widget home) => MaterialApp(theme: kureeTheme(), home: home);

  testWidgets('asks for a title, then says what went wrong when offline', (tester) async {
    await tester.pumpWidget(app(const FeatureRequestScreen()));
    await tester.pumpAndSettle();
    expect(find.text(FeatureRequestText.introTitle), findsOneWidget);
    expect(find.text(FeatureRequestText.noneYet), findsOneWidget);

    await tester.ensureVisible(find.text(FeatureRequestText.send));
    await tester.tap(find.text(FeatureRequestText.send));
    await tester.pumpAndSettle();
    expect(find.text(FeatureRequestText.needTitle), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'A reminder the day before');
    await tester.ensureVisible(find.text(FeatureRequestText.important));
    await tester.tap(find.text(FeatureRequestText.important));
    await tester.ensureVisible(find.text(FeatureRequestText.send));
    await tester.tap(find.text(FeatureRequestText.send));
    await tester.pumpAndSettle();
    expect(find.text('Offline.'), findsOneWidget);
    expect(find.text(FeatureRequestText.thanksTitle), findsNothing);
  });

  testWidgets('the inbox shows the error and a way to try again', (tester) async {
    await tester.pumpWidget(app(const FeatureInboxScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Offline.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  test('requests read from the server', () {
    final list = FeatureRequest.list([
      {'id': 3, 'title': 'Dark mode', 'status': 'planned', 'owner_note': 'Soon', 'created_at': '2026-10-25T10:00:00Z', 'importance': 'must'},
      'not a request',
    ]);
    expect(list.length, 1);
    expect(list.first.id, 3);
    expect(list.first.status, 'planned');
    expect(list.first.note, 'Soon');
    expect(list.first.signedUp, isTrue);
  });
}
