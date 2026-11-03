import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Clinical Clarity Palette Architecture
  static const Color primary = Color(0xFF006A43);
  static const Color primaryContainer = Color(0xFF008655);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFF8DF8BD);
  static const Color primaryFixedDim = Color(0xFF71DBA2);
  static const Color onPrimaryFixed = Color(0xFF002112);
  static const Color onPrimaryFixedVariant = Color(0xFF005232);

  // Secondary / High Risk (Bahaya / Tinggi)
  static const Color secondary = Color(0xFFB61722);
  static const Color secondaryContainer = Color(0xFFDA3437);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryFixed = Color(0xFFFFDAD7);
  static const Color secondaryFixedDim = Color(0xFFFFB3AD);

  // Tertiary / Medium Risk (Peringatan / Sedang)
  static const Color tertiary = Color(0xFF825100);
  static const Color tertiaryContainer = Color(0xFFA36700);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryFixed = Color(0xFFFFDDB8);
  static const Color tertiaryFixedDim = Color(0xFFFFB95F);

  // Surfaces & Backgrounds
  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F3FF);
  static const Color surfaceContainer = Color(0xFFE9EDFF);
  static const Color surfaceContainerHigh = Color(0xFFE1E8FD);
  static const Color surfaceContainerHighest = Color(0xFFDCE2F7);

  static const Color onSurface = Color(0xFF141B2B);
  static const Color onSurfaceVariant = Color(0xFF3E4941);
  static const Color outline = Color(0xFF6E7A71);
  static const Color outlineVariant = Color(0xFFBDCABF);

  // Semantic Risks Quick Access
  static const Color riskHighSolid = Color(0xFFEF4444);
  static const Color riskHighContainer = Color(0xFFFEF2F2);
  static const Color riskHighBorder = Color(0xFFFEE2E2);

  static const Color riskMediumSolid = Color(0xFFF59E0B);
  static const Color riskMediumContainer = Color(0xFFFFFBEB);
  static const Color riskMediumBorder = Color(0xFFFEF3C7);

  static const Color riskSafeSolid = Color(0xFF22C55E);
  static const Color riskSafeContainer = Color(0xFFF0FDF4);
  static const Color riskSafeBorder = Color(0xFFDCFCE7);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: Color(0xFFF6FFF6),
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: Color(0xFFFFFBFF),
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: Color(0xFFFFFBFF),
        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 32 / 24,
          letterSpacing: -0.24,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 28 / 20,
          letterSpacing: -0.1,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 24 / 18,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 20 / 14,
          color: onSurface,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 20 / 14,
          color: onSurface,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 16 / 12,
          letterSpacing: 0.24,
          color: onSurface,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 16 / 12,
          color: onSurfaceVariant,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
