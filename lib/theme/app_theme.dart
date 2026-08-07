import 'package:flutter/material.dart';

class AppTheme {
  static const bg = Color(0xFF1A1B2E);
  static const surface = Color(0xFF252640);
  static const card = Color(0xFF2D2E4A);
  static const accent = Color(0xFF7C8CF8);
  static const accentSoft = Color(0xFFA5B4FC);
  static const success = Color(0xFF6EE7B7);
  static const danger = Color(0xFFFCA5A5);
  static const textPrimary = Color(0xFFE2E8F0);
  static const textSecondary = Color(0xFF94A3B8);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.dark(
      primary: accent, secondary: accentSoft,
      surface: surface, error: danger, onSurface: textPrimary,
    ),
    cardColor: card,
    appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: textPrimary, elevation: 0),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
