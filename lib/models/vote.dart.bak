import 'package:flutter/foundation.dart';

/// An immutable data model for a governance vote.
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
      id: json['id']?.toString() ?? '',
      voterUserId: json['voter_user_id'] as String?,
      proposalId: json['proposal_id']?.toString() ?? '',
      voteValue: json['vote_value'] as String? ?? '',
      rationale: json['rationale'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  /// Converts this model into a JSON map.
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

  /// Creates a new instance of [Vote] with optional new values.
  Vote copyWith({
    String? id,
    String? voterUserId,
    String? proposalId,
    String? voteValue,
    String? rationale,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vote(
      id: id ?? this.id,
      voterUserId: voterUserId ?? this.voterUserId,
      proposalId: proposalId ?? this.proposalId,
      voteValue: voteValue ?? this.voteValue,
      rationale: rationale ?? this.rationale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper to safely parse DateTime values.
  static DateTime _parseDate(dynamic value) {
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vote &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Vote(id: $id, proposalId: $proposalId, voteValue: $voteValue)';
  }
}

