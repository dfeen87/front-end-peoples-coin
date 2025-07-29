// models/tech_system.dart
// This file defines the TechSystem data model with all its properties.

import 'package:flutter/material.dart'; // Required for IconData and Color

/// Represents a technical system with its associated code,
/// and display properties for UI.
class TechSystem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String code;

  /// Creates a [TechSystem] instance.
  ///
  /// [icon]: The icon associated with the system.
  /// [title]: The title of the system.
  /// [description]: A brief description of the system.
  /// [color]: A color associated with the system for UI theming.
  /// [code]: The string content of the system's code.
  const TechSystem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.code,
  });
}

