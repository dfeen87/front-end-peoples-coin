import 'package:flutter/material.dart';

class TechSystem {
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

  factory TechSystem.fromJson(Map<String, dynamic> json) {
    return TechSystem(
      icon: IconData(
        json['icon_code_point'],
        fontFamily: json['icon_font_family'],
        fontPackage: json['icon_font_package'],
        matchTextDirection: json['icon_match_text_direction'] ?? false,
      ),
      title: json['title'],
      description: json['description'],
      color: Color(json['color']),
      code: json['code'],
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

