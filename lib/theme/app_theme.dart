import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0E1117);
  static const Color surface = Color(0xFF161B22);
  static const Color neon = Color(0xFF3DF5C8);
  static const Color neonAlt = Color(0xFF6C8CFF);
  static const Color danger = Color(0xFFFF5C7A);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.dark(
          primary: neon,
          secondary: neonAlt,
          surface: surface,
          error: danger,
        ),
        cardColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: neon,
            foregroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}
