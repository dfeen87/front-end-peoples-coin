import 'package:flutter/foundation.dart';

@immutable
class ProposalTag {
  final String proposalId;
  final String tagId;

  const ProposalTag({
    required this.proposalId,
    required this.tagId,
  });

  /// Creates a new instance of [ProposalTag] with optional new values.
  ProposalTag copyWith({
    String? proposalId,
    String? tagId,
  }) {
    return ProposalTag(
      proposalId: proposalId ?? this.proposalId,
      tagId: tagId ?? this.tagId,
    );
  }

  factory ProposalTag.fromJson(Map<String, dynamic> json) {
    return ProposalTag(
      proposalId: json['proposal_id'] as String,
      tagId: json['tag_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proposal_id': proposalId,
      'tag_id': tagId,
    };
  }
}

