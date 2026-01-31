import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Only two theme modes: Wizard (dark purple/gold) and Forest (dark green)
enum AppThemeMode { wizard, forest }

class AppThemes {
  /// Wizard Theme - Night mode for low light/dark environments
  /// Optimized for minimal eye strain in dark conditions
  static final ThemeData wizard = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6A0DAD), // Deeper purple
      brightness: Brightness.dark,
      primary: const Color(0xFFD4AF37), // Muted gold - easier on eyes at night
      secondary: const Color(0xFF7B1FA2), // Muted purple
      surface: const Color(0xFF0A0A12), // Very dark surface
      onSurface: const Color(0xFFE0E0E0), // Slightly dimmed white
    ),
    textTheme: GoogleFonts.cinzelTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyMedium: GoogleFonts.lato(
        color: const Color(0xFFB0B0B0),
      ), // Dimmed text
      bodyLarge: GoogleFonts.lato(
        color: const Color(0xFFD0D0D0),
      ), // Slightly dimmed
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFD4AF37), // Muted gold
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF0D0D18).withValues(alpha: 0.85), // Very dark card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
        ), // Subtle border
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5E35B1), // Muted purple button
        foregroundColor: const Color(0xFFE0E0E0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.cinzel(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        elevation: 4, // Reduced elevation for darker feel
        shadowColor: const Color(0xFF4A148C).withValues(alpha: 0.3),
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFF050510), // Very dark background
    iconTheme: const IconThemeData(
      color: Color(0xFFD4AF37),
    ), // Muted gold icons
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0A0A15).withValues(alpha: 0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A40)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A40)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
    ),
  );

  /// Forest Theme - Fresh & Modern daylight theme
  /// Vibrant colors optimized for bright outdoor use
  static final ThemeData forest = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32), // Deep Forest Green
      brightness: Brightness.light,
      primary: const Color(0xFF2E7D32), // Deep Green - strong primary
      secondary: const Color(0xFF66BB6A), // Fresh Green - vibrant secondary
      tertiary: const Color(0xFFFFA000), // Amber - warm sun accent
      surface: const Color(0xFFFFFFFF), // Pure white
      onSurface: const Color(0xFF1B5E20), // Dark green-black text
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme)
        .copyWith(
          bodyMedium: GoogleFonts.poppins(
            color: const Color(0xFF33691E), // Dark green-gray
            fontWeight: FontWeight.w400,
          ),
          bodyLarge: GoogleFonts.poppins(
            color: const Color(0xFF1B5E20), // Deepest green
            fontWeight: FontWeight.w500,
          ),
          headlineMedium: GoogleFonts.poppins(
            color: const Color(0xFF1B5E20), // Deep Forest Green
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.poppins(
            color: const Color(0xFF2E7D32), // Primary Green
            fontWeight: FontWeight.w600,
          ),
          titleMedium: GoogleFonts.poppins(
            color: const Color(0xFF33691E),
            fontWeight: FontWeight.w500,
          ),
          labelLarge: GoogleFonts.poppins(
            color: const Color(0xFF1B5E20),
            fontWeight: FontWeight.w500,
          ),
        ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1B5E20), // Deepest Green
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
      color: const Color(0xFFFFFFFF),
      surfaceTintColor: const Color(0xFFF1F8E9), // Slight green tint on cards
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32), // Deep Green
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        elevation: 6,
        shadowColor: const Color(0xFF1B5E20).withValues(alpha: 0.4),
      ),
    ),
    scaffoldBackgroundColor: const Color(
      0xFFF1F8E9,
    ), // Lightest Green background
    iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFFA000), // Amber accent for action
      foregroundColor: Color(0xFF3E2723), // Dark brown icon on amber
      elevation: 6,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFA5D6A7),
        ), // Light green border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFA5D6A7),
        ), // Light green border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF2E7D32),
          width: 2,
        ), // Deep green focus
      ),
      labelStyle: const TextStyle(color: Color(0xFF558B2F)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: const Color(0xFFF1F8E9),
      selectedIconTheme: const IconThemeData(
        color: Color(0xFF2E7D32),
        size: 32,
      ),
      unselectedIconTheme: IconThemeData(
        color: const Color(0xFF33691E).withValues(alpha: 0.6),
      ),
      selectedLabelTextStyle: const TextStyle(
        color: Color(0xFF2E7D32),
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: const Color(0xFF33691E).withValues(alpha: 0.6),
      ),
      indicatorColor: const Color(
        0xFFA5D6A7,
      ).withValues(alpha: 0.5), // Soft selection bg
    ),
  );

  /// Get theme by mode
  static ThemeData getTheme(AppThemeMode mode) {
    return mode == AppThemeMode.wizard ? wizard : forest;
  }
}
