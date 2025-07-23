import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class NebulaBackgroundPainter extends CustomPainter {
  // UPDATED: The painter now accepts a direct Offset for the center.
  final Offset center;
  final List<Color> colors;
  final double noiseIntensity;

  NebulaBackgroundPainter({
    required this.center, // Changed from 'animation'
    required this.colors,
    required this.noiseIntensity,
  }) : super(repaint: ValueNotifier<Offset>(center)); // Use a ValueNotifier for repaint

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Create the gradient using the new 'center' property
    final gradient = RadialGradient(
      center: Alignment(center.dx * 2 - 1, center.dy * 2 - 1), // Convert 0-1 to -1-1
      radius: 1.5,
      colors: colors,
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Optional: Add noise for texture
    final random = Random(123); // Use a fixed seed for consistent noise
    for (int i = 0; i < 5000 * noiseIntensity; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final color = Color.fromRGBO(255, 255, 255, random.nextDouble() * 0.2);
      canvas.drawCircle(Offset(x, y), 0.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant NebulaBackgroundPainter oldDelegate) {
    // Repaint only if the center position or other properties change.
    return oldDelegate.center != center ||
        oldDelegate.colors != colors ||
        oldDelegate.noiseIntensity != noiseIntensity;
  }
}
