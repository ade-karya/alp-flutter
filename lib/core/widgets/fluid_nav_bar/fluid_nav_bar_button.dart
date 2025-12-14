import 'package:flutter/material.dart';

import 'fluid_fill_icon.dart';
import 'fluid_icon_data.dart';
import 'curves.dart';

/// Callback for when a nav bar button is pressed
typedef FluidNavBarButtonPressedCallback = void Function();

/// A button widget for the fluid navigation bar
/// Animates up/down when selected and includes fill animation
class FluidNavBarButton extends StatefulWidget {
  static const nominalExtent = Size(64, 64);

  final FluidFillIconData iconData;
  final bool selected;
  final FluidNavBarButtonPressedCallback onPressed;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;

  const FluidNavBarButton({
    super.key,
    required this.iconData,
    required this.selected,
    required this.onPressed,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
  });

  @override
  State<FluidNavBarButton> createState() => _FluidNavBarButtonState();
}

class _FluidNavBarButtonState extends State<FluidNavBarButton>
    with SingleTickerProviderStateMixin {
  static const double _activeOffset = 16;
  static const double _defaultOffset = 0;
  static const double _radius = 25;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1666),
      reverseDuration: const Duration(milliseconds: 833),
      vsync: this,
    );
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
          ..addListener(() {
            setState(() {});
          });
    _startAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FluidNavBarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (widget.selected) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    const ne = FluidNavBarButton.nominalExtent;
    final offsetCurve = widget.selected
        ? const ElasticOutCurve(0.38)
        : Curves.easeInQuint;
    final scaleCurve = widget.selected
        ? const CenteredElasticOutCurve(0.6)
        : const CenteredElasticInCurve(0.6);

    final progress = const LinearPointCurve(
      0.28,
      0.0,
    ).transform(_animation.value);

    final offset = Tween<double>(
      begin: _defaultOffset,
      end: _activeOffset,
    ).transform(offsetCurve.transform(progress));
    const scaleCurveScale = 0.50;
    final scaleY =
        0.5 +
        scaleCurve.transform(progress) * scaleCurveScale +
        (0.5 - scaleCurveScale / 2);

    return GestureDetector(
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints.tight(ne),
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.all(ne.width / 2 - _radius),
          constraints: BoxConstraints.tight(const Size.square(_radius * 2)),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(25),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          transform: Matrix4.translationValues(0, -offset, 0),
          child: FluidFillIcon(
            iconData: widget.iconData,
            fillAmount: const LinearPointCurve(
              0.25,
              1.0,
            ).transform(_animation.value),
            scaleY: scaleY,
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
          ),
        ),
      ),
    );
  }
}
