import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api.dart';
import 'core/notifications.dart';
import 'l10n/lang.dart';
import 'l10n/strings.dart';
import 'ui/home.dart';
import 'ui/launch.dart';
import 'ui/sign_in.dart';
import 'ui/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Says once when the app falls back to what this phone kept, because the
/// server could not be reached.
void _sayWhenOffline() {
  if (!Api.instance.showingSaved.value) return;
  messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(S.current.offlineSaved)),
      ]),
      backgroundColor: K.deep,
      duration: const Duration(seconds: 4),
    ));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones stay upright; tablets turn freely.
  final view = PlatformDispatcher.instance.views.first;
  final shortest = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortest < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: K.paper,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  // The card for the loading screen's first frame, where the launch screen had it.
  await LaunchScreen.prepare();
  await Future.wait([Api.instance.load(), Lang.instance.load()]);
  Api.instance.showingSaved.addListener(_sayWhenOffline);
  runApp(const KureeApp());
  // Reminders and pushes start alongside the first screen, so they never hold
  // the launch screen. Asks nothing here; a tapped notification is picked up
  // through Notifications.openChit whenever it arrives.
  unawaited(Notifications.instance.init());
}

class KureeApp extends StatelessWidget {
  const KureeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The language follows the phone, unless one was picked in the app.
    return ListenableBuilder(
      listenable: Lang.instance,
      builder: (context, _) => MaterialApp(
        title: 'Kuree',
        debugShowCheckedModeBanner: false,
        theme: kureeTheme(),
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: messengerKey,
        locale: Lang.instance.locale,
        supportedLocales: [for (final c in S.codes) Locale(c)],
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeListResolutionCallback: (phone, _) => Lang.resolve(phone),
        // Text never grows past a size that breaks the cards.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          final scale = mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3);
          return MediaQuery(data: mq.copyWith(textScaler: scale), child: child!);
        },
        // The loading screen restores the session and loads the chits first.
        home: const LaunchScreen(child: AuthGate()),
      ),
    );
  }
}

/// Signed in: the chits. Signed out: the sign-in screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late StreamSubscription<Session?> _sub;
  bool _signedIn = Api.instance.signedIn;

  @override
  void initState() {
    super.initState();
    _sub = Api.instance.changes.listen((s) {
      final now = s != null;
      if (now == _signedIn) return;
      // Signing out closes everything that was open.
      if (!now) navigatorKey.currentState?.popUntil((r) => r.isFirst);
      setState(() => _signedIn = now);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _signedIn ? const HomeScreen(key: ValueKey('home')) : const SignInScreen(key: ValueKey('signin')),
    );
  }
}
