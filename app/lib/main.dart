import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/api.dart';
import 'ui/home.dart';
import 'ui/sign_in.dart';
import 'ui/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  await Api.instance.load();
  runApp(const KureeApp());
}

class KureeApp extends StatelessWidget {
  const KureeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuree',
      debugShowCheckedModeBanner: false,
      theme: kureeTheme(),
      navigatorKey: navigatorKey,
      // Text never grows past a size that breaks the cards.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final scale = mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3);
        return MediaQuery(data: mq.copyWith(textScaler: scale), child: child!);
      },
      home: const AuthGate(),
    );
  }
}

/// Signed in: the kuris. Signed out: the sign-in screen.
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
