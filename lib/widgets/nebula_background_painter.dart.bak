import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class NebulaBackgroundPainter extends CustomPainter {
  final Offset center;  // Normalized 0.0 – 1.0
  final List<Color> colors;
  final double noiseIntensity;
  final Random noiseRandom;

  NebulaBackgroundPainter({
    required this.center,
    required this.colors,
    required this.noiseIntensity,
    required this.noiseRandom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Scale normalized center (0–1) to canvas alignment (-1 to 1)
    final alignmentCenter = Alignment(center.dx * 2 - 1, center.dy * 2 - 1);

    // Radial gradient centered at scaled alignment
    final gradient = RadialGradient(
      center: alignmentCenter,
      radius: 1.0,
      colors: colors,
      stops: List.generate(colors.length, (i) => i / (colors.length - 1)),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect);

    // Paint gradient background
    canvas.drawRect(rect, paint);

    // Star-like noise overlay
    final noisePaint = Paint();
    final int noiseCount = (5000 * noiseIntensity).round();

    for (int i = 0; i < noiseCount; i++) {
      final x = noiseRandom.nextDouble() * size.width;
      final y = noiseRandom.nextDouble() * size.height;
      noisePaint.color = Colors.white.withOpacity(noiseRandom.nextDouble() * 0.12);
      canvas.drawCircle(Offset(x, y), 0.4, noisePaint);
    }
  }

  @override
  bool shouldRepaint(covariant NebulaBackgroundPainter oldDelegate) {
    return oldDelegate.center != center ||
        !listEquals(oldDelegate.colors, colors) ||
        oldDelegate.noiseIntensity != noiseIntensity;
  }
}

