import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

class NebulaBackgroundPainter extends CustomPainter {
  final Animation<Offset> animation; // Animation is now for an Offset (x,y shift)
  final List<Color> colors;
  final double noiseIntensity;

  NebulaBackgroundPainter({
    required this.animation,
    this.colors = const [
      Color(0xFF8A2BE2), // BlueViolet (deep purple)
      Color(0xFFFF1493), // DeepPink
      Color(0xFF00BFFF), // DeepSkyBlue
      Color(0xFFDA70D6), // Orchid (lighter purple)
    ],
    this.noiseIntensity = 0.05,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Create a radial gradient for the base nebula shape
    final gradient = RadialGradient(
      colors: colors,
      stops: const [0.0, 0.3, 0.6, 1.0],
      // Use the animated offset directly for the center
      center: FractionalOffset(
        0.5 + animation.value.dx, // Shift X based on animation
        0.5 + animation.value.dy, // Shift Y based on animation
      ),
      radius: 1.2,
    ).createShader(rect);

    canvas.drawRect(
      rect,
      Paint()..shader = gradient,
    );

    // Optional: Add a subtle noise layer for more organic texture
    final random = Random();
    final noisePaint = Paint()
      ..color = Colors.white.withOpacity(noiseIntensity)
      ..strokeWidth = 1.0;

    for (int i = 0; i < size.width * size.height * 0.0001; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawPoints(ui.PointMode.points, [Offset(x, y)], noisePaint);
    }
  }

  @override
  bool shouldRepaint(covariant NebulaBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.colors != colors;
  }
}
