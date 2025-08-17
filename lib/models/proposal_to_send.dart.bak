import 'package:flutter/foundation.dart';

/// A simplified model for sending a new proposal to the API.
/// This is based on the CreateProposalSchema in the backend.
@immutable
class ProposalToSend {
  final String proposerUserId;
  final String title;
  final String description;
  final String proposalType;
  final Map<String, dynamic>? details;
  final DateTime? voteEndTime; // Optional vote end time

  const ProposalToSend({
    required this.proposerUserId,
    required this.title,
    required this.description,
    required this.proposalType,
    this.details,
    this.voteEndTime,
  });

  /// Creates a new instance of [ProposalToSend] with optional new values.
  ProposalToSend copyWith({
    String? proposerUserId,
    String? title,
    String? description,
    String? proposalType,
    Map<String, dynamic>? details,
    DateTime? voteEndTime,
  }) {
    return ProposalToSend(
      proposerUserId: proposerUserId ?? this.proposerUserId,
      title: title ?? this.title,
      description: description ?? this.description,
      proposalType: proposalType ?? this.proposalType,
      details: details ?? this.details,
      voteEndTime: voteEndTime ?? this.voteEndTime,
    );
  }

  /// Converts this object into a JSON map for the API request body.
  Map<String, dynamic> toJson() {
    return {
      'proposer_user_id': proposerUserId,
      'title': title,
      'description': description,
      'proposal_type': proposalType,
      'details': details ?? {},
      'vote_end_time': voteEndTime?.toIso8601String(),
    };
  }
}

