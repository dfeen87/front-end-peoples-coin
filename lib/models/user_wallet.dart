import 'package:flutter/foundation.dart';

@immutable
class UserWallet {
  final String id;
  final String userId;
  final String publicAddress;
  final String blockchainNetwork;
  final bool isPrimary;
  final String? encryptedPrivateKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserWallet({
    required this.id,
    required this.userId,
    required this.publicAddress,
    required this.blockchainNetwork,
    required this.isPrimary,
    this.encryptedPrivateKey,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserWallet.fromJson(Map<String, dynamic> json) {
    return UserWallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      publicAddress: json['public_address'] as String,
      blockchainNetwork: json['blockchain_network'] as String,
      isPrimary: json['is_primary'] as bool,
      encryptedPrivateKey: json['encrypted_private_key'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'public_address': publicAddress,
      'blockchain_network': blockchainNetwork,
      'is_primary': isPrimary,
      'encrypted_private_key': encryptedPrivateKey,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

