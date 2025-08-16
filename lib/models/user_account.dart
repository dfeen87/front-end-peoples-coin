import 'package:json_annotation/json_annotation.dart';

part 'user_account.g.dart';

/// Immutable data model for a user account.
/// Mirrors the `user_accounts` table in the backend.
@JsonSerializable()
class UserAccount {
  final String id;
  @JsonKey(name: 'firebase_uid')
  final String firebaseUid;
  final String email;
  final String username;
  final double balance;
  final String? bio;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'wallet_id')
  final String? walletId;
  @JsonKey(name: 'public_key')
  final String? publicKey;
  @JsonKey(name: 'encrypted_private_key')
  final String? encryptedPrivateKey;
  final String role;
  @JsonKey(name: 'is_email_verified')
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
  factory UserAccount.fromJson(Map<String, dynamic> json) =>
      _$UserAccountFromJson(json);

  /// Converts this instance into JSON.
  Map<String, dynamic> toJson() => _$UserAccountToJson(this);

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

