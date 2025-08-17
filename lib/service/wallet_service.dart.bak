// lib/service/wallet_service.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Exception thrown when wallet decryption fails.
class WalletDecryptionException implements Exception {
  final String message;
  WalletDecryptionException(this.message);
  @override
  String toString() => 'WalletDecryptionException: $message';
}

/// Container class for wallet key data.
class WalletKeys {
  final String publicKeyBase64; // base64 encoded public key
  final String encryptedPrivateKeyBase64; // base64 encrypted private key
  final String ivBase64; // base64 nonce/IV for AES-GCM
  final String saltBase64; // base64 salt for HKDF

  WalletKeys({
    required this.publicKeyBase64,
    required this.encryptedPrivateKeyBase64,
    required this.ivBase64,
    required this.saltBase64,
  });

  Map<String, dynamic> toJson() => {
        'publicKey': publicKeyBase64,
        'encryptedPrivateKey': encryptedPrivateKeyBase64,
        'ivBase64': ivBase64,
        'saltBase64': saltBase64,
      };

  factory WalletKeys.fromJson(Map<String, dynamic> json) => WalletKeys(
        publicKeyBase64: json['publicKey'],
        encryptedPrivateKeyBase64: json['encryptedPrivateKey'],
        ivBase64: json['ivBase64'],
        saltBase64: json['saltBase64'],
      );
}

/// Wallet service managing key generation, encryption, decryption, and signing.
class WalletService {
  static const int _aesKeyLength = 32; // 256-bit key
  static const int _aesGcmNonceLength = 12;

  final Random _secureRandom = Random.secure();

  /// Generates a new Ed25519 key pair and encrypts the private key using a session key.
  Future<WalletKeys> generateWalletKeys({
    required String sessionToken,
  }) async {
    final ed25519 = Ed25519();
    final keyPair = await ed25519.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKeyBytes = await keyPair.extractPublicKey().then((pub) => pub.bytes);

    final salt = _generateRandomBytes(32); // Generate a fresh salt
    final encryptionKey = await _deriveKeyFromSession(sessionToken, salt);
    final nonce = _generateRandomBytes(_aesGcmNonceLength);

    final encryptedPrivateKeyBase64 = await _encryptPrivateKeyGcm(
        privateKeyBytes, encryptionKey, nonce);

    return WalletKeys(
      publicKeyBase64: base64Encode(publicKeyBytes),
      encryptedPrivateKeyBase64: encryptedPrivateKeyBase64,
      ivBase64: base64Encode(nonce),
      saltBase64: base64Encode(salt),
    );
  }

  /// Decrypts private key using a session-derived key.
  Future<Uint8List> decryptPrivateKey({
    required String sessionToken,
    required WalletKeys keys,
  }) async {
    final salt = base64Decode(keys.saltBase64);
    final encryptionKey = await _deriveKeyFromSession(sessionToken, salt);
    final nonce = base64Decode(keys.ivBase64);
    final encryptedBytes = base64Decode(keys.encryptedPrivateKeyBase64);

    try {
      return await _decryptPrivateKeyGcm(encryptedBytes, encryptionKey, nonce);
    } catch (_) {
      throw WalletDecryptionException('Failed to decrypt private key.');
    }
  }

  /// Signs transaction data using Ed25519 private key bytes.
  Future<Uint8List> signTransaction({
    required Uint8List privateKeyBytes,
    required Uint8List data,
  }) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
    final signature = await algorithm.sign(data, keyPair: keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  Future<String> signTransactionBase64({required Uint8List privateKeyBytes, required String data}) async {
    final signatureBytes = await signTransaction(privateKeyBytes: privateKeyBytes, data: utf8.encode(data) as Uint8List);
    return base64Encode(signatureBytes);
  }

  Future<SecretKey> _deriveKeyFromSession(String sessionToken, Uint8List salt) async {
    final secretKey = SecretKey(utf8.encode(sessionToken));
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final newKey = await hkdf.deriveKey(secretKey: secretKey, nonce: salt);
    return newKey;
  }

  Future<String> _encryptPrivateKeyGcm(Uint8List privateKeyBytes, SecretKey aesKey, Uint8List nonce) async {
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(privateKeyBytes, secretKey: aesKey, nonce: nonce);
    return base64Encode(secretBox.cipherText + secretBox.mac.bytes);
  }

  Future<Uint8List> _decryptPrivateKeyGcm(Uint8List encryptedBytes, SecretKey aesKey, Uint8List nonce) async {
    if (encryptedBytes.length < 16) throw WalletDecryptionException('Invalid encrypted data length.');
    final macBytes = encryptedBytes.sublist(encryptedBytes.length - 16);
    final cipherTextBytes = encryptedBytes.sublist(0, encryptedBytes.length - 16);
    final secretBox = SecretBox(cipherTextBytes, nonce: nonce, mac: Mac(macBytes));
    final decryptedBytes = await AesGcm.with256bits().decrypt(secretBox, secretKey: aesKey);
    return Uint8List.fromList(decryptedBytes);
  }

  Uint8List _generateRandomBytes(int length) =>
      Uint8List.fromList(List<int>.generate(length, (_) => _secureRandom.nextInt(256)));
}
