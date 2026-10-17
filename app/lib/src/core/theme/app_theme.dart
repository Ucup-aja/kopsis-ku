import 'package:flutter/material.dart';

/// Tema KopsisKu — biru + abu (slate).
///
/// Light: latar slate-100, kartu putih, aksen blue-600.
/// Dark: latar slate-950/900, kartu slate-800, aksen blue-400.
class AppTheme {
  // Brand
  static const primary = Color(0xFF2563EB); // blue-600
  static const primaryDark = Color(0xFF1D4ED8); // blue-700
  static const primaryLight = Color(0xFFDBEAFE); // blue-100
  static const primarySoft = Color(0xFFEFF6FF); // blue-50
  static const accent = Color(0xFF38BDF8); // sky-400

  // Light (abu kebiruan)
  static const bg = Color(0xFFF1F5F9); // slate-100
  static const bg2 = Color(0xFFE2E8F0); // slate-200
  static const card = Colors.white;
  static const textDark = Color(0xFF0F172A); // slate-900
  static const textBody = Color(0xFF334155); // slate-700
  static const textMuted = Color(0xFF64748B); // slate-500
  static const border = Color(0xFFE2E8F0); // slate-200
  static const borderSoft = Color(0xFFF1F5F9);

  // Status
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
  static const restok = Color(0xFF7C3AED);

  // Dark (slate)
  static const darkBg = Color(0xFF0F172A); // slate-900
  static const darkBg2 = Color(0xFF020617); // slate-950
  static const darkCard = Color(0xFF1E293B); // slate-800
  static const darkCard2 = Color(0xFF273449);
  static const darkBorder = Color(0xFF334155); // slate-700
  static const darkText = Color(0xFFF1F5F9); // slate-100
  static const darkMuted = Color(0xFF94A3B8); // slate-400
  static const darkPrimary = Color(0xFF60A5FA); // blue-400

  static const double rSm = 12;
  static const double rMd = 16;
  static const double rLg = 20;
  static const double rXl = 28;

  static List<BoxShadow> shadowSm = [
    BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 2)),
    BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 24,
        offset: const Offset(0, 8)),
  ];

  static BoxDecoration cardDecoration({
    bool dark = false,
    double radius = rMd,
    Color? color,
  }) =>
      BoxDecoration(
        color: color ?? (dark ? darkCard : card),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: dark ? darkBorder : border),
        boxShadow: dark ? [] : shadowSm,
      );

  /// Gradient hero biru -> slate.
  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const heroGradientDark = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: bg,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4),
      iconTheme: IconThemeData(color: textDark),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
          side: const BorderSide(color: border)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm),
          borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm),
          borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm),
          borderSide: const BorderSide(color: primary, width: 1.6)),
      labelStyle:
          const TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 13),
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      prefixIconColor: textMuted,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        textStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: border),
      backgroundColor: card,
      labelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: primaryLight,
      labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: card,
      indicatorColor: primaryLight,
      selectedIconTheme: IconThemeData(color: primary),
      unselectedIconTheme: IconThemeData(color: textMuted),
      selectedLabelTextStyle:
          TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelTextStyle:
          TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 12),
    ),
    dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rLg))),
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: textDark,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
      actionTextColor: accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: darkPrimary,
      surface: darkBg,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4),
      iconTheme: IconThemeData(color: darkText),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
          side: const BorderSide(color: darkBorder)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm),
          borderSide: const BorderSide(color: darkBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm),
          borderSide: const BorderSide(color: darkBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm),
          borderSide: const BorderSide(color: darkPrimary, width: 1.6)),
      labelStyle:
          const TextStyle(color: darkMuted, fontWeight: FontWeight.w600, fontSize: 13),
      hintStyle: const TextStyle(color: darkMuted, fontSize: 13),
      prefixIconColor: darkMuted,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        textStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: darkBorder),
      backgroundColor: darkCard,
      labelStyle: const TextStyle(color: darkText, fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkCard,
      indicatorColor: const Color(0xFF1E3A5F),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(
          fontSize: 11.5, fontWeight: FontWeight.w700, color: darkText)),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: darkCard,
      indicatorColor: Color(0xFF1E3A5F),
      selectedIconTheme: IconThemeData(color: darkPrimary),
      unselectedIconTheme: IconThemeData(color: darkMuted),
      selectedLabelTextStyle:
          TextStyle(color: darkText, fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelTextStyle:
          TextStyle(color: darkMuted, fontWeight: FontWeight.w600, fontSize: 12),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rLg)),
    ),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 1),
    iconTheme: const IconThemeData(color: darkText),
    textTheme: ThemeData.dark().textTheme.apply(bodyColor: darkText, displayColor: darkText),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: darkCard2,
      contentTextStyle: const TextStyle(color: darkText, fontSize: 13.5),
      actionTextColor: darkPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: darkBorder),
      ),
    ),
  );
}
