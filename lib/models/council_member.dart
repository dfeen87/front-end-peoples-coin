import 'package:flutter/foundation.dart';

/// Defines the possible roles a Council Member can have.
/// Using an enum provides type safety and prevents errors from typos.
enum CouncilRole {
  councilor,
  chair,
  secretary,
  treasurer,
}

@immutable
class CouncilMember {
  final String id;
  final String userId;
  final CouncilRole role;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CouncilMember({
    required this.id,
    required this.userId,
    required this.role,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new instance of [CouncilMember] with optional new values.
  CouncilMember copyWith({
    String? id,
    String? userId,
    CouncilRole? role,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CouncilMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CouncilMember.fromJson(Map<String, dynamic> json) {
    return CouncilMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      // Convert the string role from JSON to the enum value
      role: CouncilRole.values.firstWhere(
        (e) => e.name == (json['role'] as String).toLowerCase(),
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      // Convert the enum value to its string name for JSON
      'role': role.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

