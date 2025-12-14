import 'dart:math';
import 'package:flutter/material.dart';

class WizardBackground extends StatefulWidget {
  final Widget child;

  const WizardBackground({super.key, required this.child});

  @override
  State<WizardBackground> createState() => _WizardBackgroundState();
}

class _WizardBackgroundState extends State<WizardBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Star> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate random stars
    for (int i = 0; i < 50; i++) {
      _stars.add(
        Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 2 + 1,
          opacity: _random.nextDouble(),
          speed: _random.nextDouble() * 0.2 + 0.1,
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
        // Deep Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F0C29), // Deepest Navy
                Color(0xFF302B63), // Purple Navy
                Color(0xFF24243E), // Dark Slate
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Animated Stars
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: StarPainter(_stars, _controller.value),
              size: Size.infinite,
            );
          },
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class Star {
  double x;
  double y;
  double size;
  double opacity;
  double speed;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
  });
}

class StarPainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  StarPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var star in stars) {
      // Twinkle effect
      final opacity =
          (star.opacity + sin(animationValue * 2 * pi * star.speed)) / 2 + 0.3;
      paint.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));

      // Gentle movement
      final yPos = (star.y + animationValue * star.speed) % 1.0;

      canvas.drawCircle(
        Offset(star.x * size.width, yPos * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) => true;
}
