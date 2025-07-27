import 'package:flutter/material.dart';
import 'nebula_background_painter.dart';

class DynamicNebulaBackground extends StatefulWidget {
  final List<Color> colors;
  final double noiseIntensity;
  final Duration colorTransitionDuration;

  const DynamicNebulaBackground({
    super.key,
    this.colors = const [
      Color(0xFF8A2BE2),
      Color(0xFFCC6699),
      Color(0xFF00BFFF),
      Color(0xFFDA70D6),
    ],
    this.noiseIntensity = 0.05,
    this.colorTransitionDuration = const Duration(seconds: 10),
  });

  @override
  State<DynamicNebulaBackground> createState() => _DynamicNebulaBackgroundState();
}

class _DynamicNebulaBackgroundState extends State<DynamicNebulaBackground>
    with TickerProviderStateMixin {
  late AnimationController _positionController;
  late AnimationController _colorController;

  Offset _position = const Offset(0.5, 0.5);
  Offset _velocity = const Offset(0.0016, 0.0024);

  @override
  void initState() {
    super.initState();

    // Controls the moving position of the nebula center
    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Controls the color transition cycle
    _colorController = AnimationController(
      vsync: this,
      duration: widget.colorTransitionDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _positionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Color _getCurrentColor() {
    final colors = widget.colors;
    if (colors.isEmpty) return Colors.black;

    // Calculate which two colors to interpolate between
    final double progress = _colorController.value * colors.length;
    final int index = progress.floor() % colors.length;
    final int nextIndex = (index + 1) % colors.length;

    final double t = progress - progress.floor(); // fractional part for lerp

    return Color.lerp(colors[index], colors[nextIndex], t) ?? colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_positionController, _colorController]),
        builder: (context, child) {
          // Update nebula position with boundary bouncing
          const double minX = 0.0, maxX = 1.0;
          const double minY = 0.0, maxY = 1.0;

          if (_position.dx <= minX || _position.dx >= maxX) {
            _velocity = Offset(-_velocity.dx, _velocity.dy);
          }
          if (_position.dy <= minY || _position.dy >= maxY) {
            _velocity = Offset(_velocity.dx, -_velocity.dy);
          }
          _position += _velocity;

          // Get interpolated current color from palette
          final Color currentColor = _getCurrentColor();

          return SizedBox.expand(
            child: CustomPaint(
              painter: NebulaBackgroundPainter(
                center: _position,
                colors: [currentColor], // Use the single interpolated color
                noiseIntensity: widget.noiseIntensity,
              ),
            ),
          );
        },
      ),
    );
  }
}

