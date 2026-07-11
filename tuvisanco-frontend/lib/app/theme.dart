import 'package:flutter/material.dart';

class AppTheme {
  // Brand color palette from FootballAI Figma Spec
  static const Color background = Color(0xFF0D0E18);
  static const Color surface = Color(0xFF1A1C2E);
  static const Color surfaceElevated = Color(0xFF252740);
  static const Color surfaceBorder = Color(0xFF2E3150);
  static const Color primary = Color(0xFF4361EE);
  static const Color primaryDark = Color(0xFF3A0CA3);
  static const Color accentPurple = Color(0xFF7209B7);
  static const Color accentPink = Color(0xFFF72585);
  static const Color success = Color(0xFF2DC653);
  static const Color warning = Color(0xFFF4A261);
  static const Color error = Color(0xFFE63946);
  static const Color neutral = Color(0xFF6C757D);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3C6);
  static const Color textDisabled = Color(0xFF6B6F8A);

  // Spacing Tokens
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;
  static const double spacing2xl = 32.0;
  static const double spacing3xl = 48.0;

  // Radius Tokens
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // Dark Theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryDark,
        error: error,
        surface: surface,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: background,
          disabledBackgroundColor: textDisabled.withOpacity(0.4),
          disabledForegroundColor: textDisabled,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: surfaceBorder),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 28, color: textPrimary),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 20, color: textPrimary),
        titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 18, color: textPrimary),
        titleMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 16, color: textSecondary),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.normal, fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.normal, fontSize: 12, color: textSecondary),
        labelLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
        labelSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 11, color: textSecondary),
      ),
    );
  }

  // Light Theme (Fallbacks to dark layout since UI is primarily dark themed)
  static ThemeData get lightTheme => darkTheme;
}
