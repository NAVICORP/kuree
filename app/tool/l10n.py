#!/usr/bin/env python3
"""Builds lib/l10n/strings.dart from the ARB files in lib/l10n.

The ARB files are the source of every word the app shows. English
(app_en.arb) is the template: every other file must have the same keys and,
for each key, the same {placeholders}. Run from the app folder:

    python3 tool/l10n.py          # check and write strings.dart
    python3 tool/l10n.py --check  # check only (CI); fails if strings.dart is stale
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
L10N = os.path.join(HERE, '..', 'lib', 'l10n')
OUT = os.path.join(L10N, 'strings.dart')

CODES = ['en', 'ar', 'ml', 'ta', 'kn', 'hi']
NAMES = {'en': 'English', 'ar': 'العربية', 'ml': 'മലയാളം', 'ta': 'தமிழ்', 'kn': 'ಕನ್ನಡ', 'hi': 'हिन्दी'}
RTL = {'ar'}

# Keys read through hand-written helpers rather than their own getter.
HELPER = re.compile(r'^(month\d+|monthShort\d+|currency[A-Z]{3}|country_[a-z]{2}|lang_[a-z]{2})$')
# Names the class already uses, and words Dart keeps for itself.
RESERVED = {
    'code', 'isRtl', 'direction', 'monthsLong', 'monthsShort', 'currencyName', 'countryName', 'languageName',
    'table', 'of', 'forCode', 'current', 'delegate', 'codes', 'names', 'show', 'hide', 'late', 'in', 'is', 'new',
    'default', 'switch', 'case', 'class', 'const', 'final', 'var', 'void', 'return', 'get', 'set', 'operator',
}
PLACEHOLDER = re.compile(r'\{([a-zA-Z][a-zA-Z0-9]*)\}')


def load(code):
    with open(os.path.join(L10N, f'app_{code}.arb'), encoding='utf-8') as f:
        data = json.load(f)
    return {k: v for k, v in data.items() if not k.startswith('@')}


def placeholders(text):
    seen = []
    for m in PLACEHOLDER.finditer(text):
        if m.group(1) not in seen:
            seen.append(m.group(1))
    return seen


def check(tables):
    problems = []
    en = tables['en']
    for key in en:
        if not re.match(r'^[a-z][A-Za-z0-9_]*$', key):
            problems.append(f'en: bad key name {key}')
        if key in RESERVED:
            problems.append(f'en: key {key} clashes with a name the class or Dart uses')
    for code, t in tables.items():
        missing = [k for k in en if k not in t]
        extra = [k for k in t if k not in en]
        if missing:
            problems.append(f'{code}: missing {", ".join(missing)}')
        if extra:
            problems.append(f'{code}: not in English {", ".join(extra)}')
        for k, v in t.items():
            if k not in en:
                continue
            if not isinstance(v, str) or not v.strip():
                problems.append(f'{code}.{k}: empty')
                continue
            if sorted(placeholders(v)) != sorted(placeholders(en[k])):
                problems.append(f'{code}.{k}: placeholders {placeholders(v)} but English has {placeholders(en[k])}')
            for bad, why in (('\u2014', 'em dash'), ('\u00b7', 'middle dot'), ('Boystown', 'a name we never show')):
                if bad in v:
                    problems.append(f'{code}.{k}: contains {why}')
            if code == 'en' and re.search(r'\bkuris?\b', v, re.I):
                problems.append(f'en.{k}: says kuri; English says chit')
    return problems


def dart_string(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n') + "'"


def generate(tables):
    en = tables['en']
    out = []
    w = out.append
    w('// Written by tool/l10n.py from lib/l10n/app_*.arb. Do not edit by hand:')
    w('// change the ARB files and run `python3 tool/l10n.py` from the app folder.')
    w('// ignore_for_file: lines_longer_than_80_chars')
    w('')
    w("import 'package:flutter/foundation.dart';")
    w("import 'package:flutter/widgets.dart';")
    w('')
    w('/// Every word the app shows, in one of its six languages.')
    w('class S {')
    w('  S._(this.code, this._t);')
    w('')
    w('  /// "en", "ar", "ml", "ta", "kn" or "hi".')
    w('  final String code;')
    w('  final Map<String, String> _t;')
    w('')
    w('  static const codes = <String>[' + ', '.join(dart_string(c) for c in CODES) + '];')
    w('')
    w('  /// Each language in its own script, for the language picker.')
    w('  static const names = <String, String>{' + ', '.join(f'{dart_string(c)}: {dart_string(NAMES[c])}' for c in CODES) + '};')
    w('')
    w('  static final Map<String, S> _cache = {};')
    w('')
    w('  static S forCode(String code) {')
    w("    final c = codes.contains(code) ? code : 'en';")
    w('    return _cache.putIfAbsent(c, () => S._(c, _tables[c]!));')
    w('  }')
    w('')
    w('  /// The language in use, for code without a BuildContext (messages,')
    w('  /// errors). Kept in step by the delegate and the language picker.')
    w("  static S current = forCode('en');")
    w('')
    w('  static S of(BuildContext context) => Localizations.of<S>(context, S) ?? current;')
    w('')
    w('  static const LocalizationsDelegate<S> delegate = _SDelegate();')
    w('')
    w('  bool get isRtl => ' + ' || '.join(f'code == {dart_string(c)}' for c in sorted(RTL)) + ';')
    w('  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;')
    w('')
    w('  @visibleForTesting')
    w('  static Map<String, String> table(String code) => _tables[code]!;')
    w('')
    w("  String _get(String key) => _t[key] ?? _en[key] ?? key;")
    w('')
    w('  String _fill(String key, Map<String, Object> args) {')
    w('    var s = _get(key);')
    w("    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));")
    w('    return s;')
    w('  }')
    w('')
    w('  /// January to December.')
    w("  late final List<String> monthsLong = [for (var i = 1; i <= 12; i++) _get('month$i')];")
    w('')
    w('  /// Jan to Dec.')
    w("  late final List<String> monthsShort = [for (var i = 1; i <= 12; i++) _get('monthShort$i')];")
    w('')
    w('  /// "Indian rupee" for INR.')
    w("  String currencyName(String code) => _t['currency$code'] ?? _en['currency$code'] ?? code;")
    w('')
    w('  /// "India" for in.')
    w("  String countryName(String iso) => _t['country_$iso'] ?? _en['country_$iso'] ?? iso.toUpperCase();")
    w('')
    w('  /// A language\'s name in this language: "Arabic" for ar.')
    w("  String languageName(String code) => _t['lang_$code'] ?? names[code] ?? code;")
    for key, text in en.items():
        if HELPER.match(key):
            continue
        ps = placeholders(text)
        w('')
        doc = text.replace('\n', ' ').strip()
        w(f'  /// {doc}')
        if not ps:
            w(f'  String get {key} => _get({dart_string(key)});')
        else:
            params = ', '.join(f'Object {p}' for p in ps)
            args = ', '.join(f'{dart_string(p)}: {p}' for p in ps)
            w(f'  String {key}({params}) => _fill({dart_string(key)}, {{{args}}});')
    w('}')
    w('')
    w('class _SDelegate extends LocalizationsDelegate<S> {')
    w('  const _SDelegate();')
    w('')
    w('  @override')
    w('  bool isSupported(Locale locale) => S.codes.contains(locale.languageCode);')
    w('')
    w('  @override')
    w('  Future<S> load(Locale locale) {')
    w('    final s = S.forCode(locale.languageCode);')
    w('    S.current = s;')
    w('    return SynchronousFuture<S>(s);')
    w('  }')
    w('')
    w('  @override')
    w('  bool shouldReload(_SDelegate old) => false;')
    w('}')
    for code in CODES:
        t = tables[code]
        w('')
        w(f'const Map<String, String> _{code} = {{')
        for key in en:
            w(f'  {dart_string(key)}: {dart_string(t[key])},')
        w('};')
    w('')
    w('const Map<String, Map<String, String>> _tables = {' + ', '.join(f'{dart_string(c)}: _{c}' for c in CODES) + '};')
    return '\n'.join(out) + '\n'


def main():
    tables = {c: load(c) for c in CODES}
    problems = check(tables)
    if problems:
        print('\n'.join(problems))
        sys.exit(1)
    text = generate(tables)
    if '--check' in sys.argv:
        with open(OUT, encoding='utf-8') as f:
            if f.read() != text:
                print('lib/l10n/strings.dart is out of date: run python3 tool/l10n.py')
                sys.exit(1)
        print('ok')
        return
    with open(OUT, 'w', encoding='utf-8') as f:
        f.write(text)
    print(f'wrote {OUT} ({len(tables["en"])} keys, {len(CODES)} languages)')


if __name__ == '__main__':
    main()
