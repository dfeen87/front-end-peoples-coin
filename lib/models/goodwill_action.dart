import 'package:flutter/foundation.dart';

/// Represents the status of a Goodwill Action, mirroring the
/// `goodwill_status` ENUM in the database.
enum GoodwillStatus {
  pendingVerification,
  verified,
  rejected,
  // A fallback for unknown or new statuses from the server.
  unknown,
}

/// Represents the data structure for a single act of goodwill, mirroring the
/// `goodwill_actions` table in the database.
@immutable
class GoodwillAction {
  final String id; // UUID
  final String? performerUserId; // Can be null if user is deleted
  final String actionType;
  final String description;
  final Map<String, dynamic> contextualData; // JSONB
  final int lovesValue;
  final double? resonanceScore;
  final GoodwillStatus status;
  final DateTime? processedAt;
  final String? blockchainTxHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoodwillAction({
    required this.id,
    this.performerUserId,
    required this.actionType,
    required this.description,
    required this.contextualData,
    required this.lovesValue,
    this.resonanceScore,
    required this.status,
    this.processedAt,
    this.blockchainTxHash,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create a GoodwillAction instance from a JSON map.
  factory GoodwillAction.fromJson(Map<String, dynamic> json) {
    return GoodwillAction(
      id: json['id'] as String,
      performerUserId: json['performer_user_id'] as String?,
      actionType: json['action_type'] as String,
      description: json['description'] as String,
      contextualData: json['contextual_data'] as Map<String, dynamic>? ?? {},
      lovesValue: json['loves_value'] as int,
      resonanceScore: (json['resonance_score'] as num?)?.toDouble(),
      // Safely parse the enum from a string.
      status: _statusFromString(json['status'] as String?),
      processedAt: json['processed_at'] == null
          ? null
          : DateTime.parse(json['processed_at'] as String),
      blockchainTxHash: json['blockchain_tx_hash'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Helper function to safely convert a string to a GoodwillStatus enum.
  static GoodwillStatus _statusFromString(String? status) {
    switch (status?.toUpperCase()) {
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
