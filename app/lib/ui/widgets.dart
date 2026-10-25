import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
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
    final h = small ? 40.0 : 46.0;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        else if (icon != null)
          Icon(icon, size: small ? 16 : 18, color: fg),
        if (busy || icon != null) SizedBox(width: small ? 6 : 8),
        // A long label (Malayalam runs long) shrinks a little to fit
        // rather than losing its end.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, textAlign: TextAlign.center, style: T.button.copyWith(color: fg, fontSize: small ? 13.5 : 14.5)),
          ),
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
            padding: EdgeInsets.symmetric(horizontal: small ? 14 : 18),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A white card with a hairline border and a soft shadow.
class KCard extends StatelessWidget {
  const KCard({super.key, required this.child, this.padding = const EdgeInsets.all(Sp.lg), this.onTap, this.color = K.surface});
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
  const HeroCard({super.key, required this.child, this.padding = const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 18)});
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
          PositionedDirectional(
            end: -120,
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
          PositionedDirectional(
            start: -90,
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
  const SlotBadge(this.text, {super.key, this.size = 34, this.style = SlotBadgeStyle.plain});
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
          style: TextStyle(
                  fontFamily: 'Manrope',
                  fontFamilyFallback: kFontFallback,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.34,
                  height: 1.1,
                  color: fg,
                  letterSpacing: 0)
              .merge(T.tabular)),
    );
  }
}

enum SlotBadgeStyle { plain, paid, winner, sun }

/// A small rounded label, as wide as its words.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = K.brand100, this.fg = K.brand600, this.icon});
  final String text;
  final Color color;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
        Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.tiny.copyWith(color: fg))),
      ]),
    );
  }
}

/// A thin progress line that fills from the start side.
class ProgressLine extends StatelessWidget {
  const ProgressLine(this.value, {super.key, this.color = K.sun, this.track = const Color(0x24FFFFFF), this.height = 8});
  final double value;
  final Color color;
  final Color track;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth.isFinite ? c.maxWidth : 200.0;
      return ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Container(
          width: w,
          height: height,
          color: track,
          alignment: AlignmentDirectional.centerStart,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            width: w * value.clamp(0, 1).toDouble(),
            height: height,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height)),
          ),
        ),
      );
    });
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
          Semantics(
            button: true,
            selected: v == value,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 40),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: v == value ? K.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: v == value ? const [BoxShadow(color: Color(0x1A032A09), blurRadius: 6, offset: Offset(0, 2))] : null,
                ),
                child: Text(label, style: T.label.copyWith(color: v == value ? K.deep : K.muted)),
              ),
            ),
          ),
      ]),
    );
  }
}

/// A round icon button on dark or light backgrounds. The circle can be
/// small, but the place to tap is always at least 48 across.
class RoundIcon extends StatelessWidget {
  const RoundIcon(this.icon, {super.key, this.onTap, this.dark = false, this.tooltip, this.size = 36});
  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tap = math.max(48.0, size);
    final circle = Opacity(
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
    final w = Semantics(
      button: true,
      enabled: onTap != null,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: tap, height: tap, child: Center(child: circle)),
      ),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, excludeFromSemantics: true, child: w);
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: Sp.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: K.brand100, borderRadius: BorderRadius.circular(K.rMd + 2)),
          child: Icon(icon, color: K.green, size: 24),
        ),
        const SizedBox(height: Sp.md + 2),
        Text(text, textAlign: TextAlign.center, style: T.body.copyWith(color: K.muted)),
        if (action != null) ...[const SizedBox(height: Sp.lg), action!],
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
    final fg = bad ? K.bad : K.brand600;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 11, 14, 11),
      decoration: BoxDecoration(color: bad ? K.badBg : K.brand100, borderRadius: BorderRadius.circular(K.rSm)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(bad ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, size: 18, color: fg),
        ),
        const SizedBox(width: Sp.sm),
        Expanded(child: Text(text, style: T.small.copyWith(color: fg))),
      ]),
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
      padding: const EdgeInsetsDirectional.fromSTEB(4, 20, 4, 8),
      child: Row(children: [
        Expanded(child: Text(text, style: T.h3)),
        if (trailing != null) ...[const SizedBox(width: Sp.sm), trailing!],
      ]),
    );
  }
}

/// A row that opens a choice: a small label, the value, and a chevron.
class KChoice extends StatelessWidget {
  const KChoice({super.key, required this.label, required this.value, required this.onTap, this.icon});
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, color: K.ink2, size: 20), const SizedBox(width: 12)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: T.small),
              const SizedBox(height: 2),
              Text(value, style: T.bodyStrong),
            ]),
          ),
          const SizedBox(width: Sp.sm),
          const Icon(Icons.expand_more_rounded, color: K.muted),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- sheets and dialogs

/// A rounded sheet from the bottom with a title and a close button. It opens
/// over the whole app, the footer too, from any tab.
Future<R?> showKSheet<R>(BuildContext context, {required String title, required Widget Function(BuildContext) builder, bool scroll = true}) {
  return showModalBottomSheet<R>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: K.paper,
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      final pad = EdgeInsets.fromLTRB(Sp.xl, Sp.sm, Sp.xl, Sp.xxl + media.padding.bottom);
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 10),
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: K.border2, borderRadius: BorderRadius.circular(5)))),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(22, 10, 8, 4),
              child: Row(children: [
                Expanded(child: Text(title, style: T.h2)),
                RoundIcon(Icons.close_rounded, tooltip: S.of(ctx).close, onTap: () => Navigator.of(ctx).pop(), size: 34),
              ]),
            ),
            Flexible(
              child: scroll ? SingleChildScrollView(padding: pad, child: builder(ctx)) : Padding(padding: pad, child: builder(ctx)),
            ),
          ]),
        ),
      );
    },
  );
}

class PickOption<V> {
  const PickOption(this.value, this.label, {this.sub, this.badge, this.icon, this.trailing});
  final V value;
  final String label;
  final String? sub;
  final String? badge;
  final IconData? icon;

  /// A short tag at the end, like a currency symbol.
  final String? trailing;
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
            padding: const EdgeInsets.only(bottom: Sp.sm),
            child: Material(
              color: o.value == selected ? K.brand100 : K.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(K.rMd),
                side: BorderSide(color: o.value == selected ? K.brand200 : K.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(o),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
                  child: Row(children: [
                    if (o.badge != null) ...[SlotBadge(o.badge!, size: 32), const SizedBox(width: Sp.md)],
                    if (o.icon != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: K.surface2, shape: BoxShape.circle),
                        child: Icon(o.icon, size: 17, color: K.ink2),
                      ),
                      const SizedBox(width: Sp.md),
                    ],
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(o.label, style: T.bodyStrong),
                        if (o.sub != null) Text(o.sub!, style: T.small),
                      ]),
                    ),
                    if (o.trailing != null) ...[
                      const SizedBox(width: Sp.sm),
                      Text(o.trailing!, style: T.label.copyWith(color: K.muted)),
                    ],
                    if (o.value == selected) ...[const SizedBox(width: Sp.sm), const Icon(Icons.check_rounded, color: K.green)],
                  ]),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, {required String title, required String text, String? yes, String? no, bool danger = false}) async {
  final s = S.of(context);
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actionsPadding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.lg),
      actions: [
        KButton(label: no ?? s.cancel, kind: KButtonKind.ghost, small: true, onPressed: () => Navigator.of(ctx).pop(false)),
        KButton(label: yes ?? s.yes, kind: danger ? KButtonKind.danger : KButtonKind.primary, small: true, onPressed: () => Navigator.of(ctx).pop(true)),
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
/// One tab in the footer: its icon (outlined, and filled when chosen) and name.
class KNavItem {
  const KNavItem(this.icon, this.iconOn, this.label);
  final IconData icon;
  final IconData iconOn;
  final String label;
}

/// The footer with the app's main tabs: the chosen one sits in a soft green
/// pill, like the other SkiFi apps.
class KNavBar extends StatelessWidget {
  const KNavBar({super.key, required this.items, required this.index, required this.onTap});
  final List<KNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  static const double _bar = 64;

  /// How much of the screen the footer takes above the phone's own bottom
  /// inset: the bar and the line along its top.
  static const double height = _bar + 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: K.surface, border: Border(top: BorderSide(color: K.border))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _bar,
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == index,
                  label: items[i].label,
                  child: InkWell(
                    onTap: () {
                      if (i != index) HapticFeedback.selectionClick();
                      onTap(i);
                    },
                    child: ExcludeSemantics(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 30,
                          decoration: BoxDecoration(color: i == index ? K.brand100 : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                          child: Icon(i == index ? items[i].iconOn : items[i].icon, size: 22, color: i == index ? K.brand600 : K.muted),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(items[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: T.tiny.copyWith(fontSize: 12, color: i == index ? K.ink : K.muted, fontWeight: i == index ? FontWeight.w700 : FontWeight.w600)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

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
        action: KButton(label: S.of(context).tryAgain, icon: Icons.refresh_rounded, kind: KButtonKind.secondary, onPressed: onRetry),
      ),
    );
  }
}
