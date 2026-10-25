import 'package:flutter/material.dart';

import '../l10n/lang.dart';
import '../l10n/strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// The language picker: the phone's language, or one of the app's six,
/// each written in its own script.
Future<void> pickLanguage(BuildContext context) async {
  final s = S.of(context);
  final picked = await showPicker<String>(
    context,
    title: s.language,
    selected: Lang.instance.chosen ?? '',
    options: [
      PickOption('', s.languagePhone, sub: S.names[Lang.resolve(WidgetsBinding.instance.platformDispatcher.locales).languageCode], icon: Icons.smartphone_rounded),
      for (final c in S.codes) PickOption(c, S.names[c]!, sub: c == s.code ? null : s.languageName(c)),
    ],
  );
  if (picked == null) return;
  await Lang.instance.choose(picked.value.isEmpty ? null : picked.value);
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
      child: Material(
        color: K.surface,
        shape: const StadiumBorder(side: BorderSide(color: K.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
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
    );
  }
}
