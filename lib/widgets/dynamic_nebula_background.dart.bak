// lib/widgets/dynamic_nebula_background.dart

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class DynamicNebulaBackground extends StatefulWidget {
  final double speed;
  final double blurSigma;

  const DynamicNebulaBackground({
    super.key,
    this.speed = 0.2,
    this.blurSigma = 70.0, // Increased blur for a softer blend
  });

  @override
  State<DynamicNebulaBackground> createState() => _DynamicNebulaBackgroundState();
}

class _DynamicNebulaBackgroundState extends State<DynamicNebulaBackground>
    with TickerProviderStateMixin {
  final Random _random = Random();
  
  late AnimationController _positionController;
  late AnimationController _colorController;
  
  // --- Layer Properties (Initial Offset & Amplitude for motion) ---
  late Offset _initialPosition1, _initialPosition2, _initialPosition3;
  late double _amplitude1, _amplitude2, _amplitude3;
  late double _phaseShift1, _phaseShift2, _phaseShift3;

  @override
  void initState() {
    super.initState();
    _initializeLayers();

    // Controller for the smooth, orbital movement of layers
    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40), // Slower movement for a lava lamp feel
    )..repeat(reverse: true); // Repeat with a reverse to keep it smooth

    // Controller for the perpetual color evolution
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30), // Very slow evolution
    )..repeat();
  }
  
  void _initializeLayers() {
    _initialPosition1 = _getRandomOffset();
    _initialPosition2 = _getRandomOffset();
    _initialPosition3 = _getRandomOffset();

    _amplitude1 = 0.1 + _random.nextDouble() * 0.1;
    _amplitude2 = 0.1 + _random.nextDouble() * 0.1;
    _amplitude3 = 0.1 + _random.nextDouble() * 0.1;
    
    _phaseShift1 = _random.nextDouble() * 2 * pi;
    _phaseShift2 = _random.nextDouble() * 2 * pi;
    _phaseShift3 = _random.nextDouble() * 2 * pi;
  }

  /// Generates a random Offset within the screen bounds (0.0 to 1.0).
  Offset _getRandomOffset() => Offset(
      _random.nextDouble() * 0.8 + 0.1, // Ensure blobs start in a central area
      _random.nextDouble() * 0.8 + 0.1);

  @override
  void dispose() {
    _positionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_positionController, _colorController]),
      builder: (context, child) {
        final double time = _positionController.value * 2 * pi;

        // Calculate new positions based on a smooth, non-linear function
        final newPosition1 = _calculateNewPosition(_initialPosition1, _amplitude1, _phaseShift1, time);
        final newPosition2 = _calculateNewPosition(_initialPosition2, _amplitude2, _phaseShift2, time);
        final newPosition3 = _calculateNewPosition(_initialPosition3, _amplitude3, _phaseShift3, time);

        return CustomPaint(
          painter: NebulaBackgroundPainter(
            positions: [newPosition1, newPosition2, newPosition3],
            colors: _getEvolvingColors(),
            blurSigma: widget.blurSigma,
          ),
          child: Container(),
        );
      },
    );
  }

  /// Calculates the next position using sine and cosine for a smooth, orbital path.
  Offset _calculateNewPosition(Offset initial, double amplitude, double phaseShift, double time) {
    return Offset(
      initial.dx + amplitude * sin(time + phaseShift),
      initial.dy + amplitude * cos(time + phaseShift),
    );
  }

  /// Generates a list of 6 smoothly evolving colors.
  List<Color> _getEvolvingColors() {
    final double time = _colorController.value;
    return List.generate(6, (i) {
      final double hue = (time * 360 + i * 30) % 360;
      return HSLColor.fromAHSL(1.0, hue, 0.8, 0.6).toColor();
    });
  }
}

class NebulaBackgroundPainter extends CustomPainter {
  final List<Offset> positions;
  final List<Color> colors;
  final double blurSigma;

  NebulaBackgroundPainter({
    required this.positions,
    required this.colors,
    required this.blurSigma,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0C0C0C));

    final blurFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

    // Layer 1: Base Layer (Largest)
    _paintLayer(
      canvas,
      size,
      positions[0],
      [colors[0], colors[1]],
      size.shortestSide * 0.9,
      blurFilter,
    );

    // Layer 2: Middle Layer
    _paintLayer(
      canvas,
      size,
      positions[1],
      [colors[2], colors[3]],
      size.shortestSide * 0.7,
      blurFilter,
      blendMode: BlendMode.plus,
    );

    // Layer 3: Core Layer (Smallest)
    _paintLayer(
      canvas,
      size,
      positions[2],
      [colors[4], colors[5]],
      size.shortestSide * 0.5,
      blurFilter,
      blendMode: BlendMode.plus,
    );
  }

  void _paintLayer(
      Canvas canvas,
      Size size,
      Offset position,
      List<Color> layerColors,
      double radius,
      MaskFilter maskFilter, {
        BlendMode? blendMode,
      }) {
    final paint = Paint()..maskFilter = maskFilter;

    if (blendMode != null) {
      paint.blendMode = blendMode;
    }

    final centerAlignment = Alignment(position.dx * 2 - 1, position.dy * 2 - 1);
    final centerOffset = Offset(position.dx * size.width, position.dy * size.height);

    paint.shader = RadialGradient(
      center: centerAlignment,
      radius: 1.5,
      colors: layerColors,
    ).createShader(Rect.fromCircle(center: centerOffset, radius: radius));
    
    canvas.drawCircle(centerOffset, radius, paint);
  }

  @override
  bool shouldRepaint(covariant NebulaBackgroundPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.colors != colors ||
        oldDelegate.blurSigma != blurSigma;
  }
}
