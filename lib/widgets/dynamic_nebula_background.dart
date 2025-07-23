import 'package:flutter/material.dart';
import 'nebula_background_painter.dart';

class DynamicNebulaBackground extends StatefulWidget {
  final List<Color> colors;
  final double noiseIntensity;

  const DynamicNebulaBackground({
    super.key,
    this.colors = const [
      Color(0xFF8A2BE2), // BlueViolet
      Color(0xFFCC6699), // Muted Fuchsia
      Color(0xFF00BFFF), // DeepSkyBlue
      Color(0xFFDA70D6), // Orchid
    ],
    this.noiseIntensity = 0.05,
  });

  @override
  State<DynamicNebulaBackground> createState() => _DynamicNebulaBackgroundState();
}

class _DynamicNebulaBackgroundState extends State<DynamicNebulaBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // NEW: State variables to track 2D position and velocity.
  // The values are normalized (0.0 to 1.0 represents the screen).
  Offset _position = const Offset(0.5, 0.5); // Start at the center
  Offset _velocity = const Offset(0.0008, 0.0012); // Speed and direction (X, Y)

  @override
  void initState() {
    super.initState();
    // UPDATED: The controller now just acts as a ticker to drive our animation loop.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Duration doesn't matter as much here
    )..addListener(_updateAnimation)..repeat(); // Listen and repeat forever
  }

  // NEW: This function runs on every animation frame.
  void _updateAnimation() {
    // These are the boundaries for our normalized coordinates.
    const double minX = 0.0, maxX = 1.0;
    const double minY = 0.0, maxY = 1.0;

    // Check for collision with horizontal edges (left/right)
    if (_position.dx <= minX || _position.dx >= maxX) {
      // Reverse the horizontal velocity to "bounce"
      _velocity = Offset(-_velocity.dx, _velocity.dy);
    }

    // Check for collision with vertical edges (top/bottom)
    if (_position.dy <= minY || _position.dy >= maxY) {
      // Reverse the vertical velocity to "bounce"
      _velocity = Offset(_velocity.dx, -_velocity.dy);
    }

    // Update the position and tell Flutter to repaint the screen
    setState(() {
      _position += _velocity;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        // UPDATED: We now pass the calculated position directly to the painter.
        painter: NebulaBackgroundPainter(
          center: _position, // Pass the current position
          colors: widget.colors,
          noiseIntensity: widget.noiseIntensity,
        ),
      ),
    );
  }
}
