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

/// Wallet service managing key generation, encryption and decryption.
/// Uses Ed25519 keys and AES-GCM for private key encryption with PBKDF2 key derivation.
class WalletService {
  /// Default AES key length in bytes (256 bits).
  static const int _aesKeyLength = 32;

  /// Default AES-GCM nonce length (12 bytes recommended).
  static const int _aesGcmNonceLength = 12;

  /// PBKDF2 iterations for key stretching.
  static const int _pbkdf2Iterations = 10000;

  final Random _secureRandom = Random.secure();

  WalletService();

  /// Generates a new Ed25519 key pair and encrypts the private key using AES-GCM
  /// with a key derived from [encryptionPassword] using PBKDF2.
  ///
  /// Returns the [WalletKeys] containing the public key, encrypted private key,
  /// salt, and IV (nonce).
  Future<WalletKeys> generateWalletKeys({
    required String encryptionPassword,
  }) async {
    final ed25519 = Ed25519();

    // Generate Ed25519 keypair
    final keyPair = await ed25519.newKeyPair();

    // Extract raw key bytes
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKeyBytes = await keyPair.extractPublicKey().then((pub) => pub.bytes);

    // Generate random salt and nonce (IV)
    final salt = _generateRandomBytes(_aesKeyLength);
    final nonce = _generateRandomBytes(_aesGcmNonceLength);

    // Derive AES key from password + salt
    final aesKey = await _deriveKeyFromPassword(encryptionPassword, salt);

    // Encrypt the private key bytes using AES-GCM
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
  /// and the [encryptionPassword] with the provided [saltBase64] and [ivBase64].
  ///
  /// Throws [WalletDecryptionException] on failure.
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
      final decryptedBytes = await _decryptPrivateKeyGcm(encryptedBytes, aesKey, nonce);
      return decryptedBytes;
    } catch (e) {
      throw WalletDecryptionException('Failed to decrypt private key. Check your password.');
    }
  }

  /// Verifies if the password can decrypt the wallet without returning the key.
  /// Returns true if password is correct, false otherwise.
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

  /// Encrypts the private key bytes using AES-GCM with the provided key and nonce.
  Future<String> _encryptPrivateKeyGcm(Uint8List privateKeyBytes, Uint8List aesKey, Uint8List nonce) async {
    final algorithm = AesGcm.with256bits();

    final secretKey = SecretKey(aesKey);
    final secretBox = await algorithm.encrypt(
      privateKeyBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Combine nonce + ciphertext + mac into one base64 string
    // (Or store separately as you already do for nonce)
    // Here we keep nonce separate, so just return combined ciphertext+mac:
    return base64Encode(secretBox.cipherText + secretBox.mac.bytes);
  }

  /// Decrypts the private key bytes using AES-GCM with the provided key and nonce.
  Future<Uint8List> _decryptPrivateKeyGcm(Uint8List encryptedBytes, Uint8List aesKey, Uint8List nonce) async {
    final algorithm = AesGcm.with256bits();

    // The last 16 bytes are the MAC tag in AES-GCM (128 bits)
    if (encryptedBytes.length < 16) {
      throw WalletDecryptionException('Invalid encrypted data length');
    }

    final macBytes = encryptedBytes.sublist(encryptedBytes.length - 16);
    final cipherTextBytes = encryptedBytes.sublist(0, encryptedBytes.length - 16);

    final secretBox = SecretBox(
      cipherTextBytes,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final secretKey = SecretKey(aesKey);
    final decryptedBytes = await algorithm.decrypt(secretBox, secretKey: secretKey);

    return Uint8List.fromList(decryptedBytes);
  }

  /// Derives a cryptographic key from a password and salt using PBKDF2 with HMAC-SHA256.
  Future<Uint8List> _deriveKeyFromPassword(String password, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _aesKeyLength * 8,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }

  /// Generates cryptographically secure random bytes of specified length.
  Uint8List _generateRandomBytes(int length) {
    return Uint8List.fromList(List<int>.generate(length, (_) => _secureRandom.nextInt(256)));
  }
}

