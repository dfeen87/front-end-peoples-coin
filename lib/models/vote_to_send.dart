import 'package:flutter/foundation.dart';

/// A simplified model for sending a new vote to the API.
@immutable
class VoteToSend {
  final String voterUserId;
  final String proposalId;
  final String voteValue;
  final String? rationale;

  const VoteToSend({
    required this.voterUserId,
    required this.proposalId,
    required this.voteValue,
    this.rationale,
  });

  /// Creates a new instance of [VoteToSend] with optional new values.
  VoteToSend copyWith({
    String? voterUserId,
    String? proposalId,
    String? voteValue,
    String? rationale,
  }) {
    return VoteToSend(
      voterUserId: voterUserId ?? this.voterUserId,
      proposalId: proposalId ?? this.proposalId,
      voteValue: voteValue ?? this.voteValue,
      rationale: rationale ?? this.rationale,
    );
  }

  /// Converts this object into a JSON map for the API request body.
  Map<String, dynamic> toJson() {
    return {
      'voter_user_id': voterUserId,
      'proposal_id': proposalId,
      'vote_value': voteValue,
      'rationale': rationale,
    };
  }
}

