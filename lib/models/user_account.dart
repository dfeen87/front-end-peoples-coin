import 'package:flutter/foundation.dart';

/// An immutable data model for a user's account, including sensitive details.
/// This mirrors the `user_accounts` table in the database.
@immutable
class UserAccount {
  final String id;
  final String firebaseUid;
  final String email;
  final String username;
  final double balance;
  final String bio;
  final String profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String walletId;
  final String publicKey;
  final String encryptedPrivateKey;
  final String role;

  const UserAccount({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.username,
    required this.balance,
    required this.bio,
    required this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.walletId,
    required this.publicKey,
    required this.encryptedPrivateKey,
    required this.role,
  });

  /// Creates a new instance of [UserAccount] from a JSON map.
  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id']?.toString() ?? '',
      firebaseUid: json['firebase_uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      bio: json['bio']?.toString() ?? '',
      profileImageUrl: json['profile_image_url']?.toString() ?? '',
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      walletId: json['wallet_id']?.toString() ?? '',
      publicKey: json['public_key']?.toString() ?? '',
      encryptedPrivateKey: json['encrypted_private_key']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
    );
  }

  /// Converts this model into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'username': username,
      'balance': balance,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'wallet_id': walletId,
      'public_key': publicKey,
      'encrypted_private_key': encryptedPrivateKey,
      'role': role,
    };
  }

  /// Creates a new instance of [UserAccount] with optional new values.
  UserAccount copyWith({
    String? id,
    String? firebaseUid,
    String? email,
    String? username,
    double? balance,
    String? bio,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? walletId,
    String? publicKey,
    String? encryptedPrivateKey,
    String? role,
  }) {
    return UserAccount(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      username: username ?? this.username,
      balance: balance ?? this.balance,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      walletId: walletId ?? this.walletId,
      publicKey: publicKey ?? this.publicKey,
      encryptedPrivateKey: encryptedPrivateKey ?? this.encryptedPrivateKey,
      role: role ?? this.role,
    );
  }
  
  /// Helper to deserialize a list of user accounts from a JSON array.
  static List<UserAccount> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => UserAccount.fromJson(json)).toList();
  }

  @override
  String toString() {
    return 'UserAccount(id: $id, username: $username, balance: $balance, role: $role)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccount &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Helper to safely parse a DateTime.
  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

