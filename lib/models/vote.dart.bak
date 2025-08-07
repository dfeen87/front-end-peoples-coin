import 'package:flutter/foundation.dart';

/// Represents a single vote on a proposal, mirroring the
/// `votes` table in the database.
@immutable
class Vote {
  final String id; // UUID
  final String? voterUserId;
  final String proposalId;
  final String voteValue; // e.g., "YES", "NO", "ABSTAIN"
  final String? rationale;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vote({
    required this.id,
    this.voterUserId,
    required this.proposalId,
    required this.voteValue,
    this.rationale,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create a Vote instance from a JSON map.
  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'] as String,
      voterUserId: json['voter_user_id'] as String?,
      proposalId: json['proposal_id'] as String,
      voteValue: json['vote_value'] as String,
      rationale: json['rationale'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts the Vote instance into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'voter_user_id': voterUserId,
      'proposal_id': proposalId,
      'vote_value': voteValue,
      'rationale': rationale,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

