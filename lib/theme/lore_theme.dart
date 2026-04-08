import 'package:flutter/material.dart';

class LoreTheme {
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF171728);
  static const Color surfaceLight = Color(0xFF202038);
  static const Color parchment = Color(0xFFD4C5A9);
  static const Color ink = Color(0xFF2C1810);
  static const Color gold = Color(0xFFD4A017);
  static const Color ruby = Color(0xFFC62828);
  static const Color sapphire = Color(0xFF1565C0);
  static const Color emerald = Color(0xFF2E7D32);
  static const Color amethyst = Color(0xFF6A1B9A);
  static const Color textPrimary = Color(0xFFE0DDD5);
  static const Color textSecondary = Color(0xFF8A8878);
  static const Color divider = Color(0xFF2A2A40);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: parchment,
          surface: surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: parchment,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        useMaterial3: true,
      );
}
