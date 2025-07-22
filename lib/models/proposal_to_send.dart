import 'package:flutter/foundation.dart';

/// A simplified model for sending a new proposal to the API.
/// This is based on the CreateProposalSchema in the backend.
@immutable
class ProposalToSend {
  final String proposerUserId;
  final String title;
  final String description;
  final String proposalType;
  // Details can be a complex object, so a Map is flexible.
  final Map<String, dynamic>? details;

  const ProposalToSend({
    required this.proposerUserId,
    required this.title,
    required this.description,
    required this.proposalType,
    this.details,
  });

  /// Converts this object into a JSON map for the API request body.
  Map<String, dynamic> toJson() {
    return {
      'proposer_user_id': proposerUserId,
      'title': title,
      'description': description,
      'proposal_type': proposalType,
      'details': details ?? {},
    };
  }
}
