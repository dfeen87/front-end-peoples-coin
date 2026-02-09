import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A data model for a technical system, including visual and descriptive data.
enum TechSystemIcon {
  actSubmission,
  governance,
  ledger,
  tokenomics,
}

@immutable
class TechSystem {
  static const Map<TechSystemIcon, IconData> _iconByKey = {
    TechSystemIcon.actSubmission: Icons.edit_document,
    TechSystemIcon.governance: Icons.gavel,
    TechSystemIcon.ledger: Icons.public,
    TechSystemIcon.tokenomics: Icons.wallet,
  };

  final TechSystemIcon iconKey;
  final String title;
  final String description;
  final Color color;
  final String code;

  const TechSystem({
    required this.iconKey,
    required this.title,
    required this.description,
    required this.color,
    required this.code,
  });

  IconData get icon => _iconByKey[iconKey] ?? Icons.settings;

  /// Creates a new instance of [TechSystem] with optional new values.
  TechSystem copyWith({
    TechSystemIcon? iconKey,
    String? title,
    String? description,
    Color? color,
    String? code,
  }) {
    return TechSystem(
      iconKey: iconKey ?? this.iconKey,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      code: code ?? this.code,
    );
  }

  /// Converts this model into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'icon_key': iconKey.name,
      'title': title,
      'description': description,
      'color': color.value,
      'code': code,
    };
  }

  /// Creates a [TechSystem] instance from a JSON map.
  factory TechSystem.fromJson(Map<String, dynamic> json) {
    final iconKeyName = json['icon_key'] as String?;
    final iconKey = TechSystemIcon.values.firstWhere(
      (value) => value.name == iconKeyName,
      orElse: () => TechSystemIcon.governance,
    );
    return TechSystem(
      iconKey: iconKey,
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
          iconKey == other.iconKey &&
          title == other.title &&
          description == other.description &&
          color == other.color &&
          code == other.code;

  @override
  int get hashCode =>
      iconKey.hashCode ^
      title.hashCode ^
      description.hashCode ^
      color.hashCode ^
      code.hashCode;

  @override
  String toString() {
    return 'TechSystem(title: $title, description: $description)';
  }
}
