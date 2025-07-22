import 'package:flutter/foundation.dart'; // Corrected import path

/// Mirrors the 'proposal_status' ENUM in your database
enum ProposalStatus {
  draft,
  active,
  closed,
  rejected,
  unknown,
}

/// Represents the data structure for a governance proposal, mirroring the
/// `proposals` table in the database.
@immutable
class Proposal {
  final String id; // UUID
  final String? proposerUserId;
  final String title;
  final String description;
  final ProposalStatus status;
  final DateTime? voteStartTime;
  final DateTime? voteEndTime;
  final double requiredQuorum; // NUMERIC(5, 2)
  final String proposalType;
  final Map<String, dynamic>? details; // JSONB
  final DateTime createdAt;
  final DateTime updatedAt;

  const Proposal({
    required this.id,
    this.proposerUserId,
    required this.title,
    required this.description,
    required this.status,
    this.voteStartTime,
    this.voteEndTime,
    required this.requiredQuorum,
    required this.proposalType,
    this.details,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create a Proposal instance from a JSON map.
  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['id'] as String,
      proposerUserId: json['proposer_user_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      status: _statusFromString(json['status'] as String?),
      voteStartTime: json['vote_start_time'] != null ? DateTime.parse(json['vote_start_time']) : null,
      voteEndTime: json['vote_end_time'] != null ? DateTime.parse(json['vote_end_time']) : null,
      requiredQuorum: double.parse(json['required_quorum'].toString()),
      proposalType: json['proposal_type'] as String,
      details: json['details'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Helper function to safely convert a string to a ProposalStatus enum.
  static ProposalStatus _statusFromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'DRAFT':
        return ProposalStatus.draft;
      case 'ACTIVE':
        return ProposalStatus.active;
      case 'CLOSED':
        return ProposalStatus.closed;
      case 'REJECTED':
        return ProposalStatus.rejected;
      default:
        return ProposalStatus.unknown;
    }
  }
}
