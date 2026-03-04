import 'package:flutter/foundation.dart';

@immutable
class Tag {
  final String id;
  final String name;

  const Tag({
    required this.id,
    required this.name,
  });

  /// Creates a new instance of [Tag] with optional new values.
  Tag copyWith({
    String? id,
    String? name,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

