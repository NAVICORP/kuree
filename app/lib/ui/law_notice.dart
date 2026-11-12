import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Where the full note on chits and the law lives.
final lawUrl = Uri.parse('https://kureeapp.com/terms#law');

const _seenKey = 'kuree.lawNoticeSeen';

/// Before the first chit on this phone: a short note that chits in India need
/// sanction and registration, and that Kuree only keeps the record. Shown once;
/// after "Got it" it does not come back. Closing it without "Got it" stops the
/// new chit, and the note comes again next time.
Future<bool> lawNoticeOnce(BuildContext context) async {
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seenKey) == true) return true;
  } catch (_) {}
  if (!context.mounted) return false;
  final ok = await showLawNotice(context);
  if (ok) {
    try {
      await prefs?.setBool(_seenKey, true);
    } catch (_) {}
  }
  return ok;
}

/// The note itself, also opened from Profile.
Future<bool> showLawNotice(BuildContext context) async {
  final s = S.of(context);
  final ok = await showKSheet<bool>(
    context,
    title: s.lawTitle,
    builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: K.mint, shape: BoxShape.circle),
          child: const Icon(Icons.gavel_rounded, color: K.green, size: 22),
        ),
        const SizedBox(width: Sp.md + 2),
        Expanded(child: Text(s.lawText, style: T.body.copyWith(color: K.ink2))),
      ]),
      const SizedBox(height: Sp.xl),
      KButton(label: s.lawGotIt, expand: true, onPressed: () => Navigator.of(ctx).pop(true)),
      const SizedBox(height: Sp.sm),
      KButton(
        label: s.lawReadMore,
        icon: Icons.open_in_new_rounded,
        kind: KButtonKind.ghost,
        expand: true,
        onPressed: () => launchUrl(lawUrl, mode: LaunchMode.externalApplication),
      ),
    ]),
  );
  return ok == true;
}
