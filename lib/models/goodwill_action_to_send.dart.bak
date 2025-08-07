// lib/models/goodwill_action_to_send.dart
import 'package:flutter/foundation.dart';

/// A model for sending a new goodwill action to the API.
@immutable
class GoodwillActionToSend {
  final String performerUserId; // Correct parameter name
  final String actionType;
  final String description;
  final int lovesValue;
  final Map<String, dynamic>? contextualData;
  final DateTime timestamp; // Field for timestamp

  const GoodwillActionToSend({
    required this.performerUserId,
    required this.actionType,
    required this.description,
    required this.lovesValue,
    this.contextualData,
    required this.timestamp,
  });

  /// Converts this object into a JSON map for the API request body.
  Map<String, dynamic> toJson() {
    return {
      'performer_user_id': performerUserId, // Matches backend expected key
      'action_type': actionType,
      'description': description,
      'loves_value': lovesValue,
      'contextual_data': contextualData ?? {},
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

