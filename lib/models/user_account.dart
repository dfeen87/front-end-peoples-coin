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
    required this.publicKey,
    required this.encryptedPrivateKey,
    required this.role,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      bio: json['bio'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      walletId: json['wallet_id'] as String? ?? '',
      publicKey: json['public_key'] as String? ?? '',
      encryptedPrivateKey: json['encrypted_private_key'] as String? ?? '',
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
      'public_key': publicKey,
      'encrypted_private_key': encryptedPrivateKey,
      'role': role,
    };
  }

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

  /// Helper to deserialize a list of user accounts from JSON array
  static List<UserAccount> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => UserAccount.fromJson(json)).toList();
  }
}

