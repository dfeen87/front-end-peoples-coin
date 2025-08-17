import 'package:flutter/foundation.dart';

/// A model for sending and receiving vote data to/from the API.
/// 
/// This class represents a vote on a proposal with a choice (e.g., 'yes', 'no', 'abstain')
/// and an optional comment explaining the rationale behind the vote.
@immutable
class VoteToSend {
  /// The unique identifier of the proposal being voted on
  final String proposalId;
  
  /// The vote choice (e.g., 'yes', 'no', 'abstain')
  final String choice;
  
  /// Optional comment explaining the vote rationale
  final String? comment;

  /// Creates a new [VoteToSend] instance.
  const VoteToSend({
    required this.proposalId,
    required this.choice,
    this.comment,
  });

  /// Creates a new instance of [VoteToSend] with optional new values.
  VoteToSend copyWith({
    String? proposalId,
    String? choice,
    String? comment,
  }) {
    return VoteToSend(
      proposalId: proposalId ?? this.proposalId,
      choice: choice ?? this.choice,
      comment: comment ?? this.comment,
    );
  }

  /// Converts this object into a JSON map for API requests.
  Map<String, dynamic> toJson() {
    return {
      'proposalId': proposalId,
      'choice': choice,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }

  /// Creates a [VoteToSend] instance from a JSON map.
  factory VoteToSend.fromJson(Map<String, dynamic> json) {
    return VoteToSend(
      proposalId: json['proposalId'] as String,
      choice: json['choice'] as String,
      comment: json['comment'] as String?,
    );
  }

  /// Alternative factory constructor for snake_case API responses
  factory VoteToSend.fromJsonSnakeCase(Map<String, dynamic> json) {
    return VoteToSend(
      proposalId: json['proposal_id'] as String,
      choice: json['choice'] as String,
      comment: json['comment'] as String?,
    );
  }

  /// Converts this object into a JSON map with snake_case keys for API requests.
  Map<String, dynamic> toJsonSnakeCase() {
    return {
      'proposal_id': proposalId,
      'choice': choice,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }

  /// Validates that the vote choice is one of the allowed values.
  bool get isValidChoice {
    const allowedChoices = ['yes', 'no', 'abstain'];
    return allowedChoices.contains(choice.toLowerCase());
  }

  /// Returns true if this vote has a comment.
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Returns the comment or a default message if no comment is provided.
  String get displayComment => comment?.isNotEmpty == true ? comment! : 'No comment provided';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoteToSend &&
        other.proposalId == proposalId &&
        other.choice == choice &&
        other.comment == comment;
  }

  @override
  int get hashCode => Object.hash(proposalId, choice, comment);

  @override
  String toString() {
    return 'VoteToSend(proposalId: $proposalId, choice: $choice, comment: $comment)';
  }

  /// Creates a formatted string representation for display purposes.
  String toDisplayString() {
    final choiceDisplay = choice.toUpperCase();
    final commentDisplay = hasComment ? ' - "$comment"' : '';
    return 'Vote: $choiceDisplay$commentDisplay';
  }
}

/// Extension to provide additional utility methods for VoteToSend
extension VoteToSendExtensions on VoteToSend {
  /// Returns true if this is a positive vote (yes)
  bool get isPositiveVote => choice.toLowerCase() == 'yes';
  
  /// Returns true if this is a negative vote (no)  
  bool get isNegativeVote => choice.toLowerCase() == 'no';
  
  /// Returns true if this is an abstain vote
  bool get isAbstainVote => choice.toLowerCase() == 'abstain';
  
  /// Returns an icon representation of the vote choice
  String get choiceIcon {
    switch (choice.toLowerCase()) {
      case 'yes':
        return '✅';
      case 'no':
        return '❌';
      case 'abstain':
        return '⚪';
      default:
        return '❓';
    }
  }
}
