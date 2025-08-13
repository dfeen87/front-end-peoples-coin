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

  /// Creates a new instance of [UserWallet] from a JSON map.
  factory UserWallet.fromJson(Map<String, dynamic> json) {
    return UserWallet(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      publicAddress: json['public_address']?.toString() ?? '',
      blockchainNetwork: json['blockchain_network']?.toString() ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      encryptedPrivateKey: json['encrypted_private_key'] as String?,
      createdAt: _safeDate(json['created_at']),
      updatedAt: _safeDate(json['updated_at']),
    );
  }

  /// Creates a new instance of [UserWallet] with optional new values.
  UserWallet copyWith({
    String? id,
    String? userId,
    String? publicAddress,
    String? blockchainNetwork,
    bool? isPrimary,
    String? encryptedPrivateKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserWallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      publicAddress: publicAddress ?? this.publicAddress,
      blockchainNetwork: blockchainNetwork ?? this.blockchainNetwork,
      isPrimary: isPrimary ?? this.isPrimary,
      encryptedPrivateKey: encryptedPrivateKey ?? this.encryptedPrivateKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this model into a JSON map.
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
  
  /// Helper to safely parse DateTime values.
  static DateTime _safeDate(dynamic value) {
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

