import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model untuk satu langkah tutorial
class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final GlobalKey? targetKey; // Key widget yang akan di-highlight

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    this.targetKey,
  });
}

/// Widget overlay tutorial interaktif dengan tema air laut
/// Menampilkan panduan step-by-step dengan efek spotlight
class FeatureTutorial extends StatefulWidget {
  final List<TutorialStep> steps;
  final String tutorialKey;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const FeatureTutorial({
    super.key,
    required this.steps,
    required this.tutorialKey,
    this.onComplete,
    this.onSkip,
  });

  /// Menampilkan tutorial jika belum pernah dilihat
  static Future<void> showIfFirstTime({
    required BuildContext context,
    required List<TutorialStep> steps,
    required String tutorialKey,
    VoidCallback? onComplete,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('tutorial_$tutorialKey') ?? false;

    if (!hasSeenTutorial && context.mounted) {
      await _showTutorialOverlay(
        context: context,
        steps: steps,
        tutorialKey: tutorialKey,
        onComplete: () async {
          await prefs.setBool('tutorial_$tutorialKey', true);
          onComplete?.call();
        },
        onSkip: () async {
          await prefs.setBool('tutorial_$tutorialKey', true);
        },
      );
    }
  }

  /// Menampilkan tutorial langsung (untuk tombol help)
  static Future<void> show({
    required BuildContext context,
    required List<TutorialStep> steps,
    required String tutorialKey,
    VoidCallback? onComplete,
  }) async {
    await _showTutorialOverlay(
      context: context,
      steps: steps,
      tutorialKey: tutorialKey,
      onComplete: onComplete,
      onSkip: null,
    );
  }

  static Future<void> _showTutorialOverlay({
    required BuildContext context,
    required List<TutorialStep> steps,
    required String tutorialKey,
    VoidCallback? onComplete,
    VoidCallback? onSkip,
  }) async {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TutorialOverlay(
        steps: steps,
        onComplete: () {
          overlayEntry.remove();
          onComplete?.call();
        },
        onSkip: () {
          overlayEntry.remove();
          onSkip?.call();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  State<FeatureTutorial> createState() => _FeatureTutorialState();
}

class _FeatureTutorialState extends State<FeatureTutorial> {
  @override
  Widget build(BuildContext context) {
    return _TutorialOverlay(
      steps: widget.steps,
      onComplete: widget.onComplete ?? () {},
      onSkip: widget.onSkip ?? () {},
    );
  }
}

/// Overlay widget yang menampilkan tutorial dengan spotlight
class _TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const _TutorialOverlay({
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Rect? _targetRect;

  // Warna tema air laut
  static const Color _foamLight = Color(0xFFB2EBF2);
  static const Color _seaLight = Color(0xFF4DD0E1);
  static const Color _seaMedium = Color(0xFF00ACC1);
  static const Color _seaDeep = Color(0xFF00838F);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _updateTargetRect();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateTargetRect() {
    final step = widget.steps[_currentStep];
    if (step.targetKey?.currentContext != null) {
      final RenderBox? renderBox =
          step.targetKey!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        setState(() {
          _targetRect = Rect.fromLTWH(
            position.dx,
            position.dy,
            renderBox.size.width,
            renderBox.size.height,
          );
        });
        return;
      }
    }
    setState(() => _targetRect = null);
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _animationController.reverse().then((_) {
        setState(() => _currentStep++);
        _updateTargetRect();
        _animationController.forward();
      });
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reverse().then((_) {
        setState(() => _currentStep--);
        _updateTargetRect();
        _animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final isLastStep = _currentStep == widget.steps.length - 1;
    final isFirstStep = _currentStep == 0;
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Dark overlay dengan spotlight hole
              Positioned.fill(
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: _targetRect,
                    opacity: _fadeAnimation.value * 0.85,
                  ),
                ),
              ),

              // Highlight border untuk target
              if (_targetRect != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  left: _targetRect!.left - 8,
                  top: _targetRect!.top - 8,
                  width: _targetRect!.width + 16,
                  height: _targetRect!.height + 16,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _seaMedium.withAlpha(
                            (200 * _fadeAnimation.value).toInt(),
                          ),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _seaLight.withAlpha(
                              (150 * _fadeAnimation.value).toInt(),
                            ),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Pulsing indicator arrow
              if (_targetRect != null) _buildArrowIndicator(),

              // Tutorial card
              Positioned(
                left: 16,
                right: 16,
                bottom: _targetRect != null
                    ? (_targetRect!.bottom > screenSize.height * 0.6
                          ? screenSize.height - _targetRect!.top + 24
                          : 100)
                    : screenSize.height * 0.3,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildTutorialCard(step, isFirstStep, isLastStep),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArrowIndicator() {
    if (_targetRect == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final isTargetOnTop = _targetRect!.center.dy < screenSize.height * 0.5;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: _targetRect!.center.dx - 20,
      top: isTargetOnTop ? _targetRect!.bottom + 8 : _targetRect!.top - 48,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 8 * (0.5 - (value - 0.5).abs())),
            child: child,
          );
        },
        onEnd: () {
          if (mounted) setState(() {});
        },
        child: Icon(
          isTargetOnTop ? Icons.arrow_upward : Icons.arrow_downward,
          color: _seaMedium,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildTutorialCard(
    TutorialStep step,
    bool isFirstStep,
    bool isLastStep,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _seaDeep.withAlpha(60),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_foamLight, _seaLight, _seaMedium],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(step.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                // Step counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentStep + 1}/${widget.steps.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              step.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Step indicators
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.steps.length, (index) {
                final isActive = index == _currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: isActive ? 20 : 6,
                  decoration: BoxDecoration(
                    color: isActive ? _seaMedium : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                if (!isLastStep)
                  TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      'Lewati',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                const Spacer(),
                if (!isFirstStep)
                  TextButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Kembali'),
                    style: TextButton.styleFrom(foregroundColor: _seaDeep),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _nextStep,
                  icon: Icon(
                    isLastStep ? Icons.check : Icons.arrow_forward,
                    size: 16,
                  ),
                  label: Text(isLastStep ? 'Selesai' : 'Lanjut'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _seaMedium,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter untuk membuat efek spotlight
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double opacity;

  _SpotlightPainter({this.targetRect, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect != null) {
      // Buat lubang spotlight dengan rounded rect
      final spotlightRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          targetRect!.left - 8,
          targetRect!.top - 8,
          targetRect!.width + 16,
          targetRect!.height + 16,
        ),
        const Radius.circular(12),
      );
      path.addRRect(spotlightRect);
      path.fillType = PathFillType.evenOdd;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        opacity != oldDelegate.opacity;
  }
}
