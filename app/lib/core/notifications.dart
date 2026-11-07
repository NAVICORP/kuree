import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/strings.dart';
import 'api.dart';
import 'config.dart';
import 'kuri.dart';
import 'reminders.dart';

/// Notifications on the phone, both kinds:
///
/// - reminders the phone sets for itself (collection day, the evening before
///   the last day to pay), from the chits as they last loaded, for the next
///   60 days, set again whenever the chits load or the app comes back;
/// - pushes from the Kuree server through Firebase when another admin marks
///   payments, runs the draw or adds you as an admin. Only when the build has
///   the Firebase settings (see config.dart); without them, reminders only.
///
/// One switch (Profile > Reminders) and one permission cover both. The
/// permission is asked only when there is a chit to be reminded about, or
/// from the switch, never on first launch.
class Notifications with WidgetsBindingObserver {
  Notifications._();
  static final Notifications instance = Notifications._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  /// The phone side is ready (false in tests and on other platforms).
  bool _ready = false;

  /// Firebase is set up in this build and started.
  bool _push = false;

  /// True when reminders are on: wanted here and allowed by the phone.
  final ValueNotifier<bool> on = ValueNotifier(false);

  /// The chit a tapped notification asks to open. The home screen opens it
  /// and sets this back to null.
  final ValueNotifier<String?> openChit = ValueNotifier(null);

  List<KuriRecord> _kuris = const [];
  Future<void> _queue = Future.value();
  int _shown = 0;

  static const _wantKey = 'kuree.notify.on';
  static const _askedKey = 'kuree.notify.asked';
  static const _tokenKey = 'kuree.push.token';
  static const _sentKey = 'kuree.push.sent';

  /// Android channels: reminders set on the phone, and pushes from the server
  /// (the server names this one in every message).
  static const remindersChannel = 'reminders';
  static const updatesChannel = 'updates';

  /// Whether this phone can show notifications from Kuree at all.
  bool get available => _ready;

  bool get _android => defaultTargetPlatform == TargetPlatform.android;
  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _iosPlugin =>
      _local.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  /// Starts the notifications. Asks nothing; safe to call once at launch.
  Future<void> init() async {
    if (kIsWeb || !(_android || _ios)) return;
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_kuree'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => _openFrom(r.payload),
      );
      _ready = true;
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) _openFrom(launch!.notificationResponse?.payload);
    } catch (e) {
      debugPrint('notifications: $e');
      _ready = false;
      return;
    }
    if (kPushConfigured) {
      try {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: kFirebaseApiKey,
            appId: kFirebaseAppId,
            messagingSenderId: kFirebaseSenderId,
            projectId: kFirebaseProjectId,
            iosBundleId: kFirebaseIosBundleId.isEmpty ? null : kFirebaseIosBundleId,
          ),
        );
        _push = true;
        FirebaseMessaging.onMessage.listen(_foreground);
        FirebaseMessaging.onMessageOpenedApp.listen((m) => _openFrom(m.data['kuri']?.toString()));
        FirebaseMessaging.instance.onTokenRefresh.listen((t) => _serial(() => _register(t)));
        final first = await FirebaseMessaging.instance.getInitialMessage();
        if (first != null) _openFrom(first.data['kuri']?.toString());
      } catch (e) {
        debugPrint('push: $e');
        _push = false;
      }
    }
    WidgetsBinding.instance.addObserver(this);
    Api.instance.changes.listen((s) {
      if (s == null) _serial(_signedOut);
    });
    await _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone's settings, or a day later: set them again.
    if (state == AppLifecycleState.resumed && Api.instance.signedIn) sync(_kuris);
  }

  void _openFrom(String? kuriId) {
    if (kuriId == null || kuriId.isEmpty) return;
    openChit.value = kuriId;
  }

  /// Runs one change after another, so two quick loads never set the
  /// reminders twice over.
  Future<void> _serial(Future<void> Function() job) {
    final next = _queue.then((_) => job()).catchError((Object e) {
      debugPrint('notifications: $e');
    });
    _queue = next;
    return next;
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _wanted() async => (await _prefs())?.getBool(_wantKey) ?? true;

  Future<bool> _allowed() async {
    if (!_ready) return false;
    try {
      if (_android) return await _androidPlugin?.areNotificationsEnabled() ?? false;
      final p = await _iosPlugin?.checkPermissions();
      return p != null && (p.isEnabled || p.isAlertEnabled || p.isProvisionalEnabled);
    } catch (_) {
      return false;
    }
  }

  Future<void> _refresh() async {
    on.value = _ready && await _wanted() && await _allowed();
  }

  // ---------------------------------------------------------------- the switch and the ask

  /// True when it is a good moment to offer reminders: there is a chit, the
  /// person has not been asked, and the phone does not allow them yet.
  Future<bool> shouldAsk(List<KuriRecord> kuris) async {
    if (!_ready || kuris.isEmpty) return false;
    final prefs = await _prefs();
    if (prefs == null || (prefs.getBool(_askedKey) ?? false)) return false;
    if (!await _wanted()) return false;
    if (await _allowed()) {
      await prefs.setBool(_askedKey, true);
      return false;
    }
    return true;
  }

  /// "Not now" on the offer: not offered again; the switch still works.
  Future<void> declined() async => (await _prefs())?.setBool(_askedKey, true);

  /// Turns reminders on, asking the phone for permission if it has not been
  /// given. False when the phone says no (the person then has to allow it in
  /// the phone's settings).
  Future<bool> turnOn() async {
    if (!_ready) return false;
    final prefs = await _prefs();
    await prefs?.setBool(_askedKey, true);
    var granted = await _allowed();
    if (!granted) {
      try {
        if (_android) {
          granted = await _androidPlugin?.requestNotificationsPermission() ?? false;
        } else {
          granted = await _iosPlugin?.requestPermissions(alert: true, sound: true) ?? false;
        }
      } catch (_) {
        granted = false;
      }
    }
    if (!granted) {
      on.value = false;
      return false;
    }
    await prefs?.setBool(_wantKey, true);
    await sync(_kuris);
    return true;
  }

  /// Turns reminders and pushes off on this phone.
  Future<void> turnOff() async {
    await (await _prefs())?.setBool(_wantKey, false);
    on.value = false;
    await _serial(() async {
      await _cancelScheduled();
      await _pushOff();
    });
  }

  // ---------------------------------------------------------------- setting them

  /// Sets the reminders again from these chits, and keeps this phone's push
  /// address with the server. Called whenever the chits load.
  Future<void> sync(List<KuriRecord> kuris) {
    _kuris = List.of(kuris);
    return _serial(() async {
      await _refresh();
      if (!on.value || !Api.instance.signedIn) {
        await _cancelScheduled();
        if (Api.instance.signedIn) await _pushOff();
        return;
      }
      await _channels();
      await _schedule(_kuris);
      await _pushOn();
    });
  }

  /// How a notification looks; [body] lets a long one open out in full.
  NotificationDetails _details(String channel, {String? body}) {
    final s = S.current;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        channel == remindersChannel ? s.notifChannelReminders : s.notifChannelUpdates,
        icon: 'ic_stat_kuree',
        color: const Color(0xFF24592B),
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: body == null ? null : BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentList: true, presentSound: true),
    );
  }

  /// The two Android channels, named in the app's language (a later call
  /// renames them when the language changes).
  Future<void> _channels() async {
    if (!_android) return;
    final s = S.current;
    final a = _androidPlugin;
    if (a == null) return;
    await a.createNotificationChannel(AndroidNotificationChannel(remindersChannel, s.notifChannelReminders, description: s.notifSub));
    await a.createNotificationChannel(AndroidNotificationChannel(updatesChannel, s.notifChannelUpdates, description: s.notifSub));
  }

  Future<void> _cancelScheduled() async {
    if (!_ready) return;
    try {
      await _local.cancelAllPendingNotifications();
    } catch (_) {}
  }

  Future<void> _schedule(List<KuriRecord> kuris) async {
    await _cancelScheduled();
    final list = planReminders(kuris, DateTime.now());
    for (var i = 0; i < list.length; i++) {
      final r = list[i];
      try {
        await _local.zonedSchedule(
          id: 1000 + i,
          // An exact moment: the phone's own time turned into UTC.
          scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
          notificationDetails: _details(remindersChannel, body: r.body),
          // Inexact: a few minutes late is fine, and it needs no exact alarm
          // permission on Android.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          body: r.body,
          payload: r.kuriId,
        );
      } catch (e) {
        debugPrint('reminder: $e');
      }
    }
  }

  // ---------------------------------------------------------------- push

  void _foreground(RemoteMessage m) {
    // With the app open, the phone shows nothing by itself: show it here.
    final n = m.notification;
    if (n == null || !on.value) return;
    _shown = (_shown + 1) % 900;
    _local.show(
      id: 100 + _shown,
      title: n.title,
      body: n.body,
      notificationDetails: _details(updatesChannel, body: n.body),
      payload: m.data['kuri']?.toString(),
    );
  }

  Future<void> _pushOn() async {
    if (!_push || !Api.instance.signedIn) return;
    try {
      final fm = FirebaseMessaging.instance;
      // Already allowed above, so this shows nothing; it lets Firebase know.
      await fm.requestPermission();
      if (_ios) {
        // The token needs the phone's push address from Apple first.
        for (var i = 0; i < 5 && await fm.getAPNSToken() == null; i++) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      final t = await fm.getToken();
      if (t != null) await _register(t);
    } catch (e) {
      debugPrint('push token: $e');
    }
  }

  /// Tells the server this phone's push address, with the app's language for
  /// the words. Only again when something changed.
  Future<void> _register(String token) async {
    if (!on.value || !Api.instance.signedIn) return;
    final prefs = await _prefs();
    final lang = S.current.code;
    final sent = '$token|$lang|${Api.instance.session?.userId ?? ''}';
    if (prefs?.getString(_sentKey) == sent) return;
    try {
      await Api.instance.rpc('register_push_device', {'token': token, 'platform': _android ? 'android' : 'ios', 'lang': lang});
      await prefs?.setString(_tokenKey, token);
      await prefs?.setString(_sentKey, sent);
    } on ApiError catch (e) {
      // An older server without push: try again on the next load.
      debugPrint('push register: ${e.message}');
    }
  }

  /// Tells the server to stop sending to this phone. Works signed out too:
  /// the address itself is the proof.
  Future<void> _pushOff() async {
    final prefs = await _prefs();
    final token = prefs?.getString(_tokenKey);
    if (token == null) return;
    try {
      await Api.instance.rpc('forget_push_device', {'token': token});
      await prefs?.remove(_tokenKey);
      await prefs?.remove(_sentKey);
    } on ApiError catch (e) {
      debugPrint('push forget: ${e.message}');
    }
  }

  /// Signed out, or the account deleted: nothing more for this phone.
  Future<void> _signedOut() async {
    _kuris = const [];
    on.value = false;
    if (!_ready) return;
    try {
      await _local.cancelAll();
    } catch (_) {}
    await _pushOff();
    if (_push) {
      try {
        // A new address for whoever signs in next.
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}
    }
  }
}
