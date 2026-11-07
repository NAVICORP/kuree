import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Country codes for members' WhatsApp numbers (for reminders), with flags
/// as pictures (Windows and some Android phones show flag emoji as two
/// letters). The English names
/// are a fallback; the list shows them in the app's language.
const kCountries = <(String, String, String)>[
  ('91', 'in', 'India'),
  ('971', 'ae', 'UAE'),
  ('966', 'sa', 'Saudi Arabia'),
  ('974', 'qa', 'Qatar'),
  ('965', 'kw', 'Kuwait'),
  ('968', 'om', 'Oman'),
  ('973', 'bh', 'Bahrain'),
  ('1', 'us', 'United States'),
  ('44', 'gb', 'United Kingdom'),
  ('61', 'au', 'Australia'),
  ('65', 'sg', 'Singapore'),
  ('60', 'my', 'Malaysia'),
  ('49', 'de', 'Germany'),
];

(String, String, String) countryOf(String code) => kCountries.firstWhere((c) => c.$1 == code, orElse: () => kCountries.first);

/// A number typed after a country code, as digits with the code. Someone who
/// types their own +44 overrides the picker.
String fullPhone(String cc, String raw) {
  final t = raw.trim();
  final own = t.startsWith('+') || t.startsWith('00');
  var d = t.replaceAll(RegExp(r'[^0-9]'), '');
  if (t.startsWith('00')) d = d.substring(2);
  if (!own) d = cc + d.replaceFirst(RegExp(r'^0+'), '');
  return d.length >= 8 && d.length <= 15 ? d : '';
}

/// The country code button: a flag and +91, opening a list.
class CountryButton extends StatelessWidget {
  const CountryButton({super.key, required this.code, required this.onChanged});
  final String code;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = countryOf(code);
    return Material(
      color: K.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rMd), side: const BorderSide(color: K.border2)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final picked = await showPicker<String>(
            context,
            title: s.countryCode,
            selected: code,
            options: [for (final x in kCountries) PickOption(x.$1, s.countryName(x.$2), sub: '+${x.$1}')],
          );
          if (picked != null) onChanged(picked.value);
        },
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset('assets/flags/${c.$2}.png', width: 22, height: 16, fit: BoxFit.cover),
              ),
              const SizedBox(width: Sp.sm),
              Text('+${c.$1}', textDirection: TextDirection.ltr, style: T.bodyStrong),
              const Icon(Icons.expand_more_rounded, size: 20, color: K.muted),
            ]),
          ),
        ),
      ),
    );
  }
}
