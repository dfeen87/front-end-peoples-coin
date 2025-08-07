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
  final DateTime? voteEndTime; // Added: Field for vote end time

  const ProposalToSend({
    required this.proposerUserId,
    required this.title,
    required this.description,
    required this.proposalType,
    this.details,
    this.voteEndTime, // Added: Named parameter for vote end time
  });

  /// Converts this object into a JSON map for the API request body.
  Map<String, dynamic> toJson() {
    return {
      'proposer_user_id': proposerUserId,
      'title': title,
      'description': description,
      'proposal_type': proposalType,
      'details': details ?? {},
      'vote_end_time': voteEndTime?.toIso8601String(), // Added: Convert DateTime to ISO 8601 string for API
    };
  }
}
