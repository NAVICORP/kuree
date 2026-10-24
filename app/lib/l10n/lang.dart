import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

/// The language the person picked in the app, or none to follow the phone.
class Lang extends ChangeNotifier {
  Lang._();
  static final Lang instance = Lang._();
  static const _key = 'kuree.lang';

  String? _code;

  /// The picked language code, or null when the app follows the phone.
  String? get chosen => _code;

  /// The locale to force, or null to follow the phone.
  Locale? get locale => _code == null ? null : Locale(_code!);

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final c = p.getString(_key);
      _code = c != null && S.codes.contains(c) ? c : null;
    } catch (_) {
      _code = null;
    }
    if (_code != null) S.current = S.forCode(_code!);
  }

  /// Picks a language, or follows the phone again with null. Remembered on
  /// this phone.
  Future<void> choose(String? code) async {
    _code = code != null && S.codes.contains(code) ? code : null;
    S.current = S.forCode(_code ?? resolve(WidgetsBinding.instance.platformDispatcher.locales).languageCode);
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      if (_code == null) {
        await p.remove(_key);
      } else {
        await p.setString(_key, _code!);
      }
    } catch (_) {
      // Not remembered this time; the app still switches now.
    }
  }

  /// The first of the phone's languages the app speaks, or English.
  static Locale resolve(List<Locale>? phone) {
    for (final l in phone ?? const <Locale>[]) {
      if (S.codes.contains(l.languageCode)) return Locale(l.languageCode);
    }
    return const Locale('en');
  }
}
