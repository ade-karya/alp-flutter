import 'package:flutter/material.dart';
import 'app_themes.dart';
import 'wizard_background.dart';
import 'forest_background.dart';

/// Helper class for theme-aware styling
class ThemeHelper {
  /// Returns the appropriate magical background widget based on theme
  static Widget wrapWithBackground(AppThemeMode mode, Widget child) {
    switch (mode) {
      case AppThemeMode.wizard:
        return WizardBackground(child: child);
      case AppThemeMode.forest:
        return ForestBackground(child: child);
    }
  }

  /// Gets accent color for the current theme (primary highlight color)
  static Color getAccentColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return const Color(0xFFD4AF37); // Muted Gold for night
      case AppThemeMode.forest:
        return const Color(0xFF2E7D32); // Deep Forest Green for day
    }
  }

  /// Gets secondary accent color for the current theme
  static Color getSecondaryAccentColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return const Color(0xFF7B1FA2); // Muted Purple
      case AppThemeMode.forest:
        return const Color(0xFF66BB6A); // Fresh Green
    }
  }

  /// Gets the card background color
  static Color getCardColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return const Color(0xFF0D0D18).withValues(alpha: 0.85);
      case AppThemeMode.forest:
        return const Color(0xFFFFFFFF); // White cards for light mode
    }
  }

  /// Gets the text color for headings
  static Color getHeadingColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return const Color(0xFFE0E0E0); // Dimmed white for night
      case AppThemeMode.forest:
        return const Color(0xFF1B5E20); // Deepest Green for day
    }
  }

  /// Gets the text color for body text
  static Color getBodyColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return const Color(0xFFB0B0B0); // Dimmed for night
      case AppThemeMode.forest:
        return const Color(0xFF33691E); // Dark green-gray for day
    }
  }

  /// Gets the subtle text color
  static Color getSubtleColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return const Color(0xFF808080); // Muted gray for night
      case AppThemeMode.forest:
        return const Color(0xFF558B2F); // Medium moss green for day
    }
  }

  /// Gets the border color for cards and containers
  static Color getBorderColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return const Color(0xFF2A2A40);
      case AppThemeMode.forest:
        return const Color(0xFFA5D6A7); // Light green border
    }
  }

  /// Gets the dialog background color
  static Color getDialogColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return const Color(0xFF0A0A15);
      case AppThemeMode.forest:
        return Colors.white; // Pure white
    }
  }
}
