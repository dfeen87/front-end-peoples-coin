import 'package:flutter/foundation.dart';

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

  Map<String, dynamic> toJson() {
    final data = {
      'voter_user_id': voterUserId,
      'proposal_id': proposalId,
      'vote_value': voteValue,
    };
    if (rationale != null && rationale!.isNotEmpty) {
      data['rationale'] = rationale;
    }
    return data;
  }
}

