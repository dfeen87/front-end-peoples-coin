import 'package:flutter/foundation.dart';

@immutable
class ActionLove {
  final String id;
  final String userId;
  final String goodwillActionId;
  final DateTime createdAt;

  const ActionLove({
    required this.id,
    required this.userId,
    required this.goodwillActionId,
    required this.createdAt,
  });

  /// Creates a new instance of [ActionLove] with optional new values.
  ActionLove copyWith({
    String? id,
    String? userId,
    String? goodwillActionId,
    DateTime? createdAt,
  }) {
    return ActionLove(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goodwillActionId: goodwillActionId ?? this.goodwillActionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ActionLove.fromJson(Map<String, dynamic> json) {
    return ActionLove(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goodwillActionId: json['goodwill_action_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goodwill_action_id': goodwillActionId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

