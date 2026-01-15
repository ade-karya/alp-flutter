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
        return const Color(0xFFFFD700); // Gold
      case AppThemeMode.forest:
        return const Color(0xFF81C784); // Light Green
    }
  }

  /// Gets secondary accent color for the current theme
  static Color getSecondaryAccentColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return const Color(0xFF9C27B0); // Purple
      case AppThemeMode.forest:
        return const Color(0xFF4CAF50); // Green
    }
  }

  /// Gets the card background color
  static Color getCardColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return Colors.black.withValues(alpha: 0.5);
      case AppThemeMode.forest:
        return const Color(0xFF1B3D1B).withValues(alpha: 0.7);
    }
  }

  /// Gets the text color for headings
  static Color getHeadingColor(AppThemeMode mode) {
    return Colors.white;
  }

  /// Gets the text color for body text
  static Color getBodyColor(AppThemeMode mode) {
    return Colors.white70;
  }

  /// Gets the subtle text color
  static Color getSubtleColor(AppThemeMode mode) {
    return Colors.white54;
  }

  /// Gets the border color for cards and containers
  static Color getBorderColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return Colors.white24;
      case AppThemeMode.forest:
        return const Color(0xFF4CAF50).withValues(alpha: 0.3);
    }
  }

  /// Gets the dialog background color
  static Color getDialogColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.wizard:
        return const Color(0xFF1A1A2E);
      case AppThemeMode.forest:
        return const Color(0xFF0D260D);
    }
  }
}
