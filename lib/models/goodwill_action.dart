enum GoodwillStatus {
  pendingVerification,
  verified,
  rejected,
  unknown, // A fallback for safety
}

class GoodwillAction {
  final String id;
  final String performerUserId;
  final String actionType;
  final String description;
  final Map<String, dynamic> contextualData;
  final int lovesValue;
  final GoodwillStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoodwillAction({
    required this.id,
    required this.performerUserId,
    required this.actionType,
    required this.description,
    required this.contextualData,
    required this.lovesValue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create a GoodwillAction from a JSON map.
  factory GoodwillAction.fromJson(Map<String, dynamic> json) {
    return GoodwillAction(
      id: json['id'] as String,
      performerUserId: json['performer_user_id'] as String,
      actionType: json['action_type'] as String,
      description: json['description'] as String,
      contextualData: (json['contextual_data'] as Map<String, dynamic>?) ?? {},
      lovesValue: json['loves_value'] as int,
      status: _statusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Helper to safely convert a string to GoodwillStatus enum.
  static GoodwillStatus _statusFromString(String status) {
    switch (status.toUpperCase()) {
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
      'contextual_data': contextualData,
      'loves_value': lovesValue,
      'status': status.toString().split('.').last.toUpperCase(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

