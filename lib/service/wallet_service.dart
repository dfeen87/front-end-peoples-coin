import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart' as encrypt_package;

/// Exception thrown when wallet decryption fails (wrong password or corrupted data).
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
  final String saltBase64; // base64 salt used in PBKDF2
  final String ivBase64; // base64 nonce/IV for AES-GCM

  WalletKeys({
    required this.publicKeyBase64,
    required this.encryptedPrivateKeyBase64,
    required this.saltBase64,
    required this.ivBase64,
  });

  Map<String, dynamic> toJson() => {
        'publicKey': publicKeyBase64,
        'encryptedPrivateKey': encryptedPrivateKeyBase64,
        'saltBase64': saltBase64,
        'ivBase64': ivBase64,
      };

  factory WalletKeys.fromJson(Map<String, dynamic> json) => WalletKeys(
        publicKeyBase64: json['publicKey'],
        encryptedPrivateKeyBase64: json['encryptedPrivateKey'],
        saltBase64: json['saltBase64'],
        ivBase64: json['ivBase64'],
      );
}

/// Wallet service managing key generation, encryption, decryption, and signing.
class WalletService {
  static const int _aesKeyLength = 32;
  static const int _aesGcmNonceLength = 12;
  static const int _pbkdf2Iterations = 10000;

  final Random _secureRandom = Random.secure();

  WalletService();

  /// Generates a new Ed25519 key pair and encrypts the private key using AES-GCM
  /// with a key derived from [encryptionPassword] using PBKDF2.
  Future<WalletKeys> generateWalletKeys({
    required String encryptionPassword,
  }) async {
    final ed25519 = Ed25519();

    final keyPair = await ed25519.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKeyBytes = await keyPair.extractPublicKey().then((pub) => pub.bytes);

    final salt = _generateRandomBytes(_aesKeyLength);
    final nonce = _generateRandomBytes(_aesGcmNonceLength);

    final aesKey = await _deriveKeyFromPassword(encryptionPassword, salt);

    final encryptedPrivateKeyBase64 =
        await _encryptPrivateKeyGcm(privateKeyBytes, aesKey, nonce);

    final publicKeyBase64 = base64Encode(publicKeyBytes);

    return WalletKeys(
      publicKeyBase64: publicKeyBase64,
      encryptedPrivateKeyBase64: encryptedPrivateKeyBase64,
      saltBase64: base64Encode(salt),
      ivBase64: base64Encode(nonce),
    );
  }

  /// Decrypts the private key bytes from the encrypted data using AES-GCM
  Future<Uint8List> decryptPrivateKey({
    required String encryptedPrivateKeyBase64,
    required String encryptionPassword,
    required String saltBase64,
    required String ivBase64,
  }) async {
    final salt = base64Decode(saltBase64);
    final nonce = base64Decode(ivBase64);
    final encryptedBytes = base64Decode(encryptedPrivateKeyBase64);

    final aesKey = await _deriveKeyFromPassword(encryptionPassword, salt);

    try {
      return await _decryptPrivateKeyGcm(encryptedBytes, aesKey, nonce);
    } catch (_) {
      throw WalletDecryptionException('Failed to decrypt private key. Check your password.');
    }
  }

  /// Verifies password correctness without returning the key
  Future<bool> verifyPassword({
    required WalletKeys walletKeys,
    required String encryptionPassword,
  }) async {
    try {
      await decryptPrivateKey(
        encryptedPrivateKeyBase64: walletKeys.encryptedPrivateKeyBase64,
        encryptionPassword: encryptionPassword,
        saltBase64: walletKeys.saltBase64,
        ivBase64: walletKeys.ivBase64,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Signs transaction data using Ed25519 private key bytes
  Future<Uint8List> signTransaction({
    required Uint8List privateKeyBytes,
    required Uint8List data,
  }) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
    final signature = await algorithm.sign(data, keyPair: keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  Future<String> signTransactionBase64({
    required Uint8List privateKeyBytes,
    required String data,
  }) async {
    final signatureBytes = await signTransaction(
      privateKeyBytes: privateKeyBytes,
      data: utf8.encode(data) as Uint8List,
    );
    return base64Encode(signatureBytes);
  }

  Future<String> _encryptPrivateKeyGcm(Uint8List privateKeyBytes, Uint8List aesKey, Uint8List nonce) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(aesKey);
    final secretBox = await algorithm.encrypt(privateKeyBytes, secretKey: secretKey, nonce: nonce);
    return base64Encode(secretBox.cipherText + secretBox.mac.bytes);
  }

  Future<Uint8List> _decryptPrivateKeyGcm(Uint8List encryptedBytes, Uint8List aesKey, Uint8List nonce) async {
    if (encryptedBytes.length < 16) throw WalletDecryptionException('Invalid encrypted data length');
    final macBytes = encryptedBytes.sublist(encryptedBytes.length - 16);
    final cipherTextBytes = encryptedBytes.sublist(0, encryptedBytes.length - 16);
    final secretBox = SecretBox(cipherTextBytes, nonce: nonce, mac: Mac(macBytes));
    final secretKey = SecretKey(aesKey);
    final decryptedBytes = await AesGcm.with256bits().decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(decryptedBytes);
  }

  Future<Uint8List> _deriveKeyFromPassword(String password, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: _pbkdf2Iterations, bits: _aesKeyLength * 8);
    final secretKey = await pbkdf2.deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
    return Uint8List.fromList(await secretKey.extractBytes());
  }

  Uint8List _generateRandomBytes(int length) => Uint8List.fromList(List<int>.generate(length, (_) => _secureRandom.nextInt(256)));
}

