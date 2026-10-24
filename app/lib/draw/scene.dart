import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../core/format.dart';

/// One slip: a slot still waiting for the pot.
class DrawEntry {
  const DrawEntry(this.slot, this.name);
  final int slot;
  final String name;
}

/// A small seeded random source, so the draw can be played again frame by
/// frame for the video and come out exactly the same.
class SeededRandom {
  SeededRandom(int seed) : _s = seed & 0xFFFFFFFF;
  int _s;

  /// 0 <= x < 1 (mulberry32)
  double next() {
    _s = (_s + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _s;
    t = _imul(t ^ (t >> 15), t | 1);
    t ^= t + _imul(t ^ (t >> 7), t | 61);
    t &= 0xFFFFFFFF;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0;
  }

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;
}

/// When each part of the draw starts, in ms after the countdown. Kept short
/// (about 15 s with the countdown) so the video fits a WhatsApp share.
class DrawPlan {
  DrawPlan._(this.writeAt, this.writeD, this.cork, this.shake, this.shakeD, this.pick, this.pickD, this.reveal, this.end);

  factory DrawPlan.forCount(int n) {
    final gap = math.max(170.0, math.min(300.0, 2000.0 / n));
    final d = gap / 0.62;
    final at = [for (var i = 0; i < n; i++) 570 + i * gap];
    final inEnd = at.last + d + 600;
    final shake = inEnd + 360;
    final pick = shake + 1840 + 200;
    final reveal = pick + 2060;
    return DrawPlan._(at, d, inEnd, shake, 1840, pick, 2060, reveal, reveal + 4600);
  }

  final List<double> writeAt;
  final double writeD;
  final double cork, shake, shakeD, pick, pickD, reveal, end;

  /// The countdown before the draw, in ms.
  static const countdown = 3000.0;

  /// How long the video runs after the result, in ms.
  static const tail = 1600.0;
}

class _Slip {
  _Slip(this.e, this.i, this.ang, this.hue);
  final DrawEntry e;
  final int i;
  String mode = 'wait';
  double x = 0, y = 0, vx = 0, vy = 0, va = 0;
  double ang;
  final Color hue;
  double ox0 = 0, oy0 = 0, oang = 0;
}

class _Bit {
  _Bit(this.x, this.y, this.vx, this.vy, this.r, this.vr, this.w, this.h, this.c);
  double x, y, vx, vy, r, vr;
  final double w, h;
  final Color c;
  double life = 1;
}

/// The bottle draw on one tall picture (1080 x 1920): one rolled slip per
/// waiting slot dropped into a glass bottle, corked, shaken, tipped until the
/// picked slip falls out and opens. The pick is decided before the first
/// frame; the scene only shows it. Time t is in ms from the end of the
/// countdown (negative during it).
class BottleScene {
  BottleScene({
    required List<DrawEntry> order,
    required this.pickIndex,
    required int seed,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.when,
  })  : rng = SeededRandom(seed),
        plan = DrawPlan.forCount(order.length) {
    const hues = [C.paper, Color(0xFFFFF7E0), Color(0xFFF7FBF6), Color(0xFFFFF9EC)];
    slips = [for (var i = 0; i < order.length; i++) _Slip(order[i], i, (rng.next() - 0.5) * 0.6, hues[i % 4])];
  }

  static const double W = 1080, H = 1920;

  final int pickIndex;

  /// "BOYSTOWN 5K KURI", "Month 5 draw", "October 2026, pot ₹65,000"
  final String kicker, title, subtitle;
  final DateTime? when;
  final SeededRandom rng;
  final DrawPlan plan;
  late final List<_Slip> slips;
  final List<_Bit> confetti = [];
  bool _burst = false;
  double simT = -DrawPlan.countdown;

  DrawEntry get picked => slips[pickIndex].e;

  /// The whole run, countdown to the end of the video, in ms.
  double get length => DrawPlan.countdown + plan.end + DrawPlan.tail;

  // ---------------------------------------------------------------- the bottle

  static const double _bw = 470, _bh = 560, _neckW = 170, _neckH = 140, _shoulder = 100, _r = 36;
  double _bx = W / 2, _by = 1220, _ba = 0, _bs = 1, _box = 0;

  void _pose(double t) {
    _bx = W / 2;
    final p = plan;
    if (t < p.shake || t < 0) {
      _ba = 0;
      _box = 0;
    } else if (t < p.shake + p.shakeD) {
      final q = (t - p.shake) / p.shakeD, amp = math.sin(q * math.pi);
      _ba = math.sin(q * math.pi * 9) * 0.42 * amp + math.sin(q * math.pi * 23) * 0.06 * amp;
      _box = math.sin(q * math.pi * 7 + 1) * 70 * amp;
    } else if (t < p.pick) {
      _ba = 0;
      _box = 0;
    } else if (t < p.reveal) {
      final pk = (t - p.pick) / p.pickD;
      _ba = _lerp(0, 2.25, _ease(pk / 0.45)) - (pk > 0.75 ? _lerp(0, 2.25, _ease((pk - 0.75) / 0.25)) : 0);
      _box = 0;
    } else {
      _ba = 0;
      _box = 0;
    }
    if (t >= p.reveal) {
      final rv = t - p.reveal;
      _bs = _lerp(1, 0.5, _ease(rv / 900));
      _by = _lerp(1220, 1500, _ease(rv / 900));
    } else {
      _bs = 1;
      _by = 1220;
    }
  }

  String _mode(double t) => t < plan.cork ? 'open' : (t >= plan.pick && t < plan.reveal ? 'tip' : 'closed');

  double _kick(double t) {
    final p = plan;
    if (t >= p.shake && t < p.shake + p.shakeD) return 260 * math.sin((t - p.shake) / p.shakeD * math.pi);
    return 0;
  }

  double _cork(double t) {
    final p = plan;
    if (t < p.cork) return 0;
    if (t < p.shake) return _out((t - p.cork) / 700);
    if (t < p.shake + p.shakeD) return 1;
    if (t < p.pick) return 1 - _out((t - p.shake - p.shakeD) / 450);
    return 0;
  }

  Offset _toWorld(double x, double y) {
    final c = math.cos(_ba), s = math.sin(_ba);
    return Offset(_bx + _box + (x * c - y * s) * _bs, _by + (x * s + y * c) * _bs);
  }

  Offset _toLocal(double x, double y) {
    final dx = (x - _bx - _box) / _bs, dy = (y - _by) / _bs, c = math.cos(-_ba), s = math.sin(-_ba);
    return Offset(dx * c - dy * s, dx * s + dy * c);
  }

  Path _bottlePath({bool close = false, double extra = 0}) {
    final w = _bw / 2, h = _bh / 2, n = _neckW / 2, top = -h - _shoulder, nt = top - _neckH - extra;
    final p = Path()
      ..moveTo(-n, nt)
      ..lineTo(-n, top)
      ..cubicTo(-n, top + 60, -w, top + 40, -w, -h + 30)
      ..lineTo(-w, h - 70)
      ..quadraticBezierTo(-w, h, -w + 70, h)
      ..lineTo(w - 70, h)
      ..quadraticBezierTo(w, h, w, h - 70)
      ..lineTo(w, -h + 30)
      ..cubicTo(w, top + 40, n, top + 60, n, top)
      ..lineTo(n, nt);
    if (close) p.close();
    return p;
  }

  // ---------------------------------------------------------------- the simulation

  static const _step = 1000 / 120;

  /// Runs the simulation up to time t, in fixed steps, so the same seed always
  /// gives the same picture at the same time.
  void advanceTo(double t) {
    while (simT + _step <= t) {
      simT += _step;
      _update(simT, _step / 1000);
    }
  }

  void _update(double t, double dt) {
    if (t < 0) return;
    _pose(t);
    final p = plan;
    // A slip that has flown into the neck drops in.
    for (final s in slips) {
      if (s.mode != 'wait') continue;
      if ((t - p.writeAt[s.i]) / p.writeD < 1) continue;
      final mouth = _toWorld(0, -_bh / 2 - _shoulder - _neckH - 30);
      final local = _toLocal(mouth.dx, mouth.dy);
      s.mode = 'in';
      s.x = local.dx + (rng.next() - 0.5) * 10;
      s.y = local.dy;
      s.vx = (rng.next() - 0.5) * 60;
      s.vy = 600;
      s.ang = math.pi / 2 + (s.i.isOdd ? 0.25 : -0.25);
      s.va = (rng.next() - 0.5) * 3;
    }
    // The picked slip slides to the neck and out.
    if (t >= p.pick && t < p.reveal) {
      final ch = slips[pickIndex];
      final pk = (t - p.pick) / p.pickD;
      if (ch.mode == 'in' && pk > 0.32) {
        ch.mode = 'out';
        ch.ox0 = ch.x;
        ch.oy0 = ch.y;
        ch.oang = ch.ang;
      }
    }
    _physics(dt, _mode(t), _kick(t));
    if (!_burst && t >= p.reveal + 650) {
      _burst = true;
      _spray(W / 2, 800);
    }
    for (final b in confetti) {
      b.vy += 1500 * dt;
      b.vx *= math.pow(0.99, dt * 60).toDouble();
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.r += b.vr * dt;
      b.life -= dt * 0.18;
    }
    confetti.removeWhere((b) => b.life <= 0 || b.y > H + 60);
  }

  void _physics(double dt, String mode, double kick) {
    final gx = math.sin(-_ba) * 2600, gy = math.cos(-_ba) * 2600;
    final inside = slips.where((s) => s.mode == 'in').toList();
    final damp = math.pow(0.995, dt * 60).toDouble(), dampA = math.pow(0.985, dt * 60).toDouble(), k = kick * dt * 60;
    for (final s in inside) {
      // How far the rolled slip reaches at its angle, so its ends stay inside the glass too.
      final co = math.cos(s.ang).abs(), si = math.sin(s.ang).abs();
      final hx = math.max(_r, 64 * co + 23 * si) + 6, hy = math.max(_r, 64 * si + 23 * co) + 6;
      final w = _bw / 2 - hx, h = _bh / 2 - hy, n = math.max(0.0, _neckW / 2 - hx), top = -_bh / 2 - _shoulder - _neckH + hy;
      s.vx += gx * dt;
      s.vy += gy * dt;
      if (k > 0) {
        s.vx += (rng.next() - 0.5) * k;
        s.vy += (rng.next() - 0.65) * k;
        s.va += (rng.next() - 0.5) * k * 0.01;
      }
      s.vx *= damp;
      s.vy *= damp;
      s.va *= dampA;
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.ang += s.va * dt;
      final bodyTop = -_bh / 2 + 30, neckBase = -_bh / 2 - _shoulder + hy;
      if (s.y < bodyTop) {
        final kk = ((bodyTop - s.y) / (bodyTop - neckBase)).clamp(0.0, 1.0), lim = _lerp(w, n, kk);
        if (s.x < -lim) {
          s.x = -lim;
          s.vx = s.vx.abs() * 0.4;
        }
        if (s.x > lim) {
          s.x = lim;
          s.vx = -s.vx.abs() * 0.4;
        }
        // Open while the slips go in; corked while it shakes; held at the
        // shoulder while it is tipped, so only the picked slip comes out.
        final cap = mode == 'open' ? -1e9 : (mode == 'tip' ? neckBase : top);
        if (s.y < cap) {
          s.y = cap;
          s.vy = s.vy.abs() * 0.3;
        }
      } else {
        if (s.x < -w) {
          s.x = -w;
          s.vx = s.vx.abs() * 0.45;
          s.va += s.vy * 0.002;
        }
        if (s.x > w) {
          s.x = w;
          s.vx = -s.vx.abs() * 0.45;
          s.va -= s.vy * 0.002;
        }
      }
      if (s.y > h) {
        s.y = h;
        s.vy = -s.vy.abs() * 0.35;
        s.vx *= 0.9;
        s.va += s.vx * 0.003;
      }
    }
    for (var i = 0; i < inside.length; i++) {
      for (var j = i + 1; j < inside.length; j++) {
        final a = inside[i], b = inside[j];
        final dx = b.x - a.x, dy = b.y - a.y, d2 = dx * dx + dy * dy, m = _r * 2 * 0.86;
        if (d2 < m * m && d2 > 0.01) {
          final d = math.sqrt(d2), push = (m - d) / 2, ux = dx / d, uy = dy / d;
          a.x -= ux * push;
          a.y -= uy * push;
          b.x += ux * push;
          b.y += uy * push;
          final rv = (b.vx - a.vx) * ux + (b.vy - a.vy) * uy;
          if (rv < 0) {
            final imp = rv * 0.6;
            a.vx += ux * imp;
            a.vy += uy * imp;
            b.vx -= ux * imp;
            b.vy -= uy * imp;
          }
        }
      }
    }
  }

  void _spray(double x, double y) {
    const cols = [C.sun, C.leaf, C.mint, Color(0xFFFFFFFF), C.peach, Color(0xFF7FD18F)];
    for (var i = 0; i < 170; i++) {
      final a = rng.next() * math.pi * 2, sp = 500 + rng.next() * 1200;
      confetti.add(_Bit(x, y, math.cos(a) * sp, math.sin(a) * sp - 700, rng.next() * 6, (rng.next() - 0.5) * 14,
          12 + rng.next() * 14, 6 + rng.next() * 10, cols[i % cols.length]));
    }
  }

  // ---------------------------------------------------------------- painting

  /// Paints the frame for time t (after advanceTo(t)) onto a 1080 x 1920 canvas.
  void paint(Canvas g, double t) {
    _pose(t < 0 ? 0.0 : t);
    if (t < 0) {
      _ba = 0;
      _box = 0;
      _bs = 1;
      _by = 1220;
    }
    _bg(g, t);
    _header(g);

    if (t < 0) {
      _bottleBack(g);
      _bottleFront(g, 0);
      if (t > -DrawPlan.countdown) {
        final since = t + DrawPlan.countdown;
        final left = 3 - (since / 1000).floor();
        final f = (since % 1000) / 1000;
        _text(g, '$left', W / 2, 1160,
            size: 360 + f * 120, weight: FontWeight.w800, heading: true, color: C.sun.withValues(alpha: 1 - f * 0.6), base: _Base.middle);
        _caption(g, 'Get ready', 'The draw starts in a moment');
      }
      _footer(g);
      return;
    }

    final p = plan;
    final top = <void Function()>[];
    // Writing, rolling and dropping each slip.
    for (final s in slips) {
      if (s.mode == 'in' || s.mode == 'out' || t < p.writeAt[s.i]) continue;
      final k = (t - p.writeAt[s.i]) / p.writeD;
      const sx = W / 2, sy = 520.0;
      if (k < 0.5) {
        final appear = _out(k / 0.12);
        final letters = (((k - 0.08) / 0.32).clamp(0.0, 1.0) * s.e.name.length).floor();
        top.add(() => _slipFlat(g, sx, sy + (1 - appear) * 60, 620, 170, s.ang * 0.2, s, letters, appear));
      } else if (k < 0.66) {
        final r = _ease((k - 0.5) / 0.16);
        if (r < 0.6) {
          top.add(() => _slipFlat(g, sx, sy, _lerp(620, 140, r / 0.6), _lerp(170, 50, r / 0.6), s.ang * 0.2, s, null, 1 - r * 0.6));
        } else {
          top.add(() => _slipRolled(g, sx, sy, s.ang * 0.2 * (1 - r), s, 1.2));
        }
      } else {
        final f = ((k - 0.66) / 0.34).clamp(0.0, 1.0);
        final mouth = _toWorld(0, -_bh / 2 - _shoulder - _neckH - 30);
        final fx = _lerp(sx, mouth.dx, _ease(f)), fy = _lerp(sy, mouth.dy, _ease(f)) - math.sin(f * math.pi) * 140;
        final ang = _lerp(0, math.pi / 2 + (s.i.isOdd ? 0.25 : -0.25), _ease(f));
        top.add(() => _slipRolled(g, fx, fy, ang, s, _lerp(1.2, 1, f)));
      }
    }

    final mode = _mode(t);
    _bottleBack(g);
    g.save();
    g.translate(_bx + _box, _by);
    g.rotate(_ba);
    g.scale(_bs, _bs);
    g.clipPath(_bottlePath(close: true, extra: mode == 'open' ? 600 : 0));
    g.scale(1 / _bs, 1 / _bs);
    g.rotate(-_ba);
    g.translate(-(_bx + _box), -_by);
    for (final s in slips) {
      if (s.mode != 'in') continue;
      final wp = _toWorld(s.x, s.y);
      _slipRolled(g, wp.dx, wp.dy, _ba + s.ang, s, _bs);
    }
    g.restore();
    _bottleFront(g, _cork(t));

    // Captions
    final lastEnd = p.writeAt.last + p.writeD;
    if (t < 1500) {
      _caption(g, 'Writing every name', 'One slip for every slot still waiting for the pot');
    } else if (t < lastEnd) {
      final cur = [for (final s in slips) if (t >= p.writeAt[s.i]) s].length;
      _caption(g, 'Into the bottle', '$cur of ${slips.length}');
    } else if (t < p.shake) {
      _caption(g, 'Closing the bottle', null);
    } else if (t < p.shake + p.shakeD) {
      _caption(g, 'Shaking', 'Every slip has the same chance');
    } else if (t < p.reveal) {
      _caption(g, 'Picking one', null);
    }

    for (final f in top) {
      f();
    }

    // The picked slip on its way out.
    final ch = slips[pickIndex];
    if (ch.mode == 'out' && t < p.reveal) {
      final pk = (t - p.pick) / p.pickD;
      final e = ((pk - 0.32) / 0.3).clamp(0.0, 1.0);
      final topY = -_bh / 2 - _shoulder - _neckH - 80;
      if (e < 1) {
        final lx = _lerp(ch.ox0, 0, _ease(math.min(1, e * 1.6))), ly = _lerp(ch.oy0, topY, _ease(e));
        final wp = _toWorld(lx, ly);
        final wa = _ba + _lerp(ch.oang, math.pi / 2, e);
        // Still inside the neck: keep it behind the glass.
        g.save();
        g.translate(_bx + _box, _by);
        g.rotate(_ba);
        g.scale(_bs, _bs);
        g.clipPath(_bottlePath(close: true, extra: 600));
        g.scale(1 / _bs, 1 / _bs);
        g.rotate(-_ba);
        g.translate(-(_bx + _box), -_by);
        _slipRolled(g, wp.dx, wp.dy, wa, ch, 1);
        g.restore();
      } else {
        // Out, and up into the light. Where it left the neck:
        final saveA = _ba, saveOx = _box, saveS = _bs, saveY = _by;
        _pose(p.pick + 0.62 * p.pickD);
        final from = _toWorld(0, topY);
        final fromA = _ba + math.pi / 2;
        _ba = saveA;
        _box = saveOx;
        _bs = saveS;
        _by = saveY;
        final u = ((pk - 0.62) / 0.38).clamp(0.0, 1.0);
        final wx = _lerp(from.dx, W / 2, _ease(u)), wy = _lerp(from.dy, 820, _ease(u)) - math.sin(u * math.pi) * 120;
        final wa = _lerp(fromA, math.pi * 2, _ease(u));
        _slipRolled(g, wx, wy, wa, ch, _lerp(1, 1.3, u));
      }
    }

    if (t >= p.reveal) {
      final rk = t - p.reveal;
      // Rays
      g.save();
      g.clipRect(const Rect.fromLTWH(0, 350, W, H - 350));
      g.translate(W / 2, 800);
      g.rotate(t / 4000);
      final ray = Paint()..color = C.sun.withValues(alpha: (rk / 600).clamp(0.0, 1.0) * 0.22);
      for (var i = 0; i < 14; i++) {
        g.rotate(math.pi * 2 / 14);
        g.drawPath(Path()
          ..moveTo(0, 0)
          ..lineTo(-60, -900)
          ..lineTo(60, -900)
          ..close(), ray);
      }
      g.restore();
      final op = _back(rk / 700);
      if (rk < 350) {
        _slipRolled(g, W / 2, 800, 0, ch, 1.3 + rk / 350 * 0.4);
      } else {
        _slipFlat(g, W / 2, 800, _lerp(180, 860, op), _lerp(60, 250, op), 0, ch, null, 1);
      }
      final a = ((rk - 700) / 500).clamp(0.0, 1.0);
      if (a > 0) {
        _text(g, 'TAKES THE POT THIS MONTH', W / 2, 1010, size: 46, weight: FontWeight.w800, color: C.sun.withValues(alpha: a));
        _text(g, subtitlePot, W / 2, 1110, size: 96, weight: FontWeight.w800, heading: true, color: const Color(0xFFFFFFFF).withValues(alpha: a));
      }
    }

    // Confetti
    final bit = Paint();
    for (final b in confetti) {
      g.save();
      g.translate(b.x, b.y);
      g.rotate(b.r);
      bit.color = b.c.withValues(alpha: b.life.clamp(0.0, 1.0));
      g.drawRect(Rect.fromLTWH(-b.w / 2, -b.h / 2, b.w, b.h * math.cos(b.r * 2).abs()), bit);
      g.restore();
    }

    _footer(g);
  }

  /// The pot as the result shows it.
  String subtitlePot = '';

  void _bg(Canvas g, double t) {
    g.drawRect(
      const Rect.fromLTWH(0, 0, W, H),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(W / 2, 900), 1300,
          const [Color(0xFF0E4A1A), C.deep, Color(0xFF021A05)], const [0, 0.55, 1],
          TileMode.clamp, null, const Offset(W / 2, 760), 80,
        ),
    );
    final glow = Paint();
    final clock = t + DrawPlan.countdown;
    for (var i = 0; i < 6; i++) {
      final raw = (i * 211 + clock * 0.02 * (i.isOdd ? 1 : -1));
      final x = (raw % (W + 400) + (W + 400)) % (W + 400) - 200, y = 300.0 + i * 260;
      glow.color = (i.isOdd ? C.sun : C.leaf).withValues(alpha: 0.07);
      g.drawCircle(Offset(x, y), 160.0 + i * 20, glow);
    }
  }

  void _header(Canvas g) {
    _text(g, kicker, W / 2, 150, size: 36, weight: FontWeight.w700, color: C.sun);
    _text(g, title, W / 2, 250, size: 84, weight: FontWeight.w700, heading: true, color: const Color(0xFFFFFFFF));
    _text(g, subtitle, W / 2, 312, size: 38, weight: FontWeight.w600, color: const Color(0xD9DDEEDF));
  }

  void _footer(Canvas g) {
    final at = when;
    _text(g, '${slips.length} names in the bottle. ${at != null ? 'Drawn ${stamp(at)}' : stamp(DateTime.now())}', W / 2, H - 70,
        size: 30, weight: FontWeight.w600, color: const Color(0xB3DDEEDF));
  }

  void _caption(Canvas g, String text, String? small) {
    _text(g, text, W / 2, 1640, size: 52, weight: FontWeight.w700, heading: true, color: const Color(0xFFFFFFFF));
    if (small != null) _text(g, small, W / 2, 1700, size: 34, weight: FontWeight.w600, color: const Color(0xCCDDEEDF));
  }

  void _bottleBack(Canvas g) {
    g.save();
    g.translate(_bx + _box, _by);
    g.rotate(_ba);
    g.scale(_bs, _bs);
    g.drawPath(
      _bottlePath(close: true),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(-_bw / 2, 0), const Offset(_bw / 2, 0),
            const [Color(0x29B4E6C8), Color(0x0DB4E6C8), Color(0x24B4E6C8)], const [0, 0.5, 1]),
    );
    g.restore();
  }

  void _bottleFront(Canvas g, double cork) {
    g.save();
    g.translate(_bx + _box, _by);
    g.rotate(_ba);
    g.scale(_bs, _bs);
    g.drawPath(
      _bottlePath(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0x8CDCF5E6),
    );
    const n = _neckW / 2, nt = -_bh / 2 - _shoulder - _neckH;
    g.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-n - 16, nt - 22, _neckW + 32, 30), const Radius.circular(12)),
        Paint()..color = const Color(0x80DCF5E6));
    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14
      ..color = const Color(0x59FFFFFF);
    g.drawLine(const Offset(-_bw / 2 + 52, -_bh / 2 + 70), const Offset(-_bw / 2 + 52, _bh / 2 - 120), shine);
    shine
      ..strokeWidth = 8
      ..color = const Color(0x2EFFFFFF);
    g.drawLine(const Offset(-_bw / 2 + 84, -_bh / 2 + 90), const Offset(-_bw / 2 + 84, -_bh / 2 + 260), shine);
    if (cork > 0) {
      final cy = nt - 26 - (1 - cork) * 340, ca = (1 - cork) * 1.4;
      g.save();
      g.translate(0, cy);
      g.rotate(ca);
      final alpha = (cork * 1.4).clamp(0.0, 1.0);
      final body = Path()
        ..moveTo(-70, -60)
        ..lineTo(70, -60)
        ..lineTo(58, 70)
        ..lineTo(-58, 70)
        ..close();
      g.drawPath(
        body,
        Paint()
          ..shader = ui.Gradient.linear(const Offset(-60, 0), const Offset(60, 0), [
            const Color(0xFFA7743E).withValues(alpha: alpha),
            const Color(0xFFD6A564).withValues(alpha: alpha),
            const Color(0xFF9A6A36).withValues(alpha: alpha),
          ], const [0, 0.5, 1]),
      );
      final dot = Paint()..color = const Color(0x403C1E0A).withValues(alpha: 0.25 * alpha);
      for (final d in const [Offset(-30, -20), Offset(18, 6), Offset(-6, 40), Offset(34, -36)]) {
        g.drawCircle(d, 5, dot);
      }
      g.restore();
    }
    g.restore();
  }

  void _slipFlat(Canvas g, double x, double y, double w, double h, double rot, _Slip sl, int? letters, double alpha) {
    if (alpha <= 0) return;
    g.save();
    g.translate(x, y);
    g.rotate(rot);
    final shape = RRect.fromRectAndRadius(Rect.fromLTWH(-w / 2, -h / 2, w, h), const Radius.circular(14));
    g.drawRRect(
      shape.shift(const Offset(0, 14)),
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, 0.35 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    g.drawRRect(shape, Paint()..color = sl.hue.withValues(alpha: alpha));
    g.save();
    g.clipRRect(shape);
    final line = Paint()
      ..strokeWidth = 2
      ..color = Color.fromRGBO(36, 89, 43, 0.12 * alpha);
    for (var ly = -h / 2 + 46; ly < h / 2; ly += 40) {
      g.drawLine(Offset(-w / 2, ly), Offset(w / 2, ly), line);
    }
    g.drawLine(Offset(-w / 2 + 80, -h / 2), Offset(-w / 2 + 80, h / 2), line..color = Color.fromRGBO(200, 70, 50, 0.25 * alpha));
    g.restore();
    if (h > 90) {
      g.drawCircle(Offset(-w / 2 + 40, 0), 26, Paint()..color = C.sun.withValues(alpha: alpha));
      _text(g, '${sl.e.slot}', -w / 2 + 40, 2, size: 28, weight: FontWeight.w800, color: C.deep.withValues(alpha: alpha), base: _Base.middle);
    }
    final name = sl.e.name;
    final shown = letters == null ? name : name.substring(0, math.min(letters, name.length));
    final fs = math.min(h * 0.4, (w - 140) / math.max(4, name.length) * 1.75);
    final width = _text(g, shown, -w / 2 + 100, 4,
        size: fs, weight: FontWeight.w700, heading: true, color: C.ink.withValues(alpha: alpha), align: TextAlign.left, base: _Base.middle);
    if (letters != null && letters < name.length) {
      g.drawCircle(Offset(-w / 2 + 100 + width + 8, 10), 7, Paint()..color = C.green.withValues(alpha: alpha));
    }
    g.restore();
  }

  void _slipRolled(Canvas g, double x, double y, double rot, _Slip sl, double scale) {
    final w = 128 * scale, h = 46 * scale;
    g.save();
    g.translate(x, y);
    g.rotate(rot);
    final shape = RRect.fromRectAndRadius(Rect.fromLTWH(-w / 2, -h / 2, w, h), Radius.circular(h / 2));
    g.drawRRect(
      shape,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, -h / 2), Offset(0, h / 2), [const Color(0xFFFFFFFF), sl.hue, const Color(0xFFD9D3BD)], const [0, 0.45, 1]),
    );
    g.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x2E0F2413),
    );
    g.drawOval(Rect.fromCenter(center: Offset(w / 2 - h / 4, 0), width: h / 5 * 2, height: (h / 2 - 2) * 2), Paint()..color = const Color(0x140F2413));
    g.drawRect(Rect.fromLTWH(-7 * scale, -h / 2, 14 * scale, h), Paint()..color = C.sun);
    g.restore();
  }

  /// Draws text the way a canvas does: x is the middle (or left), y the
  /// baseline (or the middle). Returns the width.
  double _text(Canvas g, String text, double x, double y,
      {required double size,
      required FontWeight weight,
      required Color color,
      bool heading = false,
      TextAlign align = TextAlign.center,
      _Base base = _Base.alphabetic}) {
    if (text.isEmpty || size <= 0) return 0;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: heading ? 'Bricolage' : 'Manrope', fontSize: size, fontWeight: weight, color: color, letterSpacing: 0, height: 1),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final dx = align == TextAlign.center ? x - tp.width / 2 : x;
    final dy = base == _Base.middle ? y - tp.height / 2 : y - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(g, Offset(dx, dy));
    final w = tp.width;
    tp.dispose();
    return w;
  }
}

enum _Base { alphabetic, middle }

/// The draw's colours.
class C {
  static const deep = Color(0xFF032A09);
  static const green = Color(0xFF24592B);
  static const leaf = Color(0xFF3E9E58);
  static const sun = Color(0xFFFFD84D);
  static const mint = Color(0xFFDDEEDF);
  static const paper = Color(0xFFFFFDF4);
  static const ink = Color(0xFF0F2413);
  static const peach = Color(0xFFF6E3D5);
}

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _ease(double t) {
  t = _clamp01(t);
  return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
}

double _out(double t) {
  t = _clamp01(t);
  return 1 - math.pow(1 - t, 3).toDouble();
}

double _back(double t) {
  t = _clamp01(t);
  const c = 1.7;
  return 1 + (c + 1) * math.pow(t - 1, 3).toDouble() + c * math.pow(t - 1, 2).toDouble();
}
