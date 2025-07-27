import 'dart:math';
import 'package:flutter/material.dart';

class NebulaBackgroundPainter extends CustomPainter {
  final Offset center;  // 0..1 normalized position
  final List<Color> colors;
  final double noiseIntensity;

  NebulaBackgroundPainter({
    required this.center,
    required this.colors,
    required this.noiseIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create radial gradient centered according to normalized Offset
    final gradient = RadialGradient(
      center: Alignment(center.dx * 2 - 1, center.dy * 2 - 1), // normalize to -1..1
      radius: 1.5,
      colors: colors,
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Draw noise texture
    final random = Random(123); // fixed seed for consistent pattern
    final noiseCount = (5000 * noiseIntensity).round();
    final noisePaint = Paint();

    for (int i = 0; i < noiseCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      noisePaint.color = Colors.white.withOpacity(random.nextDouble() * 0.2);
      canvas.drawCircle(Offset(x, y), 0.5, noisePaint);
    }
  }

  @override
  bool shouldRepaint(covariant NebulaBackgroundPainter oldDelegate) {
    // Repaint if any parameter changed
    return oldDelegate.center != center ||
        !listEquals(oldDelegate.colors, colors) ||
        oldDelegate.noiseIntensity != noiseIntensity;
  }
}

