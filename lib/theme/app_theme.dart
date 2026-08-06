import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0E1117);
  static const Color surface = Color(0xFF161B22);
  static const Color neon = Color(0xFF3DF5C8);
  static const Color neonAlt = Color(0xFF6C8CFF);
  static const Color danger = Color(0xFFFF5C7A);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: neon,
          secondary: neonAlt,
          surface: surface,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      );
}
