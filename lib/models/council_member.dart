import 'package:flutter/foundation.dart';

@immutable
class CouncilMember {
  final String id;
  final String userId;
  final String role;
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

  factory CouncilMember.fromJson(Map<String, dynamic> json) {
    return CouncilMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
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
      'role': role,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

