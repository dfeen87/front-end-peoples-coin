import 'package:flutter/foundation.dart';

@immutable
class ProposalTag {
  final String proposalId;
  final String tagId;

  const ProposalTag({
    required this.proposalId,
    required this.tagId,
  });

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

