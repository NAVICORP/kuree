import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/api.dart';
import 'package:kuree/core/startup.dart';
import 'package:kuree/l10n/strings.dart';
import 'package:kuree/ui/launch.dart';
import 'package:kuree/ui/theme.dart';

import 'support.dart';

Widget app(Future<void> Function() work, {bool still = false, bool contrast = false}) => MaterialApp(
      theme: kureeTheme(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: still, highContrast: contrast),
          child: LaunchScreen(work: work, child: const Scaffold(body: Text('next screen'))),
        ),
      ),
    );

final launch = find.byKey(const ValueKey('launch'));
final next = find.text('next screen');

void main() {
  setUpAll(loadAppFonts);
  setUp(() => Api.instance.offline = true);
  tearDown(() => Api.instance.offline = false);

  testWidgets('the loader shows, then gives way to the next screen', (tester) async {
    await tester.pumpWidget(app(() => Future<void>.delayed(const Duration(milliseconds: 900))));
    expect(launch, findsOneWidget);
    expect(next, findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(launch, findsOneWidget);
    expect(next, findsNothing);
    // Done at 900 ms: the next screen is built under the fading loader...
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 16));
    expect(next, findsOneWidget);
    // ...and the loader is gone a moment later.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 16));
    expect(launch, findsNothing);
    expect(next, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('it shows for at least 600 ms, so it never flickers', (tester) async {
    await tester.pumpWidget(app(() async {}));
    await tester.pump(const Duration(milliseconds: 300));
    expect(next, findsNothing);
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pump(const Duration(milliseconds: 16));
    expect(next, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 16));
    expect(launch, findsNothing);
  });

  testWidgets('a slow network: "Still loading", then the app takes over', (tester) async {
    final never = Completer<void>();
    await tester.pumpWidget(app(() => never.future));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(S.current.launchStillLoading), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(S.current.launchStillLoading), findsOneWidget);
    // It never holds the app back for long.
    await tester.pump(LaunchScreen.handOverAfter);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 16));
    expect(launch, findsNothing);
    expect(next, findsOneWidget);
  });

  testWidgets('offline: says why, and Try again carries on', (tester) async {
    var calls = 0;
    await tester.pumpWidget(app(() async {
      calls++;
      if (calls == 1) throw ApiError(S.current.errNoConnection);
    }));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(S.current.errNoConnection), findsOneWidget);
    expect(find.text(S.current.tryAgain), findsOneWidget);
    expect(next, findsNothing);
    // It waits for the person rather than giving up on its own.
    await tester.pump(LaunchScreen.handOverAfter);
    expect(next, findsNothing);
    await tester.tap(find.text(S.current.tryAgain));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 16));
    expect(calls, 2);
    expect(launch, findsNothing);
    expect(next, findsOneWidget);
  });

  testWidgets('a tap bounces the card with a tick, a drag tilts it', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final never = Completer<void>();
    await tester.pumpWidget(app(() => never.future));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(launch);
    await tester.pump(const Duration(milliseconds: 60));
    expect(calls.where((c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.selectionClick'), hasLength(1));
    final g = await tester.startGesture(tester.getCenter(launch));
    await g.moveBy(const Offset(120, -160));
    await tester.pump(const Duration(milliseconds: 200));
    await g.up();
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion and Increase contrast still load and leave', (tester) async {
    await tester.pumpWidget(app(() async {}, still: true, contrast: true));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(launch);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 16));
    expect(launch, findsNothing);
    expect(next, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('signed out, start-up has nothing to load and does not fail', () async {
    expect(Api.instance.signedIn, isFalse);
    await Startup.instance.run();
    expect(Startup.instance.take(), isNull);
  });
}
