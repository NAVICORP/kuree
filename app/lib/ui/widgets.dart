import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

enum KButtonKind { primary, secondary, ghost, danger, sun }

/// A rounded button sized to its label (or full width when asked).
class KButton extends StatelessWidget {
  const KButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = KButtonKind.primary,
    this.busy = false,
    this.expand = false,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final KButtonKind kind;
  final bool busy;
  final bool expand;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, side) = switch (kind) {
      KButtonKind.primary => (K.deep, Colors.white, BorderSide.none),
      KButtonKind.secondary => (K.surface, K.deep, const BorderSide(color: K.border2)),
      KButtonKind.ghost => (Colors.transparent, K.green, BorderSide.none),
      KButtonKind.danger => (K.badBg, K.bad, BorderSide.none),
      KButtonKind.sun => (K.sun, K.deep, BorderSide.none),
    };
    final enabled = onPressed != null && !busy;
    final h = small ? 40.0 : 52.0;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        else if (icon != null)
          Icon(icon, size: small ? 17 : 20, color: fg),
        if (busy || icon != null) SizedBox(width: small ? 6 : 8),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.button.copyWith(color: fg, fontSize: small ? 14 : 15.5)),
        ),
      ],
    );
    return Opacity(
      opacity: enabled || busy ? 1 : 0.45,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: side),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                }
              : null,
          child: Container(
            height: h,
            padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A white card with a hairline border and a soft shadow.
class KCard extends StatelessWidget {
  const KCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap, this.color = K.surface});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(K.r),
        border: Border.all(color: K.border),
        boxShadow: K.shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(K.r),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? Padding(padding: padding, child: child) : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// The deep green card at the top of a month.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(K.rLg),
        color: K.deep,
        boxShadow: const [BoxShadow(color: Color(0xBF032A09), blurRadius: 40, spreadRadius: -22, offset: Offset(0, 18))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -120,
            top: -110,
            child: Container(
              width: 320,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x477FD18F), Color(0x007FD18F)]),
              ),
            ),
          ),
          Positioned(
            left: -90,
            bottom: -120,
            child: Container(
              width: 260,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x1FCFE8D6), Color(0x00CFE8D6)]),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// A slot number in a circle.
class SlotBadge extends StatelessWidget {
  const SlotBadge(this.text, {super.key, this.size = 42, this.style = SlotBadgeStyle.plain});
  final String text;
  final double size;
  final SlotBadgeStyle style;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (style) {
      SlotBadgeStyle.plain => (K.surface2, K.ink2, K.border),
      SlotBadgeStyle.paid => (K.brand100, K.brand600, K.brand200),
      SlotBadgeStyle.winner => (K.deep, K.heroText, K.deep),
      SlotBadgeStyle.sun => (K.sun, K.deep, K.sun),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: border)),
      child: Text(text,
          style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, fontSize: size * 0.34, color: fg, letterSpacing: 0)
              .merge(T.tabular)),
    );
  }
}

enum SlotBadgeStyle { plain, paid, winner, sun }

/// A small rounded label.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = K.brand100, this.fg = K.brand600, this.icon});
  final String text;
  final Color color;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12.5, color: fg), const SizedBox(width: 4)],
        Text(text, style: T.tiny.copyWith(color: fg)),
      ]),
    );
  }
}

/// A thin progress line.
class ProgressLine extends StatelessWidget {
  const ProgressLine(this.value, {super.key, this.color = K.sun, this.track = const Color(0x24FFFFFF), this.height = 8});
  final double value;
  final Color color;
  final Color track;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(children: [
          Positioned.fill(child: ColoredBox(color: track)),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1).toDouble(),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, t, __) => Opacity(opacity: t, child: ColoredBox(color: color, child: SizedBox(height: height))),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Choices in a rounded pill: All 14, To pay 6, Paid 8.
class KSegmented<V> extends StatelessWidget {
  const KSegmented({super.key, required this.items, required this.value, required this.onChanged});
  final List<(V, String)> items;
  final V value;
  final ValueChanged<V> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: K.surface2, borderRadius: BorderRadius.circular(999), border: Border.all(color: K.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final (v, label) in items)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: v == value ? K.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: v == value ? const [BoxShadow(color: Color(0x1A032A09), blurRadius: 6, offset: Offset(0, 2))] : null,
              ),
              child: Text(label, style: T.label.copyWith(color: v == value ? K.deep : K.muted, fontSize: 13.5)),
            ),
          ),
      ]),
    );
  }
}

/// A round icon button on dark or light backgrounds.
class RoundIcon extends StatelessWidget {
  const RoundIcon(this.icon, {super.key, this.onTap, this.dark = false, this.tooltip, this.size = 40});
  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final w = Opacity(
      opacity: onTap == null ? 0.3 : 1,
      child: Material(
        color: dark ? const Color(0x1AFFFFFF) : K.surface,
        shape: CircleBorder(side: dark ? BorderSide.none : const BorderSide(color: K.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Icon(icon, size: size * 0.5, color: dark ? K.heroText : K.ink)),
        ),
      ),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: K.surface2, borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, color: K.muted, size: 26),
        ),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center, style: T.body.copyWith(color: K.muted)),
        if (action != null) ...[const SizedBox(height: 14), action!],
      ]),
    );
  }
}

/// A message under a form, in red or calm green.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.bad = true});
  final String text;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: bad ? K.badBg : K.brand100, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: T.small.copyWith(color: bad ? K.bad : K.brand600, fontSize: 13.5)),
    );
  }
}

/// A title row for a section.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(children: [
        Expanded(child: Text(text, style: T.h3)),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

// ---------------------------------------------------------------- sheets and dialogs

/// A rounded sheet from the bottom with a title and a close button.
Future<R?> showKSheet<R>(BuildContext context, {required String title, required Widget Function(BuildContext) builder, bool scroll = true}) {
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: K.paper,
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 10),
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: K.border2, borderRadius: BorderRadius.circular(5)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 12, 6),
              child: Row(children: [
                Expanded(child: Text(title, style: T.h2)),
                RoundIcon(Icons.close_rounded, onTap: () => Navigator.of(ctx).pop(), size: 38),
              ]),
            ),
            Flexible(
              child: scroll
                  ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: builder(ctx))
                  : Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: builder(ctx)),
            ),
          ]),
        ),
      );
    },
  );
}

class PickOption<V> {
  const PickOption(this.value, this.label, {this.sub, this.badge, this.icon});
  final V value;
  final String label;
  final String? sub;
  final String? badge;
  final IconData? icon;
}

/// A list to choose from, in a rounded sheet (instead of a dropdown).
Future<PickOption<V>?> showPicker<V>(BuildContext context,
    {required String title, required List<PickOption<V>> options, V? selected}) {
  return showKSheet<PickOption<V>>(
    context,
    title: title,
    builder: (ctx) => Column(
      children: [
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: o.value == selected ? K.brand100 : K.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: o.value == selected ? K.brand200 : K.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(o),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    if (o.badge != null) ...[SlotBadge(o.badge!, size: 38), const SizedBox(width: 12)],
                    if (o.icon != null) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(color: K.surface2, shape: BoxShape.circle),
                        child: Icon(o.icon, size: 19, color: K.ink2),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(o.label, style: T.bodyStrong),
                        if (o.sub != null) Text(o.sub!, style: T.small),
                      ]),
                    ),
                    if (o.value == selected) const Icon(Icons.check_rounded, color: K.green),
                  ]),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, {required String title, required String text, String yes = 'Yes', String no = 'Cancel', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        KButton(label: no, kind: KButtonKind.ghost, small: true, onPressed: () => Navigator.of(ctx).pop(false)),
        KButton(label: yes, kind: danger ? KButtonKind.danger : KButtonKind.primary, small: true, onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String text, {bool bad = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(text),
    backgroundColor: bad ? K.bad : K.deep,
    duration: Duration(milliseconds: bad ? 4500 : 2800),
  ));
}

/// A full-screen spinner while something loads.
class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)));
}

/// Something did not load: what happened, and a way to try again.
class LoadFailed extends StatelessWidget {
  const LoadFailed({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.wifi_off_rounded,
        text: message,
        action: KButton(label: 'Try again', icon: Icons.refresh_rounded, kind: KButtonKind.secondary, onPressed: onRetry),
      ),
    );
  }
}
