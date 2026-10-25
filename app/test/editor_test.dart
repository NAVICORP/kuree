// The slots in a new chit: one empty row to start, and the next one comes
// as each name is typed, past ten and on.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/api.dart';
import 'package:kuree/l10n/strings.dart';
import 'package:kuree/ui/kuri_editor.dart';
import 'package:kuree/ui/theme.dart';

void main() {
  setUp(() => Api.instance.offline = true);
  tearDown(() => Api.instance.offline = false);

  Widget app(Widget home) => MaterialApp(
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

  Finder slot(int n) => find.byKey(ValueKey('slot-$n-1'));

  testWidgets('one empty slot, and the next comes as each name is typed', (tester) async {
    await tester.pumpWidget(app(const KuriEditorScreen()));
    await tester.pump();
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(slot(1), 300, scrollable: list);
    expect(slot(1), findsOneWidget);
    expect(slot(2), findsNothing);

    await tester.enterText(slot(1), 'Anees');
    await tester.pump();
    expect(slot(2), findsOneWidget);
    expect(slot(3), findsNothing);

    // Next on the keyboard goes on to the new row.
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(slot(2)).focusNode!.hasFocus, isTrue);

    await tester.enterText(slot(2), 'Naif');
    await tester.pump();
    expect(slot(3), findsOneWidget);

    // Clearing the last name takes the spare row away again.
    await tester.enterText(slot(2), '');
    await tester.pump();
    expect(slot(2), findsOneWidget);
    expect(slot(3), findsNothing);
  });

  testWidgets('more than ten slots, one name at a time', (tester) async {
    await tester.pumpWidget(app(const KuriEditorScreen()));
    await tester.pump();
    final list = find.byType(Scrollable).first;
    for (var i = 1; i <= 12; i++) {
      await tester.scrollUntilVisible(slot(i), 200, scrollable: list);
      await tester.enterText(slot(i), 'Member $i');
      await tester.pump();
    }
    await tester.scrollUntilVisible(slot(13), 200, scrollable: list);
    expect(slot(13), findsOneWidget);
    expect(slot(14), findsNothing);
  });
}
