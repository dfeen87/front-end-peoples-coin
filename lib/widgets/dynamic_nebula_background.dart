// lib/widgets/dynamic_nebula_background.dart

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class DynamicNebulaBackground extends StatefulWidget {
  final double speed;
  final double blurSigma;
  final bool enableAdaptivePerformance;
  final double organicNoiseAmount;
  final double pulsationAmount;

  const DynamicNebulaBackground({
    super.key,
    this.speed = 0.2,
    this.blurSigma = 70.0,
    this.enableAdaptivePerformance = true,
    this.organicNoiseAmount = 0.02,
    this.pulsationAmount = 0.15,
  });

  @override
  State<DynamicNebulaBackground> createState() => _DynamicNebulaBackgroundState();
}

class _DynamicNebulaBackgroundState extends State<DynamicNebulaBackground>
    with TickerProviderStateMixin {
  // Constants for better maintainability
  static const Duration _positionDuration = Duration(seconds: 40);
  static const Duration _colorDuration = Duration(seconds: 30);
  static const Duration _thermalCycleDuration = Duration(seconds: 120); // 2-minute thermal cycle
  static const double _centralAreaBounds = 0.8;
  static const double _centralAreaOffset = 0.1;
  static const double _baseAmplitudeMin = 0.1;
  static const double _baseAmplitudeRange = 0.1;
  static const double _lowEndScreenThreshold = 400.0;
  
  final Random _random = Random();
  
  late AnimationController _positionController;
  late AnimationController _colorController;
  late AnimationController _thermalController;
  
  // Layer Properties
  late final List<LayerProperties> _layers;
  
  // Performance adaptation
  late final bool _isLowEndDevice;
  late final double _adaptiveBlurSigma;
  late final int _layerCount;

  @override
  void initState() {
    super.initState();
    _initializePerformanceSettings();
    _initializeLayers();
    _initializeControllers();
  }
  
  void _initializePerformanceSettings() {
    // Simple performance detection - you could make this more sophisticated
    _isLowEndDevice = widget.enableAdaptivePerformance && 
        MediaQuery.of(context).size.shortestSide < _lowEndScreenThreshold;
    
    _adaptiveBlurSigma = _isLowEndDevice ? widget.blurSigma * 0.6 : widget.blurSigma;
    _layerCount = _isLowEndDevice ? 2 : 3;
  }
  
  void _initializeLayers() {
    _layers = List.generate(_layerCount, (index) => LayerProperties(
      initialPosition: _getRandomOffset(),
      amplitude: _baseAmplitudeMin + _random.nextDouble() * _baseAmplitudeRange,
      phaseShift: _random.nextDouble() * 2 * pi,
      orbitFrequencyX: 1.0 + _random.nextDouble() * 0.5, // Varied orbital frequencies
      orbitFrequencyY: 0.8 + _random.nextDouble() * 0.7,
      pulsePhase: _random.nextDouble() * 2 * pi,
      pulseFrequency: 0.3 + _random.nextDouble() * 0.4,
    ));
  }
  
  void _initializeControllers() {
    // Controller for smooth, orbital movement
    _positionController = AnimationController(
      vsync: this,
      duration: _positionDuration,
    )..repeat(reverse: true);

    // Controller for color evolution
    _colorController = AnimationController(
      vsync: this,
      duration: _colorDuration,
    )..repeat();
    
    // Controller for thermal cycles (slower, like real lava lamp heating)
    _thermalController = AnimationController(
      vsync: this,
      duration: _thermalCycleDuration,
    )..repeat();
  }

  /// Generates a random Offset within the screen bounds with central bias.
  Offset _getRandomOffset() => Offset(
      _random.nextDouble() * _centralAreaBounds + _centralAreaOffset,
      _random.nextDouble() * _centralAreaBounds + _centralAreaOffset);

  @override
  void dispose() {
    _positionController.dispose();
    _colorController.dispose();
    _thermalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_positionController, _colorController, _thermalController]),
      builder: (context, child) {
        final double positionTime = _positionController.value * 2 * pi;
        final double pulseTime = _positionController.value * 2 * pi * 2; // Faster pulse cycle
        final double thermalTime = _thermalController.value * 2 * pi;

        // Calculate new positions with organic movement
        final positions = _layers.map((layer) => 
          _calculateOrganicPosition(layer, positionTime)).toList();
        
        // Calculate dynamic radii with pulsation
        final radii = _layers.asMap().entries.map((entry) => 
          _calculateDynamicRadius(entry.key, entry.value, pulseTime)).toList();

        return CustomPaint(
          painter: NebulaBackgroundPainter(
            positions: positions,
            radii: radii,
            colors: _getThermodynamicColors(thermalTime),
            blurSigma: _adaptiveBlurSigma,
            layerCount: _layerCount,
          ),
          child: Container(),
        );
      },
    );
  }

  /// Calculates organic position with noise for more natural movement.
  Offset _calculateOrganicPosition(LayerProperties layer, double time) {
    // Base orbital movement
    final baseX = layer.initialPosition.dx + 
        layer.amplitude * sin(time * layer.orbitFrequencyX + layer.phaseShift);
    final baseY = layer.initialPosition.dy + 
        layer.amplitude * cos(time * layer.orbitFrequencyY + layer.phaseShift);
    
    // Add organic noise for less predictable movement
    final noiseX = sin(time * 3.7 + layer.phaseShift) * widget.organicNoiseAmount;
    final noiseY = cos(time * 2.3 + layer.phaseShift * 1.5) * widget.organicNoiseAmount * 0.8;
    
    return Offset(
      (baseX + noiseX).clamp(0.0, 1.0),
      (baseY + noiseY).clamp(0.0, 1.0),
    );
  }
  
  /// Calculates dynamic radius with pulsation effect.
  double _calculateDynamicRadius(int layerIndex, LayerProperties layer, double time) {
    final baseRadii = [0.9, 0.7, 0.5]; // Different base sizes for each layer
    final baseRadius = baseRadii[layerIndex % baseRadii.length];
    
    // Pulsation effect
    final pulsation = 1.0 + widget.pulsationAmount * 
        sin(time * layer.pulseFrequency + layer.pulsePhase);
    
    return baseRadius * pulsation;
  }

  /// Generates thermodynamically evolving colors like a real lava lamp.
  List<Color> _getThermodynamicColors(double thermalTime) {
    final double temperature = sin(thermalTime); // -1 to 1 temperature cycle
    final double colorTime = _colorController.value;
    
    return List.generate(6, (i) {
      // Base hue rotation
      final double baseHue = (colorTime * 360 + i * 30) % 360;
      
      // Temperature affects saturation and lightness
      final double saturation = (0.7 + 0.2 * temperature).clamp(0.4, 1.0);
      final double lightness = (0.5 + 0.15 * temperature).clamp(0.3, 0.8);
      
      // Slightly shift hue based on temperature for color temperature effect
      final double thermalHueShift = temperature * 15; // Warm/cool shift
      final double finalHue = (baseHue + thermalHueShift) % 360;
      
      return HSLColor.fromAHSL(1.0, finalHue, saturation, lightness).toColor();
    });
  }
}

/// Data class to hold layer properties for better organization.
class LayerProperties {
  final Offset initialPosition;
  final double amplitude;
  final double phaseShift;
  final double orbitFrequencyX;
  final double orbitFrequencyY;
  final double pulsePhase;
  final double pulseFrequency;

  const LayerProperties({
    required this.initialPosition,
    required this.amplitude,
    required this.phaseShift,
    required this.orbitFrequencyX,
    required this.orbitFrequencyY,
    required this.pulsePhase,
    required this.pulseFrequency,
  });
}

class NebulaBackgroundPainter extends CustomPainter {
  final List<Offset> positions;
  final List<double> radii;
  final List<Color> colors;
  final double blurSigma;
  final int layerCount;

  NebulaBackgroundPainter({
    required this.positions,
    required this.radii,
    required this.colors,
    required this.blurSigma,
    required this.layerCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark background
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0C0C0C));

    final blurFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    final blendModes = [null, BlendMode.plus, BlendMode.plus]; // Base layer normal, others additive

    // Paint each layer
    for (int i = 0; i < layerCount && i < positions.length; i++) {
      _paintLayer(
        canvas,
        size,
        positions[i],
        [colors[i * 2], colors[i * 2 + 1]],
        size.shortestSide * radii[i],
        blurFilter,
        blendMode: blendModes[i],
      );
    }
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
      stops: const [0.0, 1.0], // Sharper gradient for more defined blobs
    ).createShader(Rect.fromCircle(center: centerOffset, radius: radius));
    
    canvas.drawCircle(centerOffset, radius, paint);
  }

  @override
  bool shouldRepaint(covariant NebulaBackgroundPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.radii != radii ||
        oldDelegate.colors != colors ||
        oldDelegate.blurSigma != blurSigma ||
        oldDelegate.layerCount != layerCount;
  }
}
