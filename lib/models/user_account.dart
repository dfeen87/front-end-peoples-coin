// lib/models/user_account.dart

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
  final String role; // ADDED: The new role field

  UserAccount({
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
    required this.role, // ADDED: To the constructor
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      balance: (json['balance'] as num).toDouble(),
      bio: json['bio'] as String,
      profileImageUrl: json['profile_image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      walletId: json['wallet_id'] as String,
      // ADDED: Reads the 'role' field, defaults to 'user' if it doesn't exist
      role: json['role'] as String? ?? 'user',
    );
  }

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
      'role': role, // ADDED: To the JSON output
    };
  }
}
