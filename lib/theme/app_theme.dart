import 'package:flutter/material.dart';

class AppTheme {
  static const bg = Color(0xFF0D0B1A);
  static const surface = Color(0xFF1A1530);
  static const card = Color(0xFF241D3D);
  static const accent = Color(0xFF6C7BF8);
  static const accentSoft = Color(0xFF8B9CF7);
  static const success = Color(0xFF5EEAD4);
  static const danger = Color(0xFFF87171);
  static const textPrimary = Color(0xFFE8E4F0);
  static const textSecondary = Color(0xFF8B82A8);

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
