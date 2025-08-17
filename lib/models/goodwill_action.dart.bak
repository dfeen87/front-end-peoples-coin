import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Defines the possible states of a GoodwillAction.
enum GoodwillStatus {
  pendingVerification,
  verified,
  rejected,
  unknown, // Fallback for safety
}

/// A data model representing a single act of goodwill.
/// It is immutable, meaning its state cannot change after it is created.
@immutable
class GoodwillAction {
  final String id;
  final String performerUserId;
  final String actionType;
  final String description;
  final Map<String, dynamic> contextualData; // Changed from UnmodifiableMapView
  final int lovesValue;
  final GoodwillStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Enhanced scoring fields
  final int timeSpentMinutes;
  final int userImpactScore;
  final int? calculatedScore;

  const GoodwillAction({
    required this.id,
    required this.performerUserId,
    required this.actionType,
    required this.description,
    required this.contextualData, // Simplified - just store the map
    required this.lovesValue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.timeSpentMinutes = 0,
    this.userImpactScore = 50,
    this.calculatedScore,
  });

  // Add timestamp getter for backward compatibility with error logs
  DateTime get timestamp => createdAt;

  // Add userId getter for backward compatibility
  String get userId => performerUserId;

  /// Creates a GoodwillAction from a JSON map.
  factory GoodwillAction.fromJson(Map<String, dynamic> json) {
    return GoodwillAction(
      id: json['id']?.toString() ?? '',
      performerUserId: json['performer_user_id']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      contextualData: _safeContextualData(json['contextual_data']),
      lovesValue: _safeInt(json['loves_value']),
      status: _statusFromString(json['status']?.toString() ?? ''),
      createdAt: _safeDate(json['created_at']),
      updatedAt: _safeDate(json['updated_at']),
      timeSpentMinutes: _safeInt(json['time_spent_minutes'], defaultValue: 0),
      userImpactScore: _safeInt(json['user_impact_score'], defaultValue: 50),
      calculatedScore: _safeNullableInt(json['calculated_score']),
    );
  }

  /// Creates a new instance of [GoodwillAction] with optional new values.
  GoodwillAction copyWith({
    String? id,
    String? performerUserId,
    String? actionType,
    String? description,
    Map<String, dynamic>? contextualData,
    int? lovesValue,
    GoodwillStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? timeSpentMinutes,
    int? userImpactScore,
    int? calculatedScore,
  }) {
    return GoodwillAction(
      id: id ?? this.id,
      performerUserId: performerUserId ?? this.performerUserId,
      actionType: actionType ?? this.actionType,
      description: description ?? this.description,
      contextualData: contextualData ?? Map<String, dynamic>.from(this.contextualData),
      lovesValue: lovesValue ?? this.lovesValue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      userImpactScore: userImpactScore ?? this.userImpactScore,
      calculatedScore: calculatedScore ?? this.calculatedScore,
    );
  }

  /// Safely converts a string to the GoodwillStatus enum.
  static GoodwillStatus _statusFromString(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PENDING_VERIFICATION':
        return GoodwillStatus.pendingVerification;
      case 'VERIFIED':
        return GoodwillStatus.verified;
      case 'REJECTED':
        return GoodwillStatus.rejected;
      default:
        return GoodwillStatus.unknown;
    }
  }

  /// Converts the GoodwillAction instance into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'performer_user_id': performerUserId,
      'action_type': actionType,
      'description': description,
      'contextual_data': Map<String, dynamic>.from(contextualData),
      'loves_value': lovesValue,
      'status': status.name.toUpperCase(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'time_spent_minutes': timeSpentMinutes,
      'user_impact_score': userImpactScore,
      'calculated_score': calculatedScore,
      // Add timestamp for API compatibility
      'timestamp': createdAt.toIso8601String(),
    };
  }

  /// Prioritizes calculatedScore if available, otherwise uses lovesValue.
  int get score => calculatedScore ?? lovesValue;

  /// Uses description as the title.
  String get title => description;

  @override
  String toString() =>
      'GoodwillAction(id: $id, actionType: $actionType, status: $status, lovesValue: $lovesValue)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoodwillAction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // --- Private safe-parsing helpers ---
  static int _safeInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int? _safeNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _safeDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Map<String, dynamic> _safeContextualData(dynamic json) {
    if (json is Map) {
      return Map<String, dynamic>.from(json);
    }
    return {};
  }
}
