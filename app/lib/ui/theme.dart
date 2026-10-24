import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Boystown greens: deep forest green, leaf, sunny yellow, mint, on paper.
class K {
  static const deep = Color(0xFF032A09);
  static const green = Color(0xFF24592B);
  static const leaf = Color(0xFF3E9E58);
  static const sun = Color(0xFFFFD84D);
  static const mint = Color(0xFFDDEEDF);
  static const paper = Color(0xFFFAFAF5);
  static const paperWarm = Color(0xFFFFFDF4);
  static const frame = Color(0xFFECEFE6);
  static const ink = Color(0xFF0F2413);
  static const ink2 = Color(0xFF33443A);
  static const muted = Color(0xFF53665B);
  static const border = Color(0xFFE1E8E3);
  static const border2 = Color(0xFFC9D6CD);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF1F5F2);
  static const brand100 = Color(0xFFE4F1E8);
  static const brand200 = Color(0xFFC5E0CB);
  static const brand300 = Color(0xFF7FC194);
  static const brand500 = Color(0xFF1C7F38);
  static const brand600 = Color(0xFF116326);
  static const heroText = Color(0xFFCFE8D6);
  static const bad = Color(0xFF9E3226);
  static const badBg = Color(0xFFF8E5E2);
  static const warn = Color(0xFF8A5D0B);
  static const warnBg = Color(0xFFF8EFDC);
  static const sunSoft = Color(0xFFFBF0B8);

  static const r = 22.0;
  static const rLg = 28.0;

  static const shadow = [
    BoxShadow(color: Color(0x0D032A09), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x2E032A09), blurRadius: 30, spreadRadius: -18, offset: Offset(0, 12)),
  ];
}

/// Text: Manrope for reading, Bricolage Grotesque for titles and big numbers.
/// No letter spacing anywhere.
class T {
  static const _m = 'Manrope';
  static const _b = 'Bricolage';

  static const display = TextStyle(fontFamily: _b, fontSize: 34, fontWeight: FontWeight.w700, height: 1.05, letterSpacing: 0, color: K.ink);
  static const h1 = TextStyle(fontFamily: _b, fontSize: 28, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: 0, color: K.ink);
  static const h2 = TextStyle(fontFamily: _b, fontSize: 22, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: 0, color: K.ink);
  static const h3 = TextStyle(fontFamily: _b, fontSize: 18, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: 0, color: K.ink);
  static const amount = TextStyle(fontFamily: _b, fontSize: 40, fontWeight: FontWeight.w700, height: 1.0, letterSpacing: 0,
      color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]);
  static const body = TextStyle(fontFamily: _m, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0, color: K.ink);
  static const bodyStrong = TextStyle(fontFamily: _m, fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: 0, color: K.ink);
  static const small = TextStyle(fontFamily: _m, fontSize: 13, fontWeight: FontWeight.w600, height: 1.35, letterSpacing: 0, color: K.muted);
  static const tiny = TextStyle(fontFamily: _m, fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: 0, color: K.muted);
  static const label = TextStyle(fontFamily: _m, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: 0, color: K.ink2);
  static const button = TextStyle(fontFamily: _m, fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: 0);
  static const tabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
}

ThemeData kureeTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: K.deep,
    onPrimary: Colors.white,
    secondary: K.green,
    onSecondary: Colors.white,
    tertiary: K.sun,
    onTertiary: K.deep,
    error: K.bad,
    onError: Colors.white,
    surface: K.paper,
    onSurface: K.ink,
    surfaceContainerHighest: K.surface2,
    outline: K.border2,
    outlineVariant: K.border,
  );
  TextStyle m(double size, FontWeight w, [Color c = K.ink]) =>
      TextStyle(fontFamily: 'Manrope', fontSize: size, fontWeight: w, letterSpacing: 0, color: c);
  TextStyle b(double size, FontWeight w) =>
      TextStyle(fontFamily: 'Bricolage', fontSize: size, fontWeight: w, letterSpacing: 0, color: K.ink);
  final text = TextTheme(
    displayLarge: b(48, FontWeight.w700),
    displayMedium: b(40, FontWeight.w700),
    displaySmall: b(34, FontWeight.w700),
    headlineLarge: b(30, FontWeight.w700),
    headlineMedium: b(26, FontWeight.w700),
    headlineSmall: b(22, FontWeight.w700),
    titleLarge: b(20, FontWeight.w700),
    titleMedium: m(16, FontWeight.w700),
    titleSmall: m(14, FontWeight.w700),
    bodyLarge: m(16, FontWeight.w500),
    bodyMedium: m(15, FontWeight.w500),
    bodySmall: m(13, FontWeight.w600, K.muted),
    labelLarge: m(15, FontWeight.w700),
    labelMedium: m(13, FontWeight.w700),
    labelSmall: m(11.5, FontWeight.w700),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: K.paper,
    fontFamily: 'Manrope',
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: K.paper,
      foregroundColor: K.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.light),
      titleTextStyle: TextStyle(fontFamily: 'Bricolage', fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0, color: K.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: K.surface,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: m(15, FontWeight.w500, const Color(0xFF8A9A90)),
      labelStyle: m(14, FontWeight.w600, K.muted),
      floatingLabelStyle: m(14, FontWeight.w700, K.green),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: K.border2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: K.border2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: K.green, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: K.bad)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: K.bad, width: 2)),
      errorStyle: m(12.5, FontWeight.w600, K.bad),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: K.green, selectionColor: K.brand200, selectionHandleColor: K.green),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: K.deep,
      contentTextStyle: m(14.5, FontWeight.w600, Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    dividerTheme: const DividerThemeData(color: K.border, thickness: 1, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: K.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: K.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      titleTextStyle: b(21, FontWeight.w700),
      contentTextStyle: m(15, FontWeight.w500, K.ink2),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: K.green),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
