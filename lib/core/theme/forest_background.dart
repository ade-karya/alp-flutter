import 'dart:math';
import 'package:flutter/material.dart';

class ForestBackground extends StatefulWidget {
  final Widget child;

  const ForestBackground({super.key, required this.child});

  @override
  State<ForestBackground> createState() => _ForestBackgroundState();
}

class _ForestBackgroundState extends State<ForestBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Firefly> _fireflies = [];
  final List<Leaf> _leaves = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Generate fireflies
    for (int i = 0; i < 25; i++) {
      _fireflies.add(
        Firefly(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 2,
          opacity: _random.nextDouble(),
          speedX: (_random.nextDouble() - 0.5) * 0.1,
          speedY: (_random.nextDouble() - 0.5) * 0.1,
          pulsePhase: _random.nextDouble() * 2 * pi,
        ),
      );
    }

    // Generate floating leaves
    for (int i = 0; i < 15; i++) {
      _leaves.add(
        Leaf(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 10 + 8,
          rotation: _random.nextDouble() * 2 * pi,
          speed: _random.nextDouble() * 0.05 + 0.02,
          swayPhase: _random.nextDouble() * 2 * pi,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fresh & Modern Light Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFFFFF), // White top
                Color(0xFFF1F8E9), // Light Green 50
                Color(0xFFDCEDC8), // Light Green 100
                Color(0xFFA5D6A7), // Green 200
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Subtle tree silhouettes overlay
        Positioned.fill(child: CustomPaint(painter: TreeSilhouettePainter())),

        // Animated Fireflies
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: FireflyPainter(_fireflies, _controller.value),
              size: Size.infinite,
            );
          },
        ),

        // Floating Leaves (optional - subtle effect)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: LeafPainter(_leaves, _controller.value),
              size: Size.infinite,
            );
          },
        ),

        // Subtle gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.5),
                  Colors.white.withValues(alpha: 0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class Firefly {
  double x;
  double y;
  double size;
  double opacity;
  double speedX;
  double speedY;
  double pulsePhase;

  Firefly({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedX,
    required this.speedY,
    required this.pulsePhase,
  });
}

class Leaf {
  double x;
  double y;
  double size;
  double rotation;
  double speed;
  double swayPhase;

  Leaf({
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.speed,
    required this.swayPhase,
  });
}

class FireflyPainter extends CustomPainter {
  final List<Firefly> fireflies;
  final double animationValue;

  FireflyPainter(this.fireflies, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var firefly in fireflies) {
      // Pulsing glow effect
      final pulse =
          (sin(animationValue * 2 * pi * 2 + firefly.pulsePhase) + 1) / 2;
      final opacity = (firefly.opacity * 0.3 + pulse * 0.7).clamp(0.0, 1.0);

      // Gentle floating movement
      final xPos =
          (firefly.x +
              sin(animationValue * 2 * pi + firefly.pulsePhase) * 0.02) %
          1.0;
      final yPos =
          (firefly.y +
              cos(animationValue * 2 * pi * 0.5 + firefly.pulsePhase) * 0.02) %
          1.0;

      // Subtle floating particle
      final glowPaint = Paint()
        ..color = const Color(0xFFC6FF00)
            .withValues(alpha: opacity * 0.4) // Lime glow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(
        Offset(xPos * size.width, yPos * size.height),
        firefly.size * 2,
        glowPaint,
      );

      // Soft teal core
      final corePaint = Paint()
        ..color = const Color(
          0xFFAEEA00,
        ).withValues(alpha: opacity * 0.6); // Yellow-Green core

      canvas.drawCircle(
        Offset(xPos * size.width, yPos * size.height),
        firefly.size,
        corePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FireflyPainter oldDelegate) => true;
}

class LeafPainter extends CustomPainter {
  final List<Leaf> leaves;
  final double animationValue;

  LeafPainter(this.leaves, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(
        0xFF66BB6A,
      ).withValues(alpha: 0.3); // Fresh leaf green

    for (var leaf in leaves) {
      // Falling and swaying movement
      final yPos = (leaf.y + animationValue * leaf.speed) % 1.0;
      final xOffset = sin(animationValue * 2 * pi + leaf.swayPhase) * 0.03;
      final xPos = (leaf.x + xOffset) % 1.0;
      final rotation = leaf.rotation + animationValue * 2 * pi;

      canvas.save();
      canvas.translate(xPos * size.width, yPos * size.height);
      canvas.rotate(rotation);

      // Simple leaf shape
      final path = Path()
        ..moveTo(0, -leaf.size / 2)
        ..quadraticBezierTo(leaf.size / 3, 0, 0, leaf.size / 2)
        ..quadraticBezierTo(-leaf.size / 3, 0, 0, -leaf.size / 2);

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LeafPainter oldDelegate) => true;
}

class TreeSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF81C784)
          .withValues(alpha: 0.25) // Subtle green trees
      ..style = PaintingStyle.fill;

    // Draw subtle tree silhouettes at the bottom
    _drawTree(canvas, size.width * 0.1, size.height, size.height * 0.3, paint);
    _drawTree(canvas, size.width * 0.25, size.height, size.height * 0.4, paint);
    _drawTree(
      canvas,
      size.width * 0.75,
      size.height,
      size.height * 0.35,
      paint,
    );
    _drawTree(canvas, size.width * 0.9, size.height, size.height * 0.45, paint);
  }

  void _drawTree(
    Canvas canvas,
    double x,
    double bottom,
    double height,
    Paint paint,
  ) {
    final path = Path()
      ..moveTo(x, bottom)
      ..lineTo(x - height * 0.3, bottom - height * 0.4)
      ..lineTo(x - height * 0.2, bottom - height * 0.4)
      ..lineTo(x - height * 0.35, bottom - height * 0.7)
      ..lineTo(x - height * 0.15, bottom - height * 0.7)
      ..lineTo(x, bottom - height)
      ..lineTo(x + height * 0.15, bottom - height * 0.7)
      ..lineTo(x + height * 0.35, bottom - height * 0.7)
      ..lineTo(x + height * 0.2, bottom - height * 0.4)
      ..lineTo(x + height * 0.3, bottom - height * 0.4)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TreeSilhouettePainter oldDelegate) => false;
}
