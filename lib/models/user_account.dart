/// Immutable data model for a user account.
/// Mirrors the `user_accounts` table in the backend.
class UserAccount {
  final String id;
  final String firebaseUid;
  final String email;
  final String username;
  final double balance;
  final String? bio;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? walletId;
  final String? publicKey;
  final String? encryptedPrivateKey;
  final String role;
  final bool isEmailVerified;

  const UserAccount({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.username,
    required this.balance,
    this.bio,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.walletId,
    this.publicKey,
    this.encryptedPrivateKey,
    this.role = 'user',
    this.isEmailVerified = false,
  });

  /// Factory constructor for creating a new `UserAccount` instance from JSON.
  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: json['id'] as String,
        firebaseUid: json['firebase_uid'] as String,
        email: json['email'] as String,
        username: json['username'] as String,
        balance: (json['balance'] as num).toDouble(),
        bio: json['bio'] as String?,
        profileImageUrl: json['profile_image_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        walletId: json['wallet_id'] as String?,
        publicKey: json['public_key'] as String?,
        encryptedPrivateKey: json['encrypted_private_key'] as String?,
        role: json['role'] as String? ?? 'user',
        isEmailVerified: json['is_email_verified'] as bool? ?? false,
      );

  /// Converts this instance into JSON.
  Map<String, dynamic> toJson() => {
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
        'is_email_verified': isEmailVerified,
      };

  /// Clone with optional overrides.
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
    bool? isEmailVerified,
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
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  String toString() =>
      'UserAccount(id: $id, username: $username, balance: $balance, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccount && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
