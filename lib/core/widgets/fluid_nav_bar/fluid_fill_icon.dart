import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'fluid_icon_data.dart';

/// A widget that displays an icon with a fill animation effect
/// Supports both Material Icons and custom path-based icons
class FluidFillIcon extends StatelessWidget {
  static const double iconDataScale = 0.9;

  /// Warna biru air laut untuk ikon aktif
  static const Color defaultActiveColor = Color(0xFF00838F);

  /// Warna abu-abu untuk ikon tidak aktif
  static const Color defaultInactiveColor = Color(0xFFBDBDBD);

  final FluidFillIconData iconData;

  /// A normalized value between 0 and 1 representing fill amount
  final double fillAmount;

  /// Vertical scale for squash/stretch effect
  final double scaleY;

  final Color? activeColor;
  final Color? inactiveColor;

  const FluidFillIcon({
    super.key,
    required this.iconData,
    required this.fillAmount,
    required this.scaleY,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    // Defaults
    final active = activeColor ?? defaultActiveColor; // Sea Teal
    final inactive = inactiveColor ?? defaultInactiveColor; // Grey

    // Jika menggunakan Material Icon
    if (iconData.isMaterialIcon) {
      return Transform.scale(
        scaleY: scaleY,
        child: Icon(
          iconData.materialIcon,
          size: 28,
          color: Color.lerp(inactive, active, fillAmount),
        ),
      );
    }

    // Jika menggunakan custom path icons
    return CustomPaint(
      painter: _FluidFillIconPainter(
        paths: iconData.paths ?? [],
        fillAmount: fillAmount,
        scaleY: scaleY,
        activeColor: active,
      ),
    );
  }
}

class _FluidFillIconPainter extends CustomPainter {
  final List<ui.Path> paths;
  final double fillAmount;
  final double scaleY;
  final Color activeColor;

  _FluidFillIconPainter({
    required this.paths,
    required this.fillAmount,
    required this.scaleY,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBackground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.grey.shade300;

    final paintForeground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = activeColor;

    // Scale around center vertically
    canvas.translate(0.0, size.height / 2);
    canvas.scale(1.0, scaleY);
    // Center and apply icon data scale
    canvas.translate(size.width / 2, 0.0);
    canvas.scale(FluidFillIcon.iconDataScale, FluidFillIcon.iconDataScale);

    // Draw background greyed out paths
    for (final path in paths) {
      canvas.drawPath(path, paintBackground);
    }

    // Draw foreground with fill effect
    if (fillAmount > 0.0) {
      for (final path in paths) {
        canvas.drawPath(
          _extractPartialPath(path, 0.0, fillAmount),
          paintForeground,
        );
      }
    }
  }

  /// Extracts a partial path from start to end percentage
  ui.Path _extractPartialPath(ui.Path source, double start, double end) {
    final metrics = source.computeMetrics();
    final result = ui.Path();

    for (final metric in metrics) {
      final length = metric.length;
      final startDistance = length * start;
      final endDistance = length * end;

      final extracted = metric.extractPath(startDistance, endDistance);
      result.addPath(extracted, Offset.zero);
    }

    return result;
  }

  @override
  bool shouldRepaint(_FluidFillIconPainter oldDelegate) {
    return fillAmount != oldDelegate.fillAmount || scaleY != oldDelegate.scaleY;
  }
}
