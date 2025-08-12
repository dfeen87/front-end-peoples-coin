import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// The main widget that cycles through multiple celebration effects.
class CyclingCelebrationOverlay extends StatefulWidget {
  final Duration cycleDuration;

  const CyclingCelebrationOverlay({Key? key, this.cycleDuration = const Duration(seconds: 4)}) : super(key: key);

  @override
  State<CyclingCelebrationOverlay> createState() => _CyclingCelebrationOverlayState();
}

class _CyclingCelebrationOverlayState extends State<CyclingCelebrationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Widget Function(Animation<double>)> _effectsBuilders = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _effectsBuilders.addAll([
      (anim) => ConfettiOverlay(controller: anim),
      (anim) => HeartsOverlay(controller: anim),
      (anim) => SparklesOverlay(controller: anim),
    ]);

    _controller = AnimationController(vsync: this, duration: widget.cycleDuration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _effectsBuilders.length;
        });
        _controller.forward(from: 0.0);
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builder = _effectsBuilders[_currentIndex];
    return Positioned.fill(
      child: IgnorePointer(
        child: builder(_controller),
      ),
    );
  }
}

/// CONFETTI EFFECT

class ConfettiOverlay extends StatelessWidget {
  final Animation<double> controller;

  const ConfettiOverlay({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: ConfettiPainter(progress: controller.value),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final int particleCount = (progress * 100).toInt();

    for (int i = 0; i < particleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height * (1 - progress);
      paint.color = Color.fromARGB(
        (255 * (1 - progress)).toInt(),
        _random.nextInt(256),
        _random.nextInt(256),
        _random.nextInt(256),
      );

      final radius = _random.nextDouble() * 4 + 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

/// HEARTS EFFECT

class HeartsOverlay extends StatelessWidget {
  final Animation<double> controller;

  const HeartsOverlay({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: HeartsPainter(progress: controller.value),
      ),
    );
  }
}

class HeartsPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  HeartsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    int particleCount = (progress * 40).toInt();

    for (int i = 0; i < particleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = size.height - (_random.nextDouble() * size.height * progress);
      final scale = 0.5 + _random.nextDouble();

      paint.color = Colors.red.withOpacity(1 - progress);

      _drawHeart(canvas, paint, Offset(x, y), 10 * scale);
    }
  }

  void _drawHeart(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();

    final double x = center.dx;
    final double y = center.dy;
    final double s = size / 2;

    path.moveTo(x, y + s / 4);
    path.cubicTo(x, y, x - s, y, x - s, y + s / 2);
    path.cubicTo(x - s, y + s, x, y + s * 1.5, x, y + s * 2);
    path.cubicTo(x, y + s * 1.5, x + s, y + s, x + s, y + s / 2);
    path.cubicTo(x + s, y, x, y, x, y + s / 4);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeartsPainter oldDelegate) => oldDelegate.progress != progress;
}

/// SPARKLES EFFECT

class SparklesOverlay extends StatelessWidget {
  final Animation<double> controller;

  const SparklesOverlay({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: SparklesPainter(progress: controller.value),
      ),
    );
  }
}

class SparklesPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  SparklesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final int sparkleCount = (progress * 80).toInt();

    for (int i = 0; i < sparkleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;

      paint.color = Colors.white.withOpacity(1 - progress);

      _drawSparkle(canvas, paint, Offset(x, y), 3 + 2 * (1 - progress));
    }
  }

  void _drawSparkle(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    final s = size / 2;

    path.moveTo(center.dx, center.dy - s);
    path.lineTo(center.dx + s / 3, center.dy - s / 3);
    path.lineTo(center.dx + s, center.dy);
    path.lineTo(center.dx + s / 3, center.dy + s / 3);
    path.lineTo(center.dx, center.dy + s);
    path.lineTo(center.dx - s / 3, center.dy + s / 3);
    path.lineTo(center.dx - s, center.dy);
    path.lineTo(center.dx - s / 3, center.dy - s / 3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklesPainter oldDelegate) => oldDelegate.progress != progress;
}

