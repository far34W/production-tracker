// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand colours — industrial steel-blue palette
  static const Color primary       = Color(0xFF0D47A1);
  static const Color primaryLight  = Color(0xFF1565C0);
  static const Color primaryDark   = Color(0xFF002171);
  static const Color accent        = Color(0xFF00ACC1);
  static const Color success       = Color(0xFF2E7D32);
  static const Color warning       = Color(0xFFF57F17);
  static const Color danger        = Color(0xFFC62828);
  static const Color surface       = Color(0xFFF4F6FA);
  static const Color dayColor      = Color(0xFF1565C0);
  static const Color nightColor    = Color(0xFF4527A0);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
    ),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
  );
}
