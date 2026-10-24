import 'dart:math' as math;
import 'dart:typed_data';

import 'scene.dart';

/// The draw's music and sound effects, made on the phone (no files to load):
/// a small groove that heats up while the bottle shakes, pen scratches and
/// glass clinks as each slip goes in, the cork, a drum roll, and a fanfare
/// for the result. Everything is placed from the same plan as the picture,
/// so the clinks land when the slips do. Rendered once into a buffer that
/// starts with the countdown; the same buffer plays live and goes into the
/// video.
class Soundtrack {
  static const int rate = 44100;

  /// 16-bit mono samples from the start of the countdown to the end of the
  /// video. Runs in a background isolate (about a second on a phone).
  static Int16List render(DrawPlan plan, int seed) => _Synth(plan, seed).run();

  /// A WAV file around the samples, for playing.
  static Uint8List wav(Int16List samples) {
    final data = samples.buffer.asUint8List(samples.offsetInBytes, samples.lengthInBytes);
    final b = BytesBuilder();
    void u32(int v) => b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
    void u16(int v) => b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
    b.add('RIFF'.codeUnits);
    u32(36 + data.length);
    b.add('WAVE'.codeUnits);
    b.add('fmt '.codeUnits);
    u32(16);
    u16(1);
    u16(1);
    u32(rate);
    u32(rate * 2);
    u16(2);
    u16(16);
    b.add('data'.codeUnits);
    u32(data.length);
    b.add(data);
    return b.toBytes();
  }
}

enum _Wave { sine, triangle, saw }

enum _Filt { lowpass, highpass, bandpass }

class _Synth {
  _Synth(this.plan, int seed) : rng = SeededRandom(seed ^ 0x5bd1e995) {
    final seconds = (DrawPlan.countdown + plan.end + DrawPlan.tail) / 1000;
    n = (seconds * Soundtrack.rate).ceil();
    music = Float64List(n);
    sfx = Float64List(n);
    noise = Float64List(Soundtrack.rate * 2);
    for (var i = 0; i < noise.length; i++) {
      noise[i] = rng.next() * 2 - 1;
    }
  }

  final DrawPlan plan;
  final SeededRandom rng;
  late final int n;
  late final Float64List music, sfx, noise;
  static const double sr = Soundtrack.rate * 1.0;
  static const double beat = 60 / 116;

  double r() => rng.next();
  static double note(num n) => 440 * math.pow(2, (n - 69) / 12).toDouble();
  static double lerp(double a, double b, double t) => a + (b - a) * t;

  // ---------------------------------------------------------------- building blocks

  /// The gain at time tau after the start: up from almost nothing to peak in
  /// a, then down to almost nothing over d (exponential, as in Web Audio).
  static double env(double tau, double a, double peak, double d) {
    const floor = 0.0001;
    if (tau < 0) return 0;
    if (tau < a) return floor * math.pow(peak / floor, tau / a).toDouble();
    if (tau < a + d) return peak * math.pow(floor / peak, (tau - a) / d).toDouble();
    return floor;
  }

  void osc(_Wave type, double f, double t, double dur, Float64List bus, double peak, [double a = 0.005, double? f2]) {
    final start = (t * sr).round(), stop = math.min(n, ((t + dur + 0.05) * sr).round());
    if (start >= n || stop <= 0) return;
    var phase = 0.0;
    final ratio = f2 == null ? 1.0 : f2 / f;
    for (var i = math.max(0, start); i < stop; i++) {
      final tau = (i - start) / sr;
      final double freq = f2 == null ? f : (tau < dur ? f * math.pow(ratio, tau / dur).toDouble() : f2);
      final dt = freq / sr;
      phase += dt;
      if (phase >= 1) phase -= 1;
      double s;
      switch (type) {
        case _Wave.sine:
          s = math.sin(phase * 2 * math.pi);
        case _Wave.triangle:
          s = 1 - 4 * (phase - 0.5).abs();
        case _Wave.saw:
          s = 2 * phase - 1 - _blep(phase, dt);
      }
      bus[i] += s * env(tau, a, peak, dur);
    }
  }

  static double _blep(double t, double dt) {
    if (t < dt) {
      final x = t / dt;
      return x + x - x * x - 1;
    }
    if (t > 1 - dt) {
      final x = (t - 1) / dt;
      return x * x + x + x + 1;
    }
    return 0;
  }

  /// Noise through a filter whose frequency may sweep from f to f2.
  void nz(double t, double dur, Float64List bus, double peak,
      {_Filt type = _Filt.bandpass, double f = 2000, double q = 1, double? f2, double a = 0.004}) {
    final start = (t * sr).round(), stop = math.min(n, ((t + dur + 0.05) * sr).round());
    if (start >= n || stop <= 0) return;
    final bq = _Biquad(type, q);
    var read = (r() * sr).floor();
    for (var i = math.max(0, start); i < stop; i++) {
      final tau = (i - start) / sr;
      if ((i - start) % 16 == 0) {
        final double freq = f2 == null ? f : (tau < dur ? f * math.pow(f2 / f, tau / dur).toDouble() : f2);
        bq.set(freq);
      }
      final x = noise[read];
      read = (read + 1) % noise.length;
      bus[i] += bq.run(x) * env(tau, a, peak, dur);
    }
  }

  // ---------------------------------------------------------------- instruments

  void kick(double t, [double v = 1]) => osc(_Wave.sine, 150, t, 0.28, music, 0.9 * v, 0.002, 42);

  void snare(double t, [double v = 1]) {
    nz(t, 0.16, music, 0.35 * v, type: _Filt.highpass, f: 1800);
    osc(_Wave.triangle, 190, t, 0.08, music, 0.25 * v);
  }

  void hat(double t, [double v = 1]) => nz(t, 0.045, music, 0.12 * v, type: _Filt.highpass, f: 8000);
  void shaker(double t, [double v = 1]) => nz(t, 0.06, music, 0.08 * v, f: 5200, q: 2);

  void mallet(double t, num nn, [double v = 1, double dur = 0.5]) {
    final f = note(nn);
    osc(_Wave.sine, f, t, dur, music, 0.32 * v, 0.003);
    osc(_Wave.sine, f * 4, t, 0.08, music, 0.06 * v, 0.002);
  }

  void bass(double t, num nn, double dur) {
    osc(_Wave.triangle, note(nn), t, dur, music, 0.42, 0.01);
    osc(_Wave.sine, note(nn - 12), t, dur, music, 0.3, 0.01);
  }

  void pad(double t, List<int> notes, double dur, [double v = 1]) {
    final peak = 0.035 * v;
    final start = (t * sr).round(), stop = math.min(n, ((t + dur + 0.05) * sr).round());
    if (start >= n || stop <= 0) return;
    final hold = math.max(0.25, dur - 0.3);
    for (final nn in notes) {
      for (final cents in const [-6.0, 6.0]) {
        final f = note(nn) * math.pow(2, cents / 1200).toDouble();
        final dt = f / sr;
        final bq = _Biquad(_Filt.lowpass, 1)..set(1400);
        var phase = r();
        for (var i = math.max(0, start); i < stop; i++) {
          final tau = (i - start) / sr;
          phase += dt;
          if (phase >= 1) phase -= 1;
          final s = 2 * phase - 1 - _blep(phase, dt);
          double g;
          if (tau < 0.25) {
            g = 0.0001 * math.pow(peak / 0.0001, tau / 0.25).toDouble();
          } else if (tau < hold) {
            g = peak;
          } else if (tau < dur) {
            g = peak * math.pow(0.0001 / peak, (tau - hold) / math.max(0.01, dur - hold)).toDouble();
          } else {
            g = 0.0001;
          }
          music[i] += bq.run(s) * g;
        }
      }
    }
  }

  // ---------------------------------------------------------------- sound effects

  void clink(double t) {
    final f = 1900 + r() * 1300;
    osc(_Wave.sine, f, t, 0.5, sfx, 0.16, 0.002);
    osc(_Wave.sine, f * 2.76, t, 0.22, sfx, 0.05, 0.002);
    nz(t, 0.05, sfx, 0.08, f: 3000, q: 3);
  }

  void pen(double t, double dur) {
    for (var x = 0.0; x < dur; x += 0.07 + r() * 0.05) {
      nz(t + x, 0.06, sfx, 0.07, f: 3500 + r() * 2000, q: 4);
    }
  }

  void rustle(double t, double dur, bool up) => nz(t, dur, sfx, 0.16, f: up ? 900 : 3200, q: 1.2, f2: up ? 3400 : 900, a: 0.04);
  void whoosh(double t, double dur) => nz(t, dur, sfx, 0.22, f: 400, q: 1.4, f2: 2400, a: dur * 0.4);

  void corkIn(double t) {
    osc(_Wave.sine, 520, t, 0.35, sfx, 0.08, 0.02, 900);
    osc(_Wave.sine, 110, t + 0.45, 0.18, sfx, 0.4, 0.002, 60);
    nz(t + 0.45, 0.06, sfx, 0.2, type: _Filt.lowpass, f: 900);
  }

  void pop(double t) {
    osc(_Wave.sine, 520, t, 0.14, sfx, 0.5, 0.001, 120);
    nz(t, 0.08, sfx, 0.4, f: 1400, q: 1.5);
  }

  void rattle(double t, double dur) {
    for (var x = 0.0; x < dur; x += 0.025 + r() * 0.05) {
      final a = math.sin(x / dur * math.pi);
      if (r() < 0.75) nz(t + x, 0.03, sfx, 0.05 + 0.18 * a, f: 2200 + r() * 2200, q: 3);
      if (r() < 0.18) clink(t + x);
    }
  }

  void roll(double t, double dur) {
    for (var x = 0.0; x < dur; x += lerp(0.11, 0.035, x / dur)) {
      final v = lerp(0.25, 1, x / dur);
      nz(t + x, 0.08, music, 0.22 * v, type: _Filt.highpass, f: 1600);
      osc(_Wave.triangle, 200, t + x, 0.05, music, 0.12 * v);
    }
    // The riser
    final start = (t * sr).round(), stop = math.min(n, ((t + dur + 0.1) * sr).round());
    final bq = _Biquad(_Filt.lowpass, 1);
    var phase = 0.0;
    for (var i = math.max(0, start); i < stop; i++) {
      final tau = (i - start) / sr;
      final k = (tau / dur).clamp(0.0, 1.0);
      final f = 110 * math.pow(4, k).toDouble();
      if ((i - start) % 16 == 0) bq.set(300 * math.pow(4000 / 300, k).toDouble());
      final dt = f / sr;
      phase += dt;
      if (phase >= 1) phase -= 1;
      final s = 2 * phase - 1 - _blep(phase, dt);
      final double g = tau < dur
          ? 0.0001 * math.pow(0.09 / 0.0001, tau / dur).toDouble()
          : (tau < dur + 0.05 ? 0.09 * math.pow(0.0001 / 0.09, (tau - dur) / 0.05).toDouble() : 0.0);
      music[i] += bq.run(s) * g;
    }
  }

  void tada(double t) {
    kick(t, 1.2);
    nz(t, 2.2, music, 0.28, type: _Filt.highpass, f: 5000, q: 0.7, a: 0.002);
    const chord = [60, 64, 67, 72, 76];
    for (var i = 0; i < chord.length; i++) {
      mallet(t + i * 0.035, chord[i] + 12, 1.1, 1.2);
    }
    pad(t, const [48, 60, 64, 67, 72], 2.8, 1.6);
    bass(t, 36, 1.4);
    const arp = [0, 4, 7, 12, 16, 12, 7, 4, 0];
    for (var i = 0; i < 9; i++) {
      osc(_Wave.sine, note(84 + arp[i]), t + 0.25 + i * 0.07, 0.3, sfx, 0.07, 0.002);
    }
    for (var c = 0; c < 26; c++) {
      nz(t + 0.1 + r() * 1.6, 0.02, sfx, 0.05, type: _Filt.highpass, f: 6000);
    }
  }

  void beep(double t, bool hi) {
    osc(_Wave.sine, hi ? 1320 : 880, t, 0.18, sfx, 0.35, 0.003);
    osc(_Wave.sine, hi ? 2640 : 1760, t, 0.08, sfx, 0.06, 0.003);
  }

  /// C, Am, F, G at 116 beats a minute.
  static const prog = [
    (48, [60, 64, 67]),
    (45, [57, 60, 64]),
    (41, [57, 60, 65]),
    (43, [59, 62, 67]),
  ];
  static const arpOrder = [0, 1, 2, 1, 2, 0, 1, 2];

  void groove(double t0, double t1, bool hot) {
    var bar = 0;
    for (var t = t0; t < t1 - 0.01; t += beat * 4, bar++) {
      final ch = prog[bar % 4];
      final left = t1 - t;
      bass(t, ch.$1, math.min(beat * 1.8, left));
      if (left > beat * 2) bass(t + beat * 2, ch.$1, beat * 1.6);
      if (bar % 2 == 0 || hot) pad(t, ch.$2, math.min(beat * 4, left), hot ? 1.2 : 0.8);
      for (var b = 0; b < 8; b++) {
        final tt = t + b * beat / 2;
        if (tt >= t1 - 0.02) break;
        if (b % 4 == 0) kick(tt);
        if (hot && b % 4 == 2) snare(tt);
        hat(tt, b.isOdd ? 0.6 : 1);
        if (hot) shaker(tt + beat / 4);
        mallet(tt, ch.$2[arpOrder[b]] + 12, b.isOdd ? 0.55 : 0.8, 0.45);
      }
    }
  }

  void outro(double t) {
    const chords = [
      (48, [72, 76, 79]),
      (41, [69, 72, 77]),
      (43, [71, 74, 79]),
      (48, [72, 76, 84]),
    ];
    for (var i = 0; i < chords.length; i++) {
      final c = chords[i];
      final tt = t + i * beat * 2;
      bass(tt, c.$1, beat * 1.8);
      pad(tt, [for (final x in c.$2) x - 12], beat * 2, 0.9);
      for (var j = 0; j < c.$2.length; j++) {
        mallet(tt + j * beat / 2, c.$2[j], 0.7, 0.5);
      }
      kick(tt);
      hat(tt + beat / 2);
      hat(tt + beat, 0.6);
      hat(tt + beat * 1.5);
    }
  }

  // ---------------------------------------------------------------- the whole thing

  Int16List run() {
    const lead = 0.02;
    final p = plan;
    // Countdown beeps: 3, 2, 1, go.
    beep(lead, false);
    beep(lead + 1, false);
    beep(lead + 2, false);
    beep(lead + 3, true);
    final t0 = DrawPlan.countdown / 1000 + lead;
    double at(double ms) => t0 + ms / 1000;
    groove(t0, at(p.shake), false);
    groove(at(p.shake), at(p.pick), true);
    for (final w in p.writeAt) {
      final d = p.writeD;
      rustle(at(w), 0.25, true);
      pen(at(w + d * 0.08), d * 0.32 / 1000);
      rustle(at(w + d * 0.5), d * 0.16 / 1000, false);
      whoosh(at(w + d * 0.66), d * 0.3 / 1000);
      clink(at(w + d + 60));
      clink(at(w + d + 260));
    }
    corkIn(at(p.cork));
    rattle(at(p.shake), p.shakeD / 1000);
    pop(at(p.shake + p.shakeD + 80));
    whoosh(at(p.pick + p.pickD * 0.32), 0.6);
    whoosh(at(p.pick + p.pickD * 0.62), 0.7);
    roll(at(p.pick), p.pickD / 1000);
    rustle(at(p.reveal + 300), 0.4, true);
    tada(at(p.reveal + 620));
    outro(at(p.reveal + 620 + 1600));
    return _master();
  }

  /// Music and effects together, through a gentle compressor, faded at the
  /// very end and brought up to a steady level.
  Int16List _master() {
    final out = Float64List(n);
    const threshold = -14.0, ratio = 4.0, knee = 12.0;
    final att = math.exp(-1 / (0.003 * sr)), rel = math.exp(-1 / (0.2 * sr));
    var envDb = -120.0;
    var peak = 0.0;
    for (var i = 0; i < n; i++) {
      final x = 0.9 * (music[i] * 0.55 + sfx[i] * 0.9);
      final level = x.abs() < 1e-9 ? -120.0 : 20 * math.log(x.abs()) / math.ln10;
      envDb = level > envDb ? att * envDb + (1 - att) * level : rel * envDb + (1 - rel) * level;
      final over = envDb - threshold;
      double reduce;
      if (over <= -knee / 2) {
        reduce = 0;
      } else if (over < knee / 2) {
        reduce = (1 / ratio - 1) * math.pow(over + knee / 2, 2).toDouble() / (2 * knee);
      } else {
        reduce = (1 / ratio - 1) * over;
      }
      final y = x * math.pow(10, reduce / 20).toDouble();
      out[i] = y;
      if (y.abs() > peak) peak = y.abs();
    }
    final gain = peak > 0 ? 0.89 / peak : 1.0;
    final fade = (0.4 * sr).round();
    final pcm = Int16List(n);
    for (var i = 0; i < n; i++) {
      var y = out[i] * gain;
      if (i > n - fade) y *= (n - i) / fade;
      pcm[i] = (y.clamp(-1.0, 1.0) * 32767).round();
    }
    return pcm;
  }
}

/// A second-order filter (the Web Audio low-pass, high-pass and band-pass).
class _Biquad {
  _Biquad(this.type, this.q);
  final _Filt type;
  final double q;
  double b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0;
  double x1 = 0, x2 = 0, y1 = 0, y2 = 0;

  void set(double freq) {
    final double f = freq.clamp(10.0, _Synth.sr / 2 - 100);
    final w0 = 2 * math.pi * f / _Synth.sr;
    final cosw = math.cos(w0), sinw = math.sin(w0);
    double alpha, nb0, nb1, nb2;
    switch (type) {
      case _Filt.lowpass:
        alpha = sinw / (2 * math.pow(10, q / 20).toDouble());
        nb0 = (1 - cosw) / 2;
        nb1 = 1 - cosw;
        nb2 = (1 - cosw) / 2;
      case _Filt.highpass:
        alpha = sinw / (2 * math.pow(10, q / 20).toDouble());
        nb0 = (1 + cosw) / 2;
        nb1 = -(1 + cosw);
        nb2 = (1 + cosw) / 2;
      case _Filt.bandpass:
        alpha = sinw / (2 * q);
        nb0 = alpha;
        nb1 = 0;
        nb2 = -alpha;
    }
    final a0 = 1 + alpha;
    b0 = nb0 / a0;
    b1 = nb1 / a0;
    b2 = nb2 / a0;
    a1 = -2 * cosw / a0;
    a2 = (1 - alpha) / a0;
  }

  double run(double x) {
    final y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
    x2 = x1;
    x1 = x;
    y2 = y1;
    y1 = y;
    return y;
  }
}
