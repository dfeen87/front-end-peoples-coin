import 'package:flutter/foundation.dart';

/// A simplified model for sending a new goodwill action to the API.
@immutable
class GoodwillActionToSend {
  final String userId;
  final String actionType;
  final String description;
  final DateTime timestamp;
  final int lovesValue;
  final Map<String, dynamic> contextualData;

  const GoodwillActionToSend({
    required this.userId,
    required this.actionType,
    required this.description,
    required this.timestamp,
    required this.lovesValue,
    this.contextualData = const {},
  });

  /// Converts this object into a JSON map for the API request body.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'action_type': actionType,
      'description': description,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'loves_value': lovesValue,
      'contextual_data': contextualData,
    };
  }
}
