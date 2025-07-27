// lib/widgets/dynamic_nebula_background.dart

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  
  // --- Animation Controllers ---
  late Ticker _movementTicker;
  late AnimationController _colorController;

  // --- Layer Properties (Position & Velocity) ---
  late Offset _position1, _position2, _position3;
  late Offset _velocity1, _velocity2, _velocity3;

  @override
  void initState() {
    super.initState();
    _initializeLayers();

    // Ticker for physical movement of layers
    _movementTicker = createTicker(_updateMovement)..start();

    // Controller for the perpetual color evolution
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 5), // Very slow evolution
    )..repeat();
  }
  
  /// Sets the initial random positions and velocities for the three layers.
  void _initializeLayers() {
    _position1 = _getRandomOffset();
    _position2 = _getRandomOffset();
    _position3 = _getRandomOffset();

    _velocity1 = _getRandomVelocity();
    _velocity2 = _getRandomVelocity();
    _velocity3 = _getRandomVelocity();
  }

  /// Generates a random Offset within the screen bounds (0.0 to 1.0).
  Offset _getRandomOffset() => Offset(_random.nextDouble(), _random.nextDouble());

  /// Generates a random velocity vector.
  Offset _getRandomVelocity() => Offset(
      (_random.nextDouble() - 0.5) * 0.01, (_random.nextDouble() - 0.5) * 0.01);

  /// This is the corrected movement logic.
  /// It now updates the velocity of each layer when a bounce occurs.
  void _updateMovement(Duration elapsed) {
    setState(() {
      // Calculate and update state for layer 1
      final state1 = _calculateNextState(_position1, _velocity1);
      _position1 = state1.position;
      _velocity1 = state1.velocity;

      // Calculate and update state for layer 2
      final state2 = _calculateNextState(_position2, _velocity2);
      _position2 = state2.position;
      _velocity2 = state2.velocity;

      // Calculate and update state for layer 3
      final state3 = _calculateNextState(_position3, _velocity3);
      _position3 = state3.position;
      _velocity3 = state3.velocity;
    });
  }
  
  /// Calculates the next position and velocity, handling wall bounces.
  /// Returns a record containing the new position and new velocity.
  ({Offset position, Offset velocity}) _calculateNextState(
      Offset position, Offset velocity) {
    var newPosition = position + (velocity * widget.speed);
    var newVelocity = velocity;

    // Check for bounce on X-axis
    if (newPosition.dx < 0 || newPosition.dx > 1) {
      newVelocity = Offset(-newVelocity.dx, newVelocity.dy);
    }

    // Check for bounce on Y-axis
    if (newPosition.dy < 0 || newPosition.dy > 1) {
      newVelocity = Offset(newVelocity.dx, -newVelocity.dy);
    }
    
    // Clamp position to ensure it stays within the screen bounds.
    newPosition = Offset(
      newPosition.dx.clamp(0.0, 1.0),
      newPosition.dy.clamp(0.0, 1.0),
    );

    return (position: newPosition, velocity: newVelocity);
  }

  @override
  void dispose() {
    _movementTicker.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using AnimatedBuilder is more efficient than calling setState in the controller listener.
    return AnimatedBuilder(
      animation: _colorController,
      builder: (context, child) {
        return CustomPaint(
          painter: NebulaBackgroundPainter(
            positions: [_position1, _position2, _position3],
            colors: _getEvolvingColors(),
            blurSigma: widget.blurSigma,
          ),
          child: Container(),
        );
      },
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
      blendMode: BlendMode.plus, // CORRECTED from .add
    );

    // Layer 3: Core Layer (Smallest)
    _paintLayer(
      canvas,
      size,
      positions[2],
      [colors[4], colors[5]],
      size.shortestSide * 0.5,
      blurFilter,
      blendMode: BlendMode.plus, // CORRECTED from .add
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
