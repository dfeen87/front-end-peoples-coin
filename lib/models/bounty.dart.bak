import 'package:flutter/foundation.dart';

/// Defines the possible states of a Bounty.
/// Using an enum provides type safety and prevents errors from typos.
enum BountyStatus {
  active,
  completed,
  cancelled,
  expired,
}

@immutable
class Bounty {
  final String id;
  final String? createdByUserId;
  final String? relatedProposalId;
  final String title;
  final String description;
  final BountyStatus status;
  final double rewardAmount;
  final String rewardTokenSymbol;
  final DateTime? expiresAt;
  final int? maxParticipants;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Bounty({
    required this.id,
    this.createdByUserId,
    this.relatedProposalId,
    required this.title,
    required this.description,
    required this.status,
    required this.rewardAmount,
    required this.rewardTokenSymbol,
    this.expiresAt,
    this.maxParticipants,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new instance of [Bounty] with optional new values.
  Bounty copyWith({
    String? id,
    String? createdByUserId,
    String? relatedProposalId,
    String? title,
    String? description,
    BountyStatus? status,
    double? rewardAmount,
    String? rewardTokenSymbol,
    DateTime? expiresAt,
    int? maxParticipants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bounty(
      id: id ?? this.id,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      relatedProposalId: relatedProposalId ?? this.relatedProposalId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      rewardTokenSymbol: rewardTokenSymbol ?? this.rewardTokenSymbol,
      expiresAt: expiresAt ?? this.expiresAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Bounty.fromJson(Map<String, dynamic> json) {
    return Bounty(
      id: json['id'] as String,
      createdByUserId: json['created_by_user_id'] as String?,
      relatedProposalId: json['related_proposal_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      status: BountyStatus.values.firstWhere((e) => e.toString() == 'BountyStatus.${json['status'].toString().toLowerCase()}'),
      rewardAmount: double.parse(json['reward_amount'].toString()),
      rewardTokenSymbol: json['reward_token_symbol'] as String,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      maxParticipants: json['max_participants'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by_user_id': createdByUserId,
      'related_proposal_id': relatedProposalId,
      'title': title,
      'description': description,
      'status': status.name,
      'reward_amount': rewardAmount,
      'reward_token_symbol': rewardTokenSymbol,
      'expires_at': expiresAt?.toIso8601String(),
      'max_participants': maxParticipants,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

