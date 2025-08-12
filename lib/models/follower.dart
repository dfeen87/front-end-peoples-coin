import 'package:flutter/foundation.dart';

@immutable
class Follower {
  final String followerUserId;
  final String followedUserId;
  final DateTime createdAt;

  const Follower({
    required this.followerUserId,
    required this.followedUserId,
    required this.createdAt,
  });

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      followerUserId: json['follower_user_id'] as String,
      followedUserId: json['followed_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'follower_user_id': followerUserId,
      'followed_user_id': followedUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

