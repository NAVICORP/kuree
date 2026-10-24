import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuree/draw/scene.dart';
import 'package:kuree/draw/soundtrack.dart';

BottleScene make(int seed) => BottleScene(
      order: const [DrawEntry(1, 'Nazil'), DrawEntry(2, 'Nazil'), DrawEntry(3, 'Ramshad Ac'), DrawEntry(5, 'Ishaque'), DrawEntry(10, 'Farhan / Yasir')],
      pickIndex: 3,
      seed: seed,
      kicker: 'BOYSTOWN 5K KURI',
      title: 'Month 6 draw',
      subtitle: 'November 2026, pot ₹65,000',
      when: DateTime(2026, 11, 20, 19, 30),
    )..subtitlePot = '₹65,000';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the plan fits a WhatsApp video', () {
    final p = DrawPlan.forCount(9);
    expect(p.writeAt.length, 9);
    expect(p.end, lessThan(16000));
    expect(DrawPlan.forCount(13).end, lessThan(17000));
  });

  test('the same seed plays the same draw', () {
    final a = make(42), b = make(42);
    for (var t = -3000.0; t < a.plan.end + 1600; t += 1000 / 30) {
      a.advanceTo(t);
    }
    for (var t = -3000.0; t < b.plan.end + 1600; t += 1000 / 7) {
      b.advanceTo(t);
    }
    b.advanceTo(a.simT);
    expect(a.simT, b.simT);
    expect(a.confettiCount, b.confettiCount);
    expect(a.picked.slot, 5);
  });

  test('every frame paints without error', () {
    final s = make(7);
    for (var t = -3000.0; t < s.length - 3000; t += 250) {
      s.advanceTo(t);
      final rec = ui.PictureRecorder();
      s.paint(Canvas(rec), t);
      rec.endRecording().dispose();
    }
  });

  test('the soundtrack covers the whole video and is not silent', () {
    final s = make(3);
    final pcm = Soundtrack.render(s.plan, 3);
    final expected = (s.length / 1000 * Soundtrack.rate).ceil();
    expect(pcm.length, expected);
    var peak = 0;
    for (final v in pcm) {
      if (v.abs() > peak) peak = v.abs();
    }
    expect(peak, greaterThan(20000));
    final wav = Soundtrack.wav(pcm);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(wav.length, 44 + pcm.length * 2);
  });
}
