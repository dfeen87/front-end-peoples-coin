// lib/service/wallet_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/user_account.dart';
import '../models/wallet_models.dart';
import 'wallet_service.dart';

class WalletManager extends StateNotifier<AsyncValue<Wallet?>> {
  final WalletService _walletService;
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid = const Uuid();

  static const _keyPrefix = 'wallet_keys_';
  static const _userWalletMapPrefix = 'user_wallet_';
  Timer? _balanceSyncTimer;

  WalletManager(this._walletService, this._secureStorage)
      : super(const AsyncValue.data(null));

  Future<void> initializeWallet({
    required UserAccount? userAccount,
    required String? sessionToken,
  }) async {
    if (userAccount == null || sessionToken == null) {
      state = const AsyncValue.data(null);
      _balanceSyncTimer?.cancel();
      return;
    }

    state = const AsyncValue.loading();

    try {
      final existingWallet = await _loadWalletFromStorage(userAccount.id);

      if (existingWallet != null) {
        state = AsyncValue.data(existingWallet);
      } else {
        await _createAndSaveWallet(userAccount, sessionToken);
      }

      _startBalanceSync(userAccount);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _createAndSaveWallet(UserAccount userAccount, String sessionToken) async {
    state = const AsyncValue.loading();
    try {
      final keys = await _walletService.generateWalletKeys(sessionToken: sessionToken);
      
      // Fix: Add required createdAt and updatedAt parameters
      final now = DateTime.now();
      final newWallet = Wallet(
        id: _uuid.v4(), 
        userId: userAccount.id,
        createdAt: now,
        updatedAt: now,
      );

      await _saveWalletKeysToStorage(newWallet.id, keys);
      await _secureStorage.write(
        key: '$_userWalletMapPrefix${userAccount.id}',
        value: newWallet.id,
      );

      state = AsyncValue.data(newWallet);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> signTransaction({
    required String dataToSign,
    required String sessionToken,
  }) async {
    final wallet = state.value;
    if (wallet == null) {
      throw Exception('No active wallet found.');
    }

    final walletKeysJson = await _secureStorage.read(key: '$_keyPrefix${wallet.id}');
    if (walletKeysJson == null) {
      throw Exception('Wallet keys not found for ID: ${wallet.id}');
    }

    final walletKeys = WalletKeys.fromJson(jsonDecode(walletKeysJson));

    final privateKeyBytes = await _walletService.decryptPrivateKey(
      sessionToken: sessionToken,
      keys: walletKeys,
    );

    return await _walletService.signTransactionBase64(
      privateKeyBytes: privateKeyBytes,
      data: dataToSign,
    );
  }

  Future<bool> sendTransaction(String dataToSend, String sessionToken) async {
    try {
      final signature = await signTransaction(
        dataToSign: dataToSend,
        sessionToken: sessionToken,
      );

      if (signature.isEmpty) return false;

      // TODO: Replace with actual blockchain/backend call
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Wallet?> _loadWalletFromStorage(String userId) async {
    final walletId = await _secureStorage.read(key: '$_userWalletMapPrefix$userId');
    if (walletId == null) return null;

    final walletKeysJson = await _secureStorage.read(key: '$_keyPrefix$walletId');
    if (walletKeysJson == null) return null;

    // Fix: Add required createdAt and updatedAt parameters
    final now = DateTime.now();
    return Wallet(
      id: walletId, 
      userId: userId,
      createdAt: now, // In real implementation, this should come from storage/API
      updatedAt: now,
    );
  }

  Future<void> _saveWalletKeysToStorage(String walletId, WalletKeys keys) async {
    final keyJson = jsonEncode({
      'encryptedPrivateKeyBase64': keys.encryptedPrivateKeyBase64,
      'ivBase64': keys.ivBase64,
      'publicKeyBase64': keys.publicKeyBase64,
      'saltBase64': keys.saltBase64,
    });
    await _secureStorage.write(key: '$_keyPrefix$walletId', value: keyJson);
  }

  void _startBalanceSync(UserAccount userAccount) {
    _balanceSyncTimer?.cancel();
    _balanceSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      // TODO: Implement actual balance sync with the backend/blockchain
      print('Syncing balance for user: ${userAccount.id}');

      if (state is! AsyncLoading) {
        state = AsyncValue.data(state.value);
      }
    });
  }

  void clearWallet() {
    state = const AsyncValue.data(null);
    _balanceSyncTimer?.cancel();
  }

  @override
  void dispose() {
    _balanceSyncTimer?.cancel();
    super.dispose();
  }
}
