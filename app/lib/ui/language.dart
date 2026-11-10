import 'package:flutter/material.dart';

import '../l10n/lang.dart';
import '../l10n/strings.dart';
import 'glass.dart';
import 'theme.dart';
import 'widgets.dart';

/// The language picker: the phone's language across the top, then the
/// app's six in a grid of two a row, each written in its own script with
/// its name in the app's language under it.
Future<void> pickLanguage(BuildContext context) async {
  final s = S.of(context);
  final selected = Lang.instance.chosen ?? '';
  final phone = S.names[Lang.resolve(WidgetsBinding.instance.platformDispatcher.locales).languageCode];
  final picked = await showKSheet<String>(
    context,
    title: s.language,
    builder: (ctx) {
      Widget tile(String code, {required Widget child, double height = 84}) {
        final on = code == selected;
        return Material(
          color: on ? K.brand100 : K.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(K.rMd),
            side: BorderSide(color: on ? K.brand200 : K.border, width: on ? 1.5 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(ctx).pop(code),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 10),
                child: Row(children: [
                  Expanded(child: child),
                  if (on) const Icon(Icons.check_circle_rounded, color: K.green, size: 22),
                ]),
              ),
            ),
          ),
        );
      }

      Widget lang(String c) {
        final native = S.names[c]!, local = s.languageName(c);
        return tile(
          c,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(native, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.h3),
            if (local != native) ...[
              const SizedBox(height: 2),
              Text(local, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.small),
            ],
          ]),
        );
      }

      final codes = S.codes.toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        tile(
          '',
          height: 64,
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: K.surface2, shape: BoxShape.circle),
              child: const Icon(Icons.smartphone_rounded, size: 18, color: K.ink2),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.languagePhone, style: T.bodyStrong),
                if (phone != null) Text(phone, style: T.small),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: Sp.md),
        for (var i = 0; i < codes.length; i += 2) ...[
          if (i > 0) const SizedBox(height: Sp.sm + 2),
          Row(children: [
            Expanded(child: lang(codes[i])),
            const SizedBox(width: Sp.sm + 2),
            Expanded(child: i + 1 < codes.length ? lang(codes[i + 1]) : const SizedBox()),
          ]),
        ],
      ]);
    },
  );
  if (picked == null) return;
  await Lang.instance.choose(picked.isEmpty ? null : picked);
}

/// The language as a small rounded button, for the sign-in screen.
class LanguageChip extends StatelessWidget {
  const LanguageChip({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Semantics(
      button: true,
      label: s.language,
      child: Glass(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => pickLanguage(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 10, 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.translate_rounded, size: 18, color: K.green),
                  const SizedBox(width: Sp.sm),
                  Text(S.names[s.code]!, style: T.label.copyWith(color: K.ink)),
                  const SizedBox(width: 2),
                  const Icon(Icons.expand_more_rounded, size: 18, color: K.muted),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
