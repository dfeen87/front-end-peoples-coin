import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NebulaState extends ChangeNotifier {
  Offset _center = const Offset(0.5, 0.5);
  List<Color> _colors = [Colors.deepPurple, Colors.indigo, Colors.blueAccent];
  double _noiseIntensity = 0.1;
  final Random noiseRandom;

  NebulaState()
      : noiseRandom = Random(123); // fixed seed for consistent noise pattern

  Offset get center => _center;
  List<Color> get colors => _colors;
  double get noiseIntensity => _noiseIntensity;

  set center(Offset newCenter) {
    if (_center != newCenter) {
      _center = newCenter;
      notifyListeners();
    }
  }

  set colors(List<Color> newColors) {
    if (!listEquals(_colors, newColors)) {
      _colors = newColors;
      notifyListeners();
    }
  }

  set noiseIntensity(double newIntensity) {
    if (_noiseIntensity != newIntensity) {
      _noiseIntensity = newIntensity;
      notifyListeners();
    }
  }
}

