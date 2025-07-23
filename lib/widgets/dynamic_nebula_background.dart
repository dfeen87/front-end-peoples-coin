// lib/widgets/dynamic_nebula_background.dart

import 'package:flutter/material.dart';
import 'nebula_background_painter.dart';

class DynamicNebulaBackground extends StatefulWidget {
  // ... (no changes in this part)
  final List<Color> colors;
  final double noiseIntensity;

  const DynamicNebulaBackground({
    super.key,
    this.colors = const [
      Color(0xFF8A2BE2),
      Color(0xFFCC6699),
      Color(0xFF00BFFF),
      Color(0xFFDA70D6),
    ],
    this.noiseIntensity = 0.05,
  });

  @override
  State<DynamicNebulaBackground> createState() => _DynamicNebulaBackgroundState();
}

class _DynamicNebulaBackgroundState extends State<DynamicNebulaBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _position = const Offset(0.5, 0.5);
  // Let's use the faster velocity we discussed
  Offset _velocity = const Offset(0.0016, 0.0024);

  @override
  void initState() {
    super.initState();
    // UPDATED: We remove the listener here. The AnimatedBuilder will handle it.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  // This function is no longer needed because the logic is in AnimatedBuilder
  // void _updateAnimation() { ... }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NEW: We wrap the CustomPaint in an AnimatedBuilder.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // This logic now runs on every tick of the animation
        const double minX = 0.0, maxX = 1.0;
        const double minY = 0.0, maxY = 1.0;

        // Check for collision and reverse velocity
        if (_position.dx <= minX || _position.dx >= maxX) {
          _velocity = Offset(-_velocity.dx, _velocity.dy);
        }
        if (_position.dy <= minY || _position.dy >= maxY) {
          _velocity = Offset(_velocity.dx, -_velocity.dy);
        }
        _position += _velocity;

        // The builder returns the CustomPaint, which gets rebuilt efficiently.
        return SizedBox.expand(
          child: CustomPaint(
            painter: NebulaBackgroundPainter(
              center: _position,
              colors: widget.colors,
              noiseIntensity: widget.noiseIntensity,
            ),
          ),
        );
      },
    );
  }
}
