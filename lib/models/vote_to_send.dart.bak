// lib/models/vote_to_send.dart
import 'package:flutter/foundation.dart';

@immutable
class VoteToSend {
  final String voterUserId;
  final String proposalId;
  final String voteValue; // ADDED: Field for vote value
  final String? rationale;

  const VoteToSend({
    required this.voterUserId,
    required this.proposalId,
    required this.voteValue, // ADDED: Named parameter for vote value
    this.rationale,
  });

  Map<String, dynamic> toJson() {
    return {
      'voter_user_id': voterUserId,
      'proposal_id': proposalId,
      'vote_value': voteValue, // ADDED: Include vote_value in JSON
      'rationale': rationale,
    };
  }
}
