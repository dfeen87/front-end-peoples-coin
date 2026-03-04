import 'package:flutter/foundation.dart';

@immutable
class Comment {
  final String id;
  final String? authorUserId;
  final String? proposalId;
  final String? goodwillActionId;
  final String? parentCommentId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Comment({
    required this.id,
    this.authorUserId,
    this.proposalId,
    this.goodwillActionId,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Creates a new instance of [Comment] with optional new values.
  Comment copyWith({
    String? id,
    String? authorUserId,
    String? proposalId,
    String? goodwillActionId,
    String? parentCommentId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      authorUserId: authorUserId ?? this.authorUserId,
      proposalId: proposalId ?? this.proposalId,
      goodwillActionId: goodwillActionId ?? this.goodwillActionId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      authorUserId: json['author_user_id'] as String?,
      proposalId: json['proposal_id'] as String?,
      goodwillActionId: json['goodwill_action_id'] as String?,
      parentCommentId: json['parent_comment_id'] as String?,
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_user_id': authorUserId,
      'proposal_id': proposalId,
      'goodwill_action_id': goodwillActionId,
      'parent_comment_id': parentCommentId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

