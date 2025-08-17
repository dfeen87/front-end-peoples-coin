import 'package:flutter/foundation.dart';

enum ProposalStatus { draft, active, closed, rejected, unknown }

@immutable
class Proposal {
  final String id;
  final String? proposerUserId;
  final String title;
  final String description;
  final ProposalStatus status;
  final DateTime? voteStartTime;
  final DateTime? voteEndTime;
  final double requiredQuorum;
  final String proposalType;
  final Map<String, dynamic>? details;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Add missing voting-related properties
  final int forVotes;
  final int againstVotes;
  final bool userHasVoted;

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
    this.forVotes = 0,
    this.againstVotes = 0,
    this.userHasVoted = false,
  });

  Proposal copyWith({
    String? id,
    String? proposerUserId,
    String? title,
    String? description,
    ProposalStatus? status,
    DateTime? voteStartTime,
    DateTime? voteEndTime,
    double? requiredQuorum,
    String? proposalType,
    Map<String, dynamic>? details,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? forVotes,
    int? againstVotes,
    bool? userHasVoted,
  }) =>
      Proposal(
        id: id ?? this.id,
        proposerUserId: proposerUserId ?? this.proposerUserId,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        voteStartTime: voteStartTime ?? this.voteStartTime,
        voteEndTime: voteEndTime ?? this.voteEndTime,
        requiredQuorum: requiredQuorum ?? this.requiredQuorum,
        proposalType: proposalType ?? this.proposalType,
        details: details ?? this.details,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        forVotes: forVotes ?? this.forVotes,
        againstVotes: againstVotes ?? this.againstVotes,
        userHasVoted: userHasVoted ?? this.userHasVoted,
      );

  factory Proposal.fromJson(Map<String, dynamic> json) => Proposal(
        id: json['id']?.toString() ?? '',
        proposerUserId: json['proposer_user_id']?.toString(),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        status: _statusFromString(json['status']?.toString()),
        voteStartTime: _parseNullableDate(json['vote_start_time']),
        voteEndTime: _parseNullableDate(json['vote_end_time']),
        requiredQuorum: _parseDouble(json['required_quorum']),
        proposalType: json['proposal_type']?.toString() ?? '',
        details: (json['details'] as Map?)?.cast<String, dynamic>(),
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
        forVotes: _parseInt(json['for_votes']),
        againstVotes: _parseInt(json['against_votes']),
        userHasVoted: json['user_has_voted'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'proposer_user_id': proposerUserId,
        'title': title,
        'description': description,
        'status': status.name.toUpperCase(),
        'vote_start_time': voteStartTime?.toIso8601String(),
        'vote_end_time': voteEndTime?.toIso8601String(),
        'required_quorum': requiredQuorum,
        'proposal_type': proposalType,
        'details': details,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'for_votes': forVotes,
        'against_votes': againstVotes,
        'user_has_voted': userHasVoted,
      };

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

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseNullableDate(dynamic value) => value == null ? null : _parseDate(value);

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
