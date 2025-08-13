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

  WalletKeys({
    required this.publicKeyBase64,
    required this.encryptedPrivateKeyBase64,
    required this.ivBase64,
  });

  Map<String, dynamic> toJson() => {
        'publicKey': publicKeyBase64,
        'encryptedPrivateKey': encryptedPrivateKeyBase64,
        'ivBase64': ivBase64,
      };

  factory WalletKeys.fromJson(Map<String, dynamic> json) => WalletKeys(
        publicKeyBase64: json['publicKey'],
        encryptedPrivateKeyBase64: json['encryptedPrivateKey'],
        ivBase64: json['ivBase64'],
      );
}

/// Wallet service managing key generation, encryption, decryption, and signing.
class WalletService {
  static const int _aesKeyLength = 32; // 256-bit key
  static const int _aesGcmNonceLength = 12;

  final Random _secureRandom = Random.secure();
  final FlutterSecureStorage _secureStorage;

  WalletService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Generates a new Ed25519 key pair, encrypts the private key, and stores AES key securely.
  Future<WalletKeys> generateWalletKeys({required String walletId}) async {
    final ed25519 = Ed25519();
    final keyPair = await ed25519.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKeyBytes = await keyPair.extractPublicKey().then((pub) => pub.bytes);

    final aesKey = _generateRandomBytes(_aesKeyLength);
    final nonce = _generateRandomBytes(_aesGcmNonceLength);

    final encryptedPrivateKeyBase64 = await _encryptPrivateKeyGcm(privateKeyBytes, aesKey, nonce);

    // Store AES key securely in FlutterSecureStorage
    await _secureStorage.write(key: 'wallet_key_$walletId', value: base64Encode(aesKey));

    return WalletKeys(
      publicKeyBase64: base64Encode(publicKeyBytes),
      encryptedPrivateKeyBase64: encryptedPrivateKeyBase64,
      ivBase64: base64Encode(nonce),
    );
  }

  /// Decrypts private key using AES key retrieved from secure storage.
  Future<Uint8List> decryptPrivateKey({required String walletId, required WalletKeys keys}) async {
    final aesKeyBase64 = await _secureStorage.read(key: 'wallet_key_$walletId');
    if (aesKeyBase64 == null) {
      throw WalletDecryptionException('AES key not found for wallet $walletId.');
    }
    final aesKey = base64Decode(aesKeyBase64);
    final nonce = base64Decode(keys.ivBase64);
    final encryptedBytes = base64Decode(keys.encryptedPrivateKeyBase64);

    try {
      return await _decryptPrivateKeyGcm(encryptedBytes, aesKey, nonce);
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

  Future<String> _encryptPrivateKeyGcm(Uint8List privateKeyBytes, Uint8List aesKey, Uint8List nonce) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(aesKey);
    final secretBox = await algorithm.encrypt(privateKeyBytes, secretKey: secretKey, nonce: nonce);
    return base64Encode(secretBox.cipherText + secretBox.mac.bytes);
  }

  Future<Uint8List> _decryptPrivateKeyGcm(Uint8List encryptedBytes, Uint8List aesKey, Uint8List nonce) async {
    if (encryptedBytes.length < 16) throw WalletDecryptionException('Invalid encrypted data length.');
    final macBytes = encryptedBytes.sublist(encryptedBytes.length - 16);
    final cipherTextBytes = encryptedBytes.sublist(0, encryptedBytes.length - 16);
    final secretBox = SecretBox(cipherTextBytes, nonce: nonce, mac: Mac(macBytes));
    final secretKey = SecretKey(aesKey);
    final decryptedBytes = await AesGcm.with256bits().decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(decryptedBytes);
  }

  Uint8List _generateRandomBytes(int length) =>
      Uint8List.fromList(List<int>.generate(length, (_) => _secureRandom.nextInt(256)));
}

