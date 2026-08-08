import 'package:flutter/material.dart';

class AppTheme {
  static const bg = Color(0xFF0A0818);
  static const surface = Color(0xFF1C1735);
  static const card = Color(0xFF2A2348);
  static const accent = Color(0xFF7B8CFF);
  static const accentSoft = Color(0xFFA0AEFF);
  static const success = Color(0xFF4ADEAA);
  static const danger = Color(0xFFFF6B6B);
  static const textPrimary = Color(0xFFF8F7FF);
  static const textSecondary = Color(0xFFB8B2D0);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
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
