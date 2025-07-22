import 'package:flutter/foundation.dart';

/// A simplified model for sending a new vote to the API.
/// This is based on the SubmitVoteSchema in the backend.
@immutable
class VoteToSend {
  final String proposalId;
  final String voterUserId;
  final String voteChoice; // "YES", "NO", or "ABSTAIN"
  final double voteWeight;

  const VoteToSend({
    required this.proposalId,
    required this.voterUserId,
    required this.voteChoice,
    required this.voteWeight,
  });

  /// Converts this object into a JSON map for the API request body.
  Map<String, dynamic> toJson() {
    return {
      'proposal_id': proposalId,
      'voter_user_id': voterUserId,
      'vote_choice': voteChoice,
      // The backend expects a numeric/decimal, so we send the double.
      'vote_weight': voteWeight,
    };
  }
}
