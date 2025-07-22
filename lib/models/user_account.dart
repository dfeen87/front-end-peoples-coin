import 'package:flutter/foundation.dart';

/// Represents the data structure for a user account, mirroring the
/// `user_accounts` table in the backend database.
@immutable
class UserAccount {
  final String id; // UUID
  final String firebaseUid;
  final String? email;
  final String? username;
  final double balance; // NUMERIC(20, 4)
  final String? bio;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserAccount({
    required this.id,
    required this.firebaseUid,
    this.email,
    this.username,
    required this.balance,
    this.bio,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a UserAccount instance from JSON data.
  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      bio: json['bio'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  /// Converts this UserAccount instance into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'username': username,
      'balance': balance,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

