import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import 'config.dart';

/// Something the server or the network said no to, in words a person can act on.
class ApiError implements Exception {
  ApiError(this.message, {this.status = 0, this.code});
  final String message;
  final int status;
  final String? code;

  /// Another admin saved this kuri after it was loaded here.
  bool get isConflict => status == 409 || code == 'PT409';

  /// The sign-in has ended and the person has to sign in again.
  bool get isSignedOut => status == 401;

  @override
  String toString() => message;
}

/// A signed-in session: the short-lived access token and the refresh token
/// that renews it.
class Session {
  Session({required this.accessToken, required this.refreshToken, required this.expiresAt, required this.user});

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final Map<String, dynamic> user;

  String? get userId => user['id'] as String?;
  String? get email => (user['email'] as String?)?.trim().isEmpty ?? true ? null : user['email'] as String;
  String? get phone => (user['phone'] as String?)?.trim().isEmpty ?? true ? null : user['phone'] as String;

  static Session? fromJson(dynamic j) {
    if (j is! Map) return null;
    final access = j['access_token'];
    final refresh = j['refresh_token'];
    if (access is! String || refresh is! String) return null;
    DateTime expires;
    final at = j['expires_at'];
    final inSec = j['expires_in'];
    if (at is num) {
      expires = DateTime.fromMillisecondsSinceEpoch(at.toInt() * 1000);
    } else if (inSec is num) {
      expires = DateTime.now().add(Duration(seconds: inSec.toInt()));
    } else {
      expires = _jwtExpiry(access) ?? DateTime.now().add(const Duration(minutes: 50));
    }
    final user = j['user'] is Map ? Map<String, dynamic>.from(j['user'] as Map) : <String, dynamic>{};
    return Session(accessToken: access, refreshToken: refresh, expiresAt: expires, user: user);
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.millisecondsSinceEpoch ~/ 1000,
        'user': user,
      };

  static DateTime? _jwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload is Map ? payload['exp'] : null;
      return exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000) : null;
    } catch (_) {
      return null;
    }
  }
}

/// Talks to the Kuree server: sign-in through /auth/v1 (the SkiFi login),
/// and the database functions through /rest/v1/rpc. Holds the session and
/// renews it before it runs out.
class Api {
  Api._();
  static final Api instance = Api._();

  static const _storeKey = 'kuree.session';
  final http.Client _http = http.Client();
  final StreamController<Session?> _changes = StreamController<Session?>.broadcast();
  Session? _session;
  Future<void>? _refreshing;

  /// The signed-in person's name, once the home screen has asked the server.
  String name = '';

  /// For screenshots and tests: every call fails at once, without the network.
  bool offline = false;

  Session? get session => _session;
  bool get signedIn => _session != null;
  Stream<Session?> get changes => _changes.stream;

  /// Picks up the session saved on this phone, if there is one. Reads the
  /// phone only: a session about to run out is renewed in the background,
  /// and the first call to the server waits for that, so a slow network
  /// never holds up the start.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storeKey);
      if (raw == null) return;
      _session = Session.fromJson(jsonDecode(raw));
      if (_session != null && _session!.expiresAt.isBefore(DateTime.now().add(const Duration(seconds: 60)))) {
        unawaited(_refresh().catchError((Object e) async {
          if (e is ApiError && (e.status == 400 || e.status == 401 || e.status == 403 || e.status == 404)) await _setSession(null);
        }));
      }
    } catch (_) {
      _session = null;
    }
  }

  Future<void> _setSession(Session? s) async {
    _session = s;
    if (s == null) {
      name = '';
      unawaited(_forgetKept());
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (s == null) {
        await prefs.remove(_storeKey);
      } else {
        await prefs.setString(_storeKey, jsonEncode(s.toJson()));
      }
    } catch (_) {
      // The session still works for now; it just will not survive a restart.
    }
    _changes.add(s);
  }

  Map<String, String> _headers(bool withUser) => {
        'apikey': 'public',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Client-Info': 'kuree-app/1.0',
        'Authorization': 'Bearer ${withUser && _session != null ? _session!.accessToken : 'public'}',
      };

  Future<void> _fresh() async {
    final s = _session;
    if (s == null) return;
    if (s.expiresAt.isAfter(DateTime.now().add(const Duration(seconds: 60)))) return;
    try {
      await _refresh();
    } on ApiError catch (e) {
      if (e.status == 400 || e.status == 401 || e.status == 403 || e.status == 404) {
        await _setSession(null);
        throw ApiError(S.current.errSessionEnded, status: 401);
      }
      // No signal: carry on with the old token and let the server decide.
    }
  }

  Future<void> _refresh() {
    return _refreshing ??= () async {
      try {
        final j = await _send('POST', '/auth/v1/token', query: {'grant_type': 'refresh_token'},
            body: {'refresh_token': _session!.refreshToken}, withUser: false, retry: false);
        final next = Session.fromJson(j);
        if (next == null) throw ApiError(S.current.errSignInAgain, status: 401);
        await _setSession(next);
      } finally {
        _refreshing = null;
      }
    }();
  }

  Future<dynamic> _send(String method, String path,
      {Object? body, Map<String, String>? query, bool withUser = true, bool retry = true, Duration wait = const Duration(seconds: 30)}) async {
    if (offline) throw ApiError(S.current.errOffline);
    if (withUser) await _fresh();
    final uri = Uri.parse('$kApiBase$path').replace(queryParameters: query);
    http.Response r;
    try {
      final req = http.Request(method, uri)..headers.addAll(_headers(withUser));
      if (body != null) req.body = jsonEncode(body);
      final streamed = await _http.send(req).timeout(wait);
      r = await http.Response.fromStream(streamed).timeout(wait);
    } on TimeoutException {
      throw ApiError(S.current.errTimeout);
    } catch (_) {
      throw ApiError(S.current.errNoConnection);
    }
    final text = utf8.decode(r.bodyBytes, allowMalformed: true);
    dynamic j;
    if (text.isNotEmpty) {
      try {
        j = jsonDecode(text);
      } catch (_) {
        j = null;
      }
    }
    if (r.statusCode >= 200 && r.statusCode < 300) return j;
    // An access token that ran out early: renew once and try again.
    if (r.statusCode == 401 && withUser && retry && _session != null) {
      try {
        await _refresh();
      } on ApiError {
        await _setSession(null);
        throw ApiError(S.current.errSessionEnded, status: 401);
      }
      return _send(method, path, body: body, query: query, withUser: withUser, retry: false, wait: wait);
    }
    throw _error(r.statusCode, j, text);
  }

  static ApiError _error(int status, dynamic j, String text) {
    String raw = '';
    String? code;
    if (j is Map) {
      raw = (j['message'] ?? j['msg'] ?? j['error_description'] ?? j['error'] ?? '').toString();
      code = (j['code'] ?? j['error_code'])?.toString();
    }
    if (raw.isEmpty) raw = status >= 500 ? S.current.errServer : S.current.errStatus(status);
    return ApiError(nice(raw), status: status, code: code);
  }

  /// Server wording, turned into what to do next.
  static String nice(String m) {
    final s = m.toLowerCase();
    final t = S.current;
    if (s.contains('could not send')) return t.errCouldNotSend;
    if (s.contains('rate limit') || s.contains('too many')) return t.errTooMany;
    if ((s.contains('invalid') || s.contains('expired') || s.contains('not right')) &&
        (s.contains('token') || s.contains('otp') || s.contains('code'))) {
      return t.errWrongCode;
    }
    if (s.contains('invalid login credentials')) return t.errPasswordMismatch;
    if (s.contains('email address is invalid')) return t.errEmailLooksWrong;
    if (s.contains('jwt') || s.contains('not signed in')) return t.errSessionEnded;
    return m;
  }

  // ---------------------------------------------------------------- sign in

  Future<void> sendEmailCode(String email) async {
    await _send('POST', '/auth/v1/otp',
        body: {'email': email.trim().toLowerCase(), 'create_user': true, 'data': <String, dynamic>{}}, withUser: false);
  }

  Future<void> verifyEmailCode(String email, String code) async {
    final j = await _send('POST', '/auth/v1/verify',
        body: {'email': email.trim().toLowerCase(), 'token': code.trim(), 'type': 'email'}, withUser: false);
    await _take(j);
  }

  /// For accounts made with a password (the store review account).
  Future<void> signInWithPassword(String email, String password) async {
    final j = await _send('POST', '/auth/v1/token',
        query: {'grant_type': 'password'}, body: {'email': email.trim().toLowerCase(), 'password': password}, withUser: false);
    await _take(j);
  }

  /// Signs in with a token from Google or Apple. [provider] is 'google' or
  /// 'apple'; for Apple, [nonce] is the raw nonce whose SHA-256 went to Apple.
  /// [name] is the name Apple shares on the first sign-in only: it is saved
  /// before the app moves on, so nobody is asked for it again.
  Future<void> signInWithIdToken(String provider, String idToken, {String? nonce, String? name}) async {
    final j = await _send('POST', '/auth/v1/token', query: {'grant_type': 'id_token'}, body: {
      'provider': provider,
      'id_token': idToken,
      if (nonce != null) 'nonce': nonce,
    }, withUser: false);
    final s = Session.fromJson(j);
    if (s == null) throw ApiError(S.current.errSignInNotFinished);
    final n = name?.trim() ?? '';
    if (n.isNotEmpty) {
      _session = s;
      try {
        await rpc('set_my_name', {'name': n});
      } catch (_) {
        // They can still type it in when the app asks.
      }
    }
    await _setSession(s);
  }

  Future<void> _take(dynamic j) async {
    final s = Session.fromJson(j);
    if (s == null) throw ApiError(S.current.errSignInNotFinished);
    await _setSession(s);
  }

  Future<void> signOut() async {
    if (_session != null) {
      try {
        await _send('POST', '/auth/v1/logout', withUser: true, retry: false);
      } catch (_) {
        // Signed out on this phone either way.
      }
    }
    await _setSession(null);
  }

  /// Hands over or deletes this person's kuris and deletes their Kuree
  /// account, then signs out. With [skifiLogin], the SkiFi login itself (the
  /// account they sign in with, shared with other SkiFi apps) is
  /// deleted too; otherwise it stays.
  Future<void> deleteAccount({bool skifiLogin = false}) async {
    await rpc('delete_my_data');
    if (skifiLogin) {
      await _send('DELETE', '/auth/v1/user', retry: false);
      await _setSession(null);
      return;
    }
    await signOut();
  }

  // ---------------------------------------------------------------- database

  Future<dynamic> rpc(String fn, [Map<String, dynamic>? args]) async {
    final body = args ?? const <String, dynamic>{};
    if (!_kept.contains(fn)) return _send('POST', '/rest/v1/rpc/$fn', body: body);
    final key = '$_cachePrefix${_session?.userId ?? ''}:$fn:${jsonEncode(body)}';
    final saved = await _keptAnswer(key);
    try {
      // With a copy on the phone, a slow network is not waited out for long.
      final j = await _send('POST', '/rest/v1/rpc/$fn', body: body, wait: Duration(seconds: saved == null ? 30 : 8));
      showingSaved.value = false;
      unawaited(_keep(key, j));
      return j;
    } on ApiError catch (e) {
      // The server answered: that is the answer. No answer at all (no
      // network, timed out): what this phone kept from last time, if any.
      if (e.status != 0 || saved == null) rethrow;
      showingSaved.value = true;
      return saved;
    }
  }

  // ---------------------------------------------------------------- offline

  /// The reads kept on this phone so the chits open without a network.
  static const _kept = {'my_kuris', 'whoami', 'get_kuri'};
  static const _cachePrefix = 'kuree.saved:';

  /// True while the app shows what was kept on this phone because the
  /// server could not be reached.
  final ValueNotifier<bool> showingSaved = ValueNotifier(false);

  Future<void> _keep(String key, dynamic j) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(j));
    } catch (_) {
      // Not kept; it is only for reading offline.
    }
  }

  Future<dynamic> _keptAnswer(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      return raw == null ? null : jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _forgetKept() async {
    showingSaved.value = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList()) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  /// Calls a server function in supabase/functions.
  Future<dynamic> function(String name, [Map<String, dynamic>? body]) => _send('POST', '/functions/v1/$name', body: body ?? const {});

  /// Downloads a file from the server (the spreadsheet).
  Future<List<int>> download(String url) async {
    try {
      final r = await _http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
      if (r.statusCode != 200) throw ApiError(S.current.errFile, status: r.statusCode);
      return r.bodyBytes;
    } on ApiError {
      rethrow;
    } catch (_) {
      throw ApiError(S.current.errNoConnection);
    }
  }
}
