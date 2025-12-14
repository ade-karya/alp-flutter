import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Data class that holds icon data - supports both custom paths and Material Icons
class FluidFillIconData {
  final List<ui.Path>? paths;
  final IconData? materialIcon;

  const FluidFillIconData({this.paths, this.materialIcon});

  /// Constructor for path-based icons
  const FluidFillIconData.fromPaths(List<ui.Path> pathList)
    : paths = pathList,
      materialIcon = null;

  /// Constructor for Material icons
  const FluidFillIconData.fromMaterial(IconData icon)
    : materialIcon = icon,
      paths = null;

  bool get isMaterialIcon => materialIcon != null;
}

/// Predefined icons for the fluid navigation bar
/// Now supports both custom paths and Material Icons
class FluidFillIcons {
  // ===== Material Icons (seperti dashboard) =====

  /// Dashboard icon
  static const dashboard = FluidFillIconData.fromMaterial(
    Icons.dashboard_outlined,
  );

  /// Home icon (Material)
  static const homeOutlined = FluidFillIconData.fromMaterial(
    Icons.home_outlined,
  );

  /// Create content icon
  static const noteAddOutlined = FluidFillIconData.fromMaterial(
    Icons.note_add_outlined,
  );

  /// Manage class icon
  static const peopleOutlined = FluidFillIconData.fromMaterial(
    Icons.people_outlined,
  );

  /// AI Assistant icon
  static const smartToy = FluidFillIconData.fromMaterial(
    Icons.smart_toy_outlined,
  );

  /// School icon (Material)
  static const schoolOutlined = FluidFillIconData.fromMaterial(
    Icons.school_outlined,
  );

  /// Book/Library icon
  static const libraryBooks = FluidFillIconData.fromMaterial(
    Icons.library_books_outlined,
  );

  // ===== Custom Path Icons (untuk animasi fluid) =====

  /// Home icon - house shape
  static final home = FluidFillIconData(
    paths: [
      ui.Path()..addRRect(const RRect.fromLTRBXY(-10, -2, 10, 10, 2, 2)),
      ui.Path()
        ..moveTo(-14, -2)
        ..lineTo(14, -2)
        ..lineTo(0, -16)
        ..close(),
    ],
  );

  /// User/Profile icon - person shape
  static final user = FluidFillIconData(
    paths: [
      ui.Path()
        ..arcTo(const Rect.fromLTRB(-5, -16, 5, -6), 0, 1.9 * math.pi, true),
      ui.Path()
        ..arcTo(const Rect.fromLTRB(-10, 0, 10, 20), 0, -1.0 * math.pi, true),
    ],
  );

  /// Grid/Window icon - 4 squares
  static final window = FluidFillIconData(
    paths: [
      ui.Path()..addRRect(const RRect.fromLTRBXY(-12, -12, -2, -2, 2, 2)),
      ui.Path()..addRRect(const RRect.fromLTRBXY(2, -12, 12, -2, 2, 2)),
      ui.Path()..addRRect(const RRect.fromLTRBXY(-12, 2, -2, 12, 2, 2)),
      ui.Path()..addRRect(const RRect.fromLTRBXY(2, 2, 12, 12, 2, 2)),
    ],
  );

  /// School/Learning icon - graduation cap shape
  static final school = FluidFillIconData(
    paths: [
      ui.Path()
        ..moveTo(-14, 0)
        ..lineTo(0, -10)
        ..lineTo(14, 0)
        ..lineTo(0, 10)
        ..close(),
      ui.Path()
        ..moveTo(0, 2)
        ..lineTo(0, 14),
      ui.Path()
        ..moveTo(-6, 6)
        ..lineTo(-6, 12)
        ..lineTo(6, 12)
        ..lineTo(6, 6),
    ],
  );

  /// Book icon - open book shape
  static final book = FluidFillIconData(
    paths: [
      ui.Path()
        ..moveTo(0, -10)
        ..lineTo(0, 10),
      ui.Path()
        ..moveTo(-12, -8)
        ..lineTo(-12, 10)
        ..lineTo(0, 8)
        ..moveTo(-12, -8)
        ..quadraticBezierTo(-6, -12, 0, -10),
      ui.Path()
        ..moveTo(12, -8)
        ..lineTo(12, 10)
        ..lineTo(0, 8)
        ..moveTo(12, -8)
        ..quadraticBezierTo(6, -12, 0, -10),
    ],
  );

  /// Robot/AI icon - robot head
  static final robot = FluidFillIconData(
    paths: [
      ui.Path()..addRRect(const RRect.fromLTRBXY(-10, -6, 10, 10, 4, 4)),
      ui.Path()
        ..moveTo(0, -6)
        ..lineTo(0, -12),
      ui.Path()..addOval(const Rect.fromLTRB(-2, -14, 2, -10)),
      ui.Path()..addOval(const Rect.fromLTRB(-7, -2, -3, 2)),
      ui.Path()..addOval(const Rect.fromLTRB(3, -2, 7, 2)),
      ui.Path()
        ..moveTo(-5, 6)
        ..lineTo(5, 6),
    ],
  );

  /// Note/Create icon - document with plus
  static final noteAdd = FluidFillIconData(
    paths: [
      ui.Path()
        ..moveTo(-8, -12)
        ..lineTo(-8, 12)
        ..lineTo(8, 12)
        ..lineTo(8, -4)
        ..lineTo(0, -12)
        ..close(),
      ui.Path()
        ..moveTo(0, -12)
        ..lineTo(0, -4)
        ..lineTo(8, -4),
      ui.Path()
        ..moveTo(-4, 4)
        ..lineTo(4, 4),
      ui.Path()
        ..moveTo(0, 0)
        ..lineTo(0, 8),
    ],
  );

  /// People/Class icon - group of people
  static final people = FluidFillIconData(
    paths: [
      ui.Path()
        ..arcTo(const Rect.fromLTRB(-4, -14, 4, -6), 0, 1.9 * math.pi, true),
      ui.Path()
        ..arcTo(const Rect.fromLTRB(-8, -2, 8, 14), 0, -1.0 * math.pi, true),
      ui.Path()
        ..arcTo(const Rect.fromLTRB(-14, -10, -6, -4), 0, 1.9 * math.pi, true),
      ui.Path()
        ..arcTo(const Rect.fromLTRB(6, -10, 14, -4), 0, 1.9 * math.pi, true),
    ],
  );
}
