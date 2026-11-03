import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Liquid glass, after Apple's 2025 design language: a see-through layer that
/// floats over the app, blurs what passes under it, and catches the light
/// along its rim.
///
/// It belongs to the navigation layer only: the footer, the add button,
/// header buttons, the choice pills, action bars and sheets. Lists, cards and
/// amounts stay solid, so names and money always read clearly. With Increase
/// contrast turned on, every glass surface becomes a plain solid one.
enum GlassTone {
  /// Frosted white with a hint of mint, for controls on the light pages.
  light,

  /// Deep green glass with white on it, for the main action (the add button,
  /// the chosen choice pill).
  green,

  /// Clear glass for controls on the deep green month card and the draw.
  dark,

  /// A mint drop inside other glass: the chosen footer tab.
  mint,

  /// Thick frosted glass for sheets, so their text reads as clearly as a page.
  sheet,
}

/// True when glass should give way to solid surfaces.
bool glassOff(BuildContext context) => MediaQuery.highContrastOf(context);

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 999,
    this.borderRadius,
    this.tone = GlassTone.light,
    this.blur = 0,
    this.shadow = true,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;

  /// The corner radius; 999 makes a capsule or a circle.
  final double radius;

  /// Corners that differ, such as a sheet's rounded top. Wins over [radius].
  final BorderRadius? borderRadius;
  final GlassTone tone;

  /// How much of what is behind is blurred. 0 for glass that sits on a plain
  /// page (nothing moves under it), so it costs nothing to draw.
  final double blur;
  final bool shadow;
  final EdgeInsetsGeometry padding;

  static List<Color> _fill(GlassTone tone) => switch (tone) {
        GlassTone.light => const [Color(0xD9FFFFFF), Color(0xA3F1F8F2), Color(0xBDFFFFFF)],
        GlassTone.green => const [Color(0xF2357A47), Color(0xF21E5A2D), Color(0xF70A3512)],
        GlassTone.dark => const [Color(0x2EFFFFFF), Color(0x14FFFFFF), Color(0x1FFFFFFF)],
        GlassTone.mint => const [Color(0xF5EEF8F0), Color(0xE6D3EBD9), Color(0xEDE4F2E7)],
        GlassTone.sheet => const [Color(0xF5FDFEFB), Color(0xEBF4F8F1), Color(0xF2FAFBF6)],
      };

  static Color _solid(GlassTone tone) => switch (tone) {
        GlassTone.light => K.surface,
        GlassTone.green => K.deep,
        GlassTone.dark => const Color(0x26FFFFFF),
        GlassTone.mint => K.brand100,
        GlassTone.sheet => K.paper,
      };

  @override
  Widget build(BuildContext context) {
    final off = glassOff(context);
    final r = borderRadius ?? BorderRadius.circular(radius);
    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        color: off ? _solid(tone) : null,
        border: off && (tone == GlassTone.light || tone == GlassTone.mint) ? Border.all(color: K.border2) : null,
        gradient: off
            ? null
            : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _fill(tone), stops: const [0, 0.55, 1]),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (!off) body = CustomPaint(foregroundPainter: _GlassRim(r, tone), child: body);
    if (!off && blur > 0) {
      body = BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: body);
    }
    body = ClipRRect(borderRadius: r, child: body);
    if (shadow) body = CustomPaint(painter: _GlassShadow(r, tone, strong: blur > 0), child: body);
    return body;
  }
}

/// The light along the rim: bright at the top left where the light comes
/// from, faint along the sides, and a second, softer catch at the bottom
/// right where it bends through. A sheen across the top half gives the glass
/// its thickness.
class _GlassRim extends CustomPainter {
  _GlassRim(this.radius, this.tone);
  final BorderRadius radius;
  final GlassTone tone;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = radius.toRRect(rect);
    final (top, side, low, sheen) = switch (tone) {
      GlassTone.light => (0.95, 0.30, 0.70, 0.55),
      GlassTone.green => (0.62, 0.10, 0.34, 0.24),
      GlassTone.dark => (0.55, 0.08, 0.28, 0.16),
      GlassTone.mint => (0.95, 0.35, 0.60, 0.50),
      GlassTone.sheet => (1.0, 0.0, 0.0, 0.0),
    };
    const white = Colors.white;
    // The sheen: a soft white wash over the top half, gone by the middle.
    final top55 = Rect.fromLTWH(0, 0, size.width, size.height * 0.55);
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      top55,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [white.withValues(alpha: sheen), white.withValues(alpha: 0)],
        ).createShader(top55),
    );
    canvas.restore();
    // The rim.
    canvas.drawRRect(
      rr.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [white.withValues(alpha: top), white.withValues(alpha: side), white.withValues(alpha: low)],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassRim old) => old.radius != radius || old.tone != tone;
}

/// A soft shadow drawn only outside the glass, so it never greys the glass.
class _GlassShadow extends CustomPainter {
  _GlassShadow(this.radius, this.tone, {required this.strong});
  final BorderRadius radius;
  final GlassTone tone;
  final bool strong;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = radius.toRRect(rect);
    final green = tone == GlassTone.green;
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(80))
      ..addRRect(rr));
    canvas.drawRRect(
      rr.shift(Offset(0, strong ? 10 : 4)),
      Paint()
        ..color = K.deep.withValues(alpha: green ? 0.30 : (strong ? 0.16 : 0.08))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strong ? 18 : 8),
    );
    canvas.drawRRect(
      rr.shift(const Offset(0, 1)),
      Paint()
        ..color = K.deep.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassShadow old) => old.radius != radius || old.tone != tone || old.strong != strong;
}

/// Only the light on glass (rim and sheen), for buttons that keep their own
/// solid colour, such as Save: it makes them read as polished glass.
class GlassRim extends StatelessWidget {
  const GlassRim({super.key, required this.child, this.tone = GlassTone.dark, this.radius = 999});
  final Widget child;
  final GlassTone tone;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (glassOff(context)) return child;
    return CustomPaint(foregroundPainter: _GlassRim(BorderRadius.circular(radius), tone), child: child);
  }
}

/// The give of glass under a finger: it sinks a little while pressed and
/// springs back with a small bounce when let go.
class GlassPress extends StatefulWidget {
  const GlassPress({super.key, required this.child, this.onTap, this.label, this.depth = 0.92});
  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  final double depth;

  @override
  State<GlassPress> createState() => _GlassPressState();
}

class _GlassPressState extends State<GlassPress> {
  bool down = false;

  void _set(bool v) {
    if (widget.onTap == null || down == v) return;
    setState(() => down = v);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: down && !still ? widget.depth : 1,
          duration: Duration(milliseconds: down ? 90 : 420),
          curve: down ? Curves.easeOut : Curves.elasticOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// The add button as deep green glass: it floats over the list, and the list
/// shows through it, blurred, as it scrolls past. With a [label] it is a
/// capsule with the icon and the words, like "New chit".
class GlassFab extends StatelessWidget {
  const GlassFab({super.key, required this.icon, required this.onPressed, this.label, this.tooltip});
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final words = label;
    final face = Glass(
      tone: GlassTone.green,
      blur: 16,
      padding: words == null ? EdgeInsets.zero : const EdgeInsetsDirectional.fromSTEB(16, 0, 20, 0),
      child: SizedBox(
        width: words == null ? 56 : null,
        height: 52,
        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 22, color: Colors.white),
          if (words != null) ...[
            const SizedBox(width: 8),
            Text(words, style: T.button.copyWith(color: Colors.white)),
          ],
        ]),
      ),
    );
    final button = GlassPress(label: words == null ? tooltip : null, onTap: onPressed, depth: 0.92, child: face);
    return tooltip == null ? button : Tooltip(message: tooltip!, excludeFromSemantics: words != null, child: button);
  }
}

/// A bar of actions (Save, Undo) that floats over the bottom of a screen as a
/// glass capsule, with the page running underneath it. It keeps clear of the
/// footer and the phone's home bar.
class GlassBar extends StatelessWidget {
  const GlassBar({super.key, required this.child, this.padding = const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 6, 12, (bottom > 0 ? bottom : 12) + 2),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Glass(radius: 28, blur: 22, padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The arrow at the top left of a screen (and the cross that closes one) as
/// a small glass circle, matching the other header buttons.
class GlassHeaderIcon extends StatelessWidget {
  const GlassHeaderIcon({super.key, this.close = false});
  final bool close;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final icon = close ? Icons.close_rounded : (rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded);
    return SizedBox(
      width: 34,
      height: 34,
      child: Glass(child: Center(child: Icon(icon, size: close ? 18 : 22, color: K.ink))),
    );
  }
}

/// Soft light behind glass that has little colour under it, such as the
/// sign-in screen: greens, mint and a touch of sun, blurred into the page.
class AmbientLight extends StatelessWidget {
  const AmbientLight({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (glassOff(context)) return ColoredBox(color: K.paper, child: child);
    return CustomPaint(painter: _Ambient(), child: child);
  }
}

class _Ambient extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = K.paper);
    void blob(Offset c, double r, Color colour) {
      canvas.drawCircle(
        c,
        r,
        Paint()..shader = RadialGradient(colors: [colour, colour.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final m = math.max(size.width, size.height);
    blob(Offset(size.width * 0.1, size.height * 0.08), m * 0.42, K.brand300.withValues(alpha: 0.40));
    blob(Offset(size.width * 0.95, size.height * 0.2), m * 0.30, K.sun.withValues(alpha: 0.30));
    blob(Offset(size.width * 0.85, size.height * 0.9), m * 0.38, K.leaf.withValues(alpha: 0.26));
    blob(Offset(size.width * 0.05, size.height * 0.75), m * 0.28, K.mint.withValues(alpha: 0.70));
  }

  @override
  bool shouldRepaint(_Ambient old) => false;
}
