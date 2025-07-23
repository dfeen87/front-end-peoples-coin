// lib/models/goodwill_action.dart

// This enum should match the one in your Dart code.
// If it's in another file, you can remove this and import it instead.
enum GoodwillStatus {
  pendingVerification,
  verified,
  rejected,
  unknown // A fallback for safety
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

  // NEW: A factory constructor to create a GoodwillAction from a JSON map.
  factory GoodwillAction.fromJson(Map<String, dynamic> json) {
    return GoodwillAction(
      id: json['id'],
      performerUserId: json['performer_user_id'],
      actionType: json['action_type'],
      description: json['description'],
      contextualData: json['contextual_data'] ?? {},
      lovesValue: json['loves_value'],
      // This safely handles the status enum from a string.
      status: _statusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Helper function to safely convert a string to our GoodwillStatus enum.
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
}
