import 'package:flutter/foundation.dart';

/// Immutable model representing a goodwill action to send to the backend API.
@immutable
class GoodwillActionToSend {
  final String performerUserId; // Matches backend expected field name
  final String actionType;
  final String description;
  final int lovesValue;
  final Map<String, dynamic> contextualData;
  final DateTime timestamp;

  const GoodwillActionToSend({
    required this.performerUserId,
    required this.actionType,
    required this.description,
    required this.lovesValue,
    Map<String, dynamic>? contextualData,
    required this.timestamp,
  }) : contextualData = contextualData ?? const {};

  /// Creates a new instance of [GoodwillActionToSend] with optional new values.
  GoodwillActionToSend copyWith({
    String? performerUserId,
    String? actionType,
    String? description,
    int? lovesValue,
    Map<String, dynamic>? contextualData,
    DateTime? timestamp,
  }) {
    return GoodwillActionToSend(
      performerUserId: performerUserId ?? this.performerUserId,
      actionType: actionType ?? this.actionType,
      description: description ?? this.description,
      lovesValue: lovesValue ?? this.lovesValue,
      contextualData: contextualData ?? this.contextualData,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Converts this model into a JSON map suitable for API requests.
  Map<String, dynamic> toJson() => {
    'performer_user_id': performerUserId,
    'action_type': actionType,
    'description': description,
    'loves_value': lovesValue,
    'contextual_data': contextualData,
    'timestamp': timestamp.toIso8601String(),
  };
}

