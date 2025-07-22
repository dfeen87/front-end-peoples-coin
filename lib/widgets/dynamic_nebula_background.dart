import 'package:flutter/material.dart';
import 'nebula_background_painter.dart';

class DynamicNebulaBackground extends StatefulWidget {
  // Use a default list of colors here that includes the adjusted pink
  final List<Color> colors;
  final double noiseIntensity;

  const DynamicNebulaBackground({
    super.key,
    this.colors = const [
      Color(0xFF8A2BE2), // BlueViolet (deep purple)
      Color(0xFFCC6699), // A toned-down pink (e.g., a dusty rose or muted fuchsia)
      Color(0xFF00BFFF), // DeepSkyBlue
      Color(0xFFDA70D6), // Orchid (lighter purple)
    ],
    this.noiseIntensity = 0.05,
  });

  @override
  State<DynamicNebulaBackground> createState() => _DynamicNebulaBackgroundState();
}

class _DynamicNebulaBackgroundState extends State<DynamicNebulaBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation; // Animation is now of type Offset

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40), // Longer duration for slower glide
    )..repeat(reverse: true); // Repeats back and forth for a bouncing effect

    // Create an animation that moves the center of the gradient
    // from one corner to another and back, creating a gliding/bouncing feel.
    _animation = Tween<Offset>(
      begin: const Offset(-0.1, -0.1), // Start slightly offset from center
      end: const Offset(0.1, 0.1),    // End slightly offset from center
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine, // Smooth in and out for a gentle glide
    ));
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
        painter: NebulaBackgroundPainter(
          animation: _animation,
          colors: widget.colors,
          noiseIntensity: widget.noiseIntensity,
        ),
      ),
    );
  }
}
