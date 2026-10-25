import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Kuree greens: deep forest green, leaf, sunny yellow, mint, on paper.
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

  /// Corner radii: small chips and fields, cards, big cards and sheets.
  static const rSm = 12.0;
  static const rMd = 16.0;
  static const r = 18.0;
  static const rLg = 24.0;

  static const shadow = [
    BoxShadow(color: Color(0x0A032A09), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1A032A09), blurRadius: 24, spreadRadius: -18, offset: Offset(0, 10)),
  ];
}

/// Fonts for the scripts Manrope and Bricolage do not have: Malayalam, Tamil,
/// Kannada, Hindi (Devanagari) and Arabic. Latin letters and digits stay in
/// Manrope or Bricolage; anything else falls through to these.
const List<String> kFontFallback = ['NotoSansMalayalam', 'NotoSansTamil', 'NotoSansKannada', 'NotoSansDevanagari', 'NotoSansArabic'];

/// Spacing: one scale for paddings and gaps.
class Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;

  /// The side margin of every page.
  static const page = 16.0;
}

/// Text: Manrope for reading, Bricolage Grotesque for titles and big numbers.
/// Kept small and light, so screens read calm rather than loud. No letter
/// spacing anywhere. Line heights leave room for the taller Malayalam, Tamil,
/// Kannada, Hindi and Arabic letters.
class T {
  static const _m = 'Manrope';
  static const _b = 'Bricolage';
  static const _f = kFontFallback;

  static const display = TextStyle(fontFamily: _b, fontFamilyFallback: _f, fontSize: 28, fontWeight: FontWeight.w600, height: 1.14, letterSpacing: 0, color: K.ink);
  static const h1 = TextStyle(fontFamily: _b, fontFamilyFallback: _f, fontSize: 23, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0, color: K.ink);
  static const h2 = TextStyle(fontFamily: _b, fontFamilyFallback: _f, fontSize: 19, fontWeight: FontWeight.w600, height: 1.24, letterSpacing: 0, color: K.ink);
  static const h3 = TextStyle(fontFamily: _b, fontFamilyFallback: _f, fontSize: 16, fontWeight: FontWeight.w600, height: 1.28, letterSpacing: 0, color: K.ink);
  static const amount = TextStyle(fontFamily: _b, fontFamilyFallback: _f, fontSize: 32, fontWeight: FontWeight.w600, height: 1.0, letterSpacing: 0,
      color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]);
  static const body = TextStyle(fontFamily: _m, fontFamilyFallback: _f, fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.45, letterSpacing: 0, color: K.ink);
  static const bodyStrong = TextStyle(fontFamily: _m, fontFamilyFallback: _f, fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.35, letterSpacing: 0, color: K.ink);
  static const small = TextStyle(fontFamily: _m, fontFamilyFallback: _f, fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0, color: K.muted);
  static const tiny = TextStyle(fontFamily: _m, fontFamilyFallback: _f, fontSize: 11, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0, color: K.muted);
  static const label = TextStyle(fontFamily: _m, fontFamilyFallback: _f, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: 0, color: K.ink2);
  static const button = TextStyle(fontFamily: _m, fontFamilyFallback: _f, fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0);
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
      TextStyle(fontFamily: 'Manrope', fontFamilyFallback: kFontFallback, fontSize: size, fontWeight: w, letterSpacing: 0, color: c);
  TextStyle b(double size, FontWeight w) =>
      TextStyle(fontFamily: 'Bricolage', fontFamilyFallback: kFontFallback, fontSize: size, fontWeight: w, letterSpacing: 0, color: K.ink);
  final text = TextTheme(
    displayLarge: b(40, FontWeight.w600),
    displayMedium: b(34, FontWeight.w600),
    displaySmall: b(28, FontWeight.w600),
    headlineLarge: b(25, FontWeight.w600),
    headlineMedium: b(22, FontWeight.w600),
    headlineSmall: b(19, FontWeight.w600),
    titleLarge: b(17, FontWeight.w600),
    titleMedium: m(15, FontWeight.w600),
    titleSmall: m(13.5, FontWeight.w600),
    bodyLarge: m(15, FontWeight.w500),
    bodyMedium: m(14.5, FontWeight.w500),
    bodySmall: m(12.5, FontWeight.w500, K.muted),
    labelLarge: m(14, FontWeight.w600),
    labelMedium: m(12.5, FontWeight.w600),
    labelSmall: m(11, FontWeight.w600),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: K.paper,
    fontFamily: 'Manrope',
    fontFamilyFallback: kFontFallback,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: K.paper,
      foregroundColor: K.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.light),
      titleTextStyle: TextStyle(fontFamily: 'Bricolage', fontFamilyFallback: kFontFallback, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0, color: K.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: K.surface,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: m(14.5, FontWeight.w500, const Color(0xFF8A9A90)),
      labelStyle: m(13.5, FontWeight.w500, K.muted),
      floatingLabelStyle: m(13.5, FontWeight.w600, K.green),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: K.border2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: K.border2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: K.green, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: K.bad)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: K.bad, width: 1.6)),
      errorStyle: m(12, FontWeight.w500, K.bad),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: K.green, selectionColor: K.brand200, selectionHandleColor: K.green),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: K.deep,
      contentTextStyle: m(14, FontWeight.w500, Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    dividerTheme: const DividerThemeData(color: K.border, thickness: 1, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: K.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: K.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.rLg)),
      titleTextStyle: b(18, FontWeight.w600),
      contentTextStyle: m(14.5, FontWeight.w500, K.ink2),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: K.green),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: K.deep, borderRadius: BorderRadius.circular(10)),
      textStyle: m(13, FontWeight.w600, Colors.white),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : K.muted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? K.green : K.surface2),
    ),
    checkboxTheme: CheckboxThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
