import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/core/format.dart';
import 'package:kuree/l10n/strings.dart';

/// One ARB file, without its @ notes.
Map<String, String> arb(String code) {
  final j = jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync()) as Map<String, dynamic>;
  return {for (final e in j.entries) if (!e.key.startsWith('@')) e.key: e.value as String};
}

Set<String> holes(String s) => RegExp(r'\{([a-zA-Z][a-zA-Z0-9]*)\}').allMatches(s).map((m) => m.group(1)!).toSet();

void main() {
  tearDown(() => S.current = S.forCode('en'));
  final en = arb('en');

  test('the six languages', () {
    expect(S.codes, ['en', 'ar', 'ml', 'ta', 'kn', 'hi']);
    expect(S.names.keys.toList(), S.codes);
  });

  for (final code in S.codes) {
    test('$code has every key, with the same placeholders', () {
      final t = arb(code);
      expect(t.keys.toSet(), en.keys.toSet());
      for (final k in en.keys) {
        expect(holes(t[k]!), holes(en[k]!), reason: '$code.$k');
        expect(t[k]!.trim(), isNotEmpty, reason: '$code.$k');
        expect(t[k]!.contains('\u2014'), isFalse, reason: '$code.$k has an em dash');
        expect(t[k]!.contains('\u00b7'), isFalse, reason: '$code.$k has a middle dot');
        if (en[k]!.contains('Kuree')) expect(t[k]!.contains('Kuree'), isTrue, reason: '$code.$k should keep the name Kuree');
      }
    });

    test('$code: the words in the app match the ARB file', () {
      expect(S.table(code), arb(code));
    });
  }

  test('English says chit, never kuri', () {
    for (final e in en.entries) {
      expect(RegExp(r'\bkuris?\b', caseSensitive: false).hasMatch(e.value), isFalse, reason: e.key);
    }
  });

  test('the language changes months, days and times', () {
    S.current = S.forCode('ml');
    expect(monthName(10), 'ഒക്ടോബർ');
    expect(dayOf(25), '25');
    expect(S.current.slotN(4), 'സ്ലോട്ട് 4');
    S.current = S.forCode('ar');
    expect(monthName(1), 'يناير');
    expect(S.current.isRtl, isTrue);
    S.current = S.forCode('en');
    expect(monthName(10), 'October');
    expect(dayOf(25), '25th');
    expect(clock(DateTime(2026, 10, 20, 19, 31)), '7:31 pm');
  });

  test('only Arabic reads right to left', () {
    for (final c in S.codes) {
      expect(S.forCode(c).isRtl, c == 'ar', reason: c);
    }
  });

  test('an unknown language falls back to English', () {
    expect(S.forCode('fr').code, 'en');
  });
}
