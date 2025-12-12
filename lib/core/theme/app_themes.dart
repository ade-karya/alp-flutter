import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { serious, playful }

class AppThemes {
  static final ThemeData serious = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2C3E50), // Navy Blue
      brightness: Brightness.light,
      primary: const Color(0xFF2C3E50),
      secondary: const Color(0xFF95A5A6),
      tertiary: const Color(0xFFBDC3C7),
    ),
    textTheme: GoogleFonts.robotoTextTheme(),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Color(0xFF2C3E50),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
  );

  static final ThemeData playful = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF9F43), // Orange
      brightness: Brightness.light,
      primary: const Color(0xFFFF9F43),
      secondary: const Color(0xFF54a0ff), // Blue
      tertiary: const Color(0xFF1dd1a1), // Green
    ),
    textTheme: GoogleFonts.comicNeueTextTheme(),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFFFF9F43),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFFFEF9E7),
  );
}
