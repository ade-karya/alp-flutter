import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Custom elastic out curve centered at 0.5
/// Used for button pop-up animation when selected
class CenteredElasticOutCurve extends Curve {
  final double period;

  const CenteredElasticOutCurve([this.period = 0.4]);

  @override
  double transform(double t) {
    return math.pow(2.0, -10.0 * t) * math.sin(t * 2.0 * math.pi / period) +
        0.5;
  }
}

/// Custom elastic in curve centered at 0.5
/// Used for button animation when deselected
class CenteredElasticInCurve extends Curve {
  final double period;

  const CenteredElasticInCurve([this.period = 0.4]);

  @override
  double transform(double t) {
    return -math.pow(2.0, 10.0 * (t - 1.0)) *
            math.sin((t - 1.0) * 2.0 * math.pi / period) +
        0.5;
  }
}

/// Linear interpolation curve with control points
/// Used for timing adjustments in animations
class LinearPointCurve extends Curve {
  final double pIn;
  final double pOut;

  const LinearPointCurve(this.pIn, this.pOut);

  @override
  double transform(double t) {
    final lowerScale = pOut / pIn;
    final upperScale = (1.0 - pOut) / (1.0 - pIn);
    final upperOffset = 1.0 - upperScale;
    return t < pIn ? t * lowerScale : t * upperScale + upperOffset;
  }
}
