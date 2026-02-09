import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A data model for a technical system, including visual and descriptive data.
@immutable
class TechSystem {
  static const Map<int, IconData> _iconByCodePoint = {
    Icons.cloud.codePoint: Icons.cloud,
    Icons.settings.codePoint: Icons.settings,
    Icons.security.codePoint: Icons.security,
    Icons.storage.codePoint: Icons.storage,
    Icons.code.codePoint: Icons.code,
    Icons.memory.codePoint: Icons.memory,
    Icons.account_tree.codePoint: Icons.account_tree,
  };

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String code;

  const TechSystem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.code,
  });

  /// Creates a new instance of [TechSystem] with optional new values.
  TechSystem copyWith({
    IconData? icon,
    String? title,
    String? description,
    Color? color,
    String? code,
  }) {
    return TechSystem(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      code: code ?? this.code,
    );
  }

  /// Converts this model into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'icon_code_point': icon.codePoint,
      'icon_font_family': icon.fontFamily,
      'icon_font_package': icon.fontPackage,
      'icon_match_text_direction': icon.matchTextDirection,
      'title': title,
      'description': description,
      'color': color.value,
      'code': code,
    };
  }

  /// Creates a [TechSystem] instance from a JSON map.
  factory TechSystem.fromJson(Map<String, dynamic> json) {
    final iconCodePoint = json['icon_code_point'] as int?;
    return TechSystem(
      icon: _iconByCodePoint[iconCodePoint] ?? Icons.settings,
      title: json['title'] as String,
      description: json['description'] as String,
      color: Color(json['color'] as int),
      code: json['code'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechSystem &&
          runtimeType == other.runtimeType &&
          icon.codePoint == other.icon.codePoint &&
          icon.fontFamily == other.icon.fontFamily &&
          icon.fontPackage == other.icon.fontPackage &&
          icon.matchTextDirection == other.icon.matchTextDirection &&
          title == other.title &&
          description == other.description &&
          color == other.color &&
          code == other.code;

  @override
  int get hashCode =>
      icon.codePoint.hashCode ^
      icon.fontFamily.hashCode ^
      icon.fontPackage.hashCode ^
      icon.matchTextDirection.hashCode ^
      title.hashCode ^
      description.hashCode ^
      color.hashCode ^
      code.hashCode;

  @override
  String toString() {
    return 'TechSystem(title: $title, description: $description)';
  }
}
