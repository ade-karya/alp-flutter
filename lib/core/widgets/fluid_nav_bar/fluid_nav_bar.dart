import 'package:flutter/material.dart';

import 'fluid_icon_data.dart';
import 'fluid_nav_bar_button.dart';
import 'curves.dart';

/// Callback for when the navigation bar selection changes
typedef FluidNavBarChangeCallback = void Function(int selectedIndex);

/// A fluid navigation bar with animated wave background
/// The background curves follow the selected icon with smooth animations
class FluidNavBar extends StatefulWidget {
  static const double nominalHeight = 56.0;

  final FluidNavBarChangeCallback? onChange;
  final List<FluidFillIconData> icons;
  final int selectedIndex;
  final Color backgroundColor;

  const FluidNavBar({
    super.key,
    required this.onChange,
    required this.icons,
    this.selectedIndex = 0,
    this.backgroundColor = Colors.white,
    this.gradient,
    this.itemActiveColor,
    this.itemInactiveColor,
    this.itemBackgroundColor,
  });

  final Gradient? gradient;
  final Color? itemActiveColor;
  final Color? itemInactiveColor;
  final Color? itemBackgroundColor;

  @override
  State<FluidNavBar> createState() => _FluidNavBarState();
}

class _FluidNavBarState extends State<FluidNavBar>
    with TickerProviderStateMixin {
  late int _selectedIndex;

  late AnimationController _xController;
  late AnimationController _yController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;

    _xController = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    );
    _yController = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    );

    Listenable.merge([_xController, _yController]).addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _xController.value =
        _indexToPosition(_selectedIndex) / MediaQuery.of(context).size.width;
    _yController.value = 1.0;
  }

  @override
  void didUpdateWidget(FluidNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _selectedIndex) {
      _handlePressed(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSize = MediaQuery.of(context).size;
    const height = FluidNavBar.nominalHeight;

    return SizedBox(
      width: appSize.width,
      height: FluidNavBar.nominalHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: appSize.width,
            height: height,
            child: _buildBackground(),
          ),
          Positioned(
            left: (appSize.width - _getButtonContainerWidth()) / 2,
            top: 0,
            width: _getButtonContainerWidth(),
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildButtons(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    const inCurve = ElasticOutCurve(0.38);
    return CustomPaint(
      painter: _BackgroundCurvePainter(
        x: _xController.value * MediaQuery.of(context).size.width,
        normalizedY: Tween<double>(
          begin: Curves.easeInExpo.transform(_yController.value),
          end: inCurve.transform(_yController.value),
        ).transform(_yController.velocity.sign * 0.5 + 0.5),
        color: widget.backgroundColor,
        gradient: widget.gradient,
      ),
    );
  }

  List<FluidNavBarButton> _buildButtons() {
    var buttons = <FluidNavBarButton>[];
    for (var i = 0; i < widget.icons.length; i++) {
      buttons.add(
        FluidNavBarButton(
          iconData: widget.icons[i],
          selected: _selectedIndex == i,
          onPressed: () => _handlePressed(i),
          activeColor: widget.itemActiveColor,
          inactiveColor: widget.itemInactiveColor,
          backgroundColor: widget.itemBackgroundColor,
        ),
      );
    }
    return buttons;
  }

  double _getButtonContainerWidth() {
    double width = MediaQuery.of(context).size.width;
    if (width > 400.0) {
      width = 400.0;
    }
    return width;
  }

  double _indexToPosition(int index) {
    final buttonCount = widget.icons.length.toDouble();
    final appWidth = MediaQuery.of(context).size.width;
    final buttonsWidth = _getButtonContainerWidth();
    final startX = (appWidth - buttonsWidth) / 2;
    return startX +
        index.toDouble() * buttonsWidth / buttonCount +
        buttonsWidth / (buttonCount * 2.0);
  }

  void _handlePressed(int index) {
    if (_selectedIndex == index || _xController.isAnimating) return;

    setState(() {
      _selectedIndex = index;
    });

    _yController.value = 1.0;
    _xController.animateTo(
      _indexToPosition(index) / MediaQuery.of(context).size.width,
      duration: const Duration(milliseconds: 620),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      _yController.animateTo(1.0, duration: const Duration(milliseconds: 1200));
    });
    _yController.animateTo(0.0, duration: const Duration(milliseconds: 300));

    widget.onChange?.call(index);
  }
}

/// Custom painter that draws the curved background for the nav bar
/// dengan efek gradient warna air laut dan busa ombak
class _BackgroundCurvePainter extends CustomPainter {
  static const _radiusTop = 54.0;
  static const _radiusBottom = 44.0;
  static const _horizontalControlTop = 0.6;
  static const _horizontalControlBottom = 0.5;
  static const _pointControlTop = 0.35;
  static const _pointControlBottom = 0.85;
  static const _topY = -10.0;
  static const _bottomY = 54.0;
  static const _topDistance = 0.0;
  static const _bottomDistance = 6.0;

  // Warna-warna air laut dan busa ombak
  static const Color _foamWhite = Color(0xFFE8F5F9); // Putih busa ombak
  static const Color _foamLight = Color(0xFFB2EBF2); // Biru muda busa
  static const Color _seaLight = Color(0xFF4DD0E1); // Biru muda air laut
  static const Color _seaMedium = Color(0xFF00ACC1); // Biru air laut
  static const Color _seaDeep = Color(0xFF00838F); // Biru tua air laut

  final double x;
  final double normalizedY;
  final Color color; // Masih dipertahankan untuk kompatibilitas
  final Gradient? gradient;

  _BackgroundCurvePainter({
    required this.x,
    required this.normalizedY,
    required this.color,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final norm = const LinearPointCurve(0.5, 2.0).transform(normalizedY) / 2;

    final radius = Tween<double>(
      begin: _radiusTop,
      end: _radiusBottom,
    ).transform(norm);

    final anchorControlOffset = Tween<double>(
      begin: radius * _horizontalControlTop,
      end: radius * _horizontalControlBottom,
    ).transform(const LinearPointCurve(0.5, 0.75).transform(norm));

    final dipControlOffset = Tween<double>(
      begin: radius * _pointControlTop,
      end: radius * _pointControlBottom,
    ).transform(const LinearPointCurve(0.5, 0.8).transform(norm));

    final y = Tween<double>(
      begin: _topY,
      end: _bottomY,
    ).transform(const LinearPointCurve(0.2, 0.7).transform(norm));

    final dist = Tween<double>(
      begin: _topDistance,
      end: _bottomDistance,
    ).transform(const LinearPointCurve(0.5, 0.0).transform(norm));

    final x0 = x - dist / 2;
    final x1 = x + dist / 2;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(x0 - radius, 0)
      ..cubicTo(
        x0 - radius + anchorControlOffset,
        0,
        x0 - dipControlOffset,
        y,
        x0,
        y,
      )
      ..lineTo(x1, y)
      ..cubicTo(
        x1 + dipControlOffset,
        y,
        x1 + radius - anchorControlOffset,
        0,
        x1 + radius,
        0,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height);

    // Use provided gradient or default sea gradient
    final paintGradient =
        gradient ??
        const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _foamWhite, // Busa putih di atas
            _foamLight, // Transisi busa
            _seaLight, // Air laut muda
            _seaMedium, // Air laut
            _seaDeep, // Air laut dalam di bawah
          ],
          stops: [0.0, 0.15, 0.35, 0.6, 1.0],
        );

    final paint = Paint()
      ..shader = paintGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(path, paint);

    // Garis tipis di atas untuk efek busa ombak
    final foamPath = Path()
      ..moveTo(0, 0)
      ..lineTo(x0 - radius, 0)
      ..cubicTo(
        x0 - radius + anchorControlOffset,
        0,
        x0 - dipControlOffset,
        y,
        x0,
        y,
      )
      ..lineTo(x1, y)
      ..cubicTo(
        x1 + dipControlOffset,
        y,
        x1 + radius - anchorControlOffset,
        0,
        x1 + radius,
        0,
      )
      ..lineTo(size.width, 0);

    final foamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withAlpha(180);

    canvas.drawPath(foamPath, foamPaint);
  }

  @override
  bool shouldRepaint(_BackgroundCurvePainter oldPainter) {
    return x != oldPainter.x ||
        normalizedY != oldPainter.normalizedY ||
        color != oldPainter.color;
  }
}
