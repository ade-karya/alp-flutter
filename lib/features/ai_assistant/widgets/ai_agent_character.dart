import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../cubit/ai_agent_state.dart';

class AIAgentCharacter extends StatefulWidget {
  final AIAgentStatus status;
  final bool isWizard;
  final double soundLevel;

  const AIAgentCharacter({
    super.key,
    required this.status,
    required this.isWizard,
    this.soundLevel = 0.0,
  });

  @override
  State<AIAgentCharacter> createState() => _AIAgentCharacterState();
}

class _AIAgentCharacterState extends State<AIAgentCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getGlowColor().withValues(alpha: 0.3),
                blurRadius: 20 + (10 * _getPulseValue()),
                spreadRadius: 5 * _getPulseValue(),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ring
              RotationTransition(
                turns: _getRotationAnimation(),
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getGlowColor().withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: widget.status == AIAgentStatus.thinking
                      ? Stack(
                          children: List.generate(3, (index) {
                            return Positioned(
                              top: 0,
                              left: 45,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _getGlowColor(),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }),
                        )
                      : null,
                ),
              ),
              // Main Core
              Container(
                height:
                    (60 + (10 * _getPulseValue())) *
                    (1 +
                        (widget.status == AIAgentStatus.listening
                            ? (widget.soundLevel / 40).clamp(0, 0.5)
                            : 0)),
                width:
                    (60 + (10 * _getPulseValue())) *
                    (1 +
                        (widget.status == AIAgentStatus.listening
                            ? (widget.soundLevel / 40).clamp(0, 0.5)
                            : 0)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getGlowColor(),
                      _getGlowColor().withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(_getStatusIcon(), color: Colors.white, size: 30),
              ),
              // Listening Waves
              if (widget.status == AIAgentStatus.listening)
                ...List.generate(3, (index) {
                  final progress = (_controller.value + (index / 3)) % 1.0;
                  return Container(
                    height: 60 + (80 * progress),
                    width: 60 + (80 * progress),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getGlowColor().withValues(alpha: 1 - progress),
                        width: 2,
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Color _getGlowColor() {
    if (widget.isWizard) {
      switch (widget.status) {
        case AIAgentStatus.listening:
          return Colors.blueAccent;
        case AIAgentStatus.thinking:
          return const Color(0xFFFFD700); // Gold
        case AIAgentStatus.speaking:
          return Colors.cyanAccent;
        default:
          return const Color(0xFF9C27B0); // Purple
      }
    } else {
      switch (widget.status) {
        case AIAgentStatus.listening:
          return Colors.redAccent;
        case AIAgentStatus.thinking:
          return Colors.orangeAccent;
        case AIAgentStatus.speaking:
          return Colors.blueAccent;
        default:
          return Colors.green;
      }
    }
  }

  double _getPulseValue() {
    switch (widget.status) {
      case AIAgentStatus.listening:
        final basePulse = math.sin(_controller.value * math.pi * 4) * 0.5 + 0.5;
        // Boost pulse with sound level (0 to -40 range typical for soundLevel in speech_to_text)
        // Note: level is negative or small positive dB-like values usually.
        // We normalize it to a 0.0 - 1.0 range boost if we assume -40 to 0 dB.
        final levelBoost = (widget.soundLevel + 40) / 40;
        return (basePulse * 0.5) + (levelBoost.clamp(0.0, 1.0) * 0.5);
      case AIAgentStatus.thinking:
        return 0.2;
      case AIAgentStatus.speaking:
        // Rhythmic "talking" wave
        return (math.sin(_controller.value * math.pi * 8) * 0.3 +
                math.sin(_controller.value * math.pi * 2) * 0.2) +
            0.5;
      default:
        return math.sin(_controller.value * math.pi * 2) * 0.2 + 0.5;
    }
  }

  Animation<double> _getRotationAnimation() {
    if (widget.status == AIAgentStatus.thinking) {
      return _controller;
    }
    return const AlwaysStoppedAnimation(0);
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case AIAgentStatus.listening:
        return Icons.mic;
      case AIAgentStatus.thinking:
        return Icons.auto_awesome;
      case AIAgentStatus.speaking:
        return Icons.volume_up;
      default:
        return Icons.support_agent;
    }
  }
}
