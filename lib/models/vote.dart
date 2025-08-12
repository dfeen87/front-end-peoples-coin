import 'package:flutter/foundation.dart';

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
}

