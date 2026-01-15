import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Only two theme modes: Wizard (dark purple/gold) and Forest (dark green)
enum AppThemeMode { wizard, forest }

class AppThemes {
  /// Wizard Theme - Magical dark purple with gold accents and stars
  static final ThemeData wizard = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF9C27B0),
      brightness: Brightness.dark,
      primary: const Color(0xFFFFD700), // Gold
      secondary: const Color(0xFF9C27B0), // Purple
      surface: Colors.black.withValues(alpha: 0.6),
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.cinzelTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyMedium: GoogleFonts.lato(color: Colors.white70),
      bodyLarge: GoogleFonts.lato(color: Colors.white),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFFFD700),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.cinzel(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        elevation: 8,
        shadowColor: const Color(0xFF9C27B0).withValues(alpha: 0.5),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0C29),
    iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
  );

  /// Forest Theme - Enchanted dark green with fireflies
  static final ThemeData forest = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D5A27),
      brightness: Brightness.dark,
      primary: const Color(0xFF81C784), // Light Green
      secondary: const Color(0xFF4CAF50), // Green
      surface: const Color(0xFF1B3D1B).withValues(alpha: 0.9),
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.merriweatherTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          bodyMedium: GoogleFonts.lato(color: Colors.white70),
          bodyLarge: GoogleFonts.lato(color: Colors.white),
          headlineMedium: GoogleFonts.merriweather(
            color: const Color(0xFF81C784),
            fontWeight: FontWeight.bold,
          ),
        ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF81C784),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1B3D1B).withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.merriweather(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        elevation: 8,
        shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.5),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFF0D260D),
    iconTheme: const IconThemeData(color: Color(0xFF81C784)),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF4CAF50),
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1B3D1B).withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF81C784), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF81C784)),
    ),
  );

  /// Get theme by mode
  static ThemeData getTheme(AppThemeMode mode) {
    return mode == AppThemeMode.wizard ? wizard : forest;
  }
}
