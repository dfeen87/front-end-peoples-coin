import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import 'wallet_service.dart';

/// Wallet representation
class Wallet {
  final String id; // UUID or unique identifier
  final WalletKeys keys;

  Wallet({required this.id, required this.keys});
}

/// Loading states for WalletManager
enum WalletLoadingStatus {
  idle,
  creating,
  sending,
  syncing,
  error,
}

/// Wallet error container
class WalletError {
  final String message;
  WalletError(this.message);
}

/// WalletManager handles wallets lifecycle and transactions
class WalletManager extends StateNotifier<AsyncValue<List<Wallet>>> {
  final WalletService _walletService;
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid = const Uuid();

  WalletManager(this._walletService, this._secureStorage)
      : super(const AsyncValue.data([])) {
    _loadWalletsFromStorage();
    _startBalanceSync();
  }

  WalletLoadingStatus loadingStatus = WalletLoadingStatus.idle;
  WalletError? lastError;
  Timer? _syncTimer;

  List<Wallet> get wallets => state.value ?? [];

  /// Creates a new wallet and saves it securely
  Future<void> createWallet() async {
    loadingStatus = WalletLoadingStatus.creating;
    lastError = null;
    state = AsyncValue.loading();

    try {
      final keys = await _walletService.generateWalletKeys(); // PINless
      final id = _uuid.v4();
      final newWallet = Wallet(id: id, keys: keys);

      await _saveWalletToStorage(newWallet);

      state = AsyncValue.data([...wallets, newWallet]);
      loadingStatus = WalletLoadingStatus.idle;
    } catch (e, st) {
      loadingStatus = WalletLoadingStatus.error;
      lastError = WalletError('Failed to create wallet: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Unlocks wallet (PIN removed)
  Future<Wallet?> unlockWallet({required String id}) async {
    loadingStatus = WalletLoadingStatus.idle;
    lastError = null;

    try {
      final walletJson = await _secureStorage.read(key: 'wallet_$id');
      if (walletJson == null) throw Exception('Wallet not found');

      final keys = WalletKeys.fromJson(jsonDecode(walletJson));
      final unlockedWallet = Wallet(id: id, keys: keys);

      final updatedWallets = wallets.where((w) => w.id != id).toList()..add(unlockedWallet);
      state = AsyncValue.data(updatedWallets);

      return unlockedWallet;
    } catch (e, st) {
      loadingStatus = WalletLoadingStatus.error;
      lastError = WalletError('Failed to unlock wallet: $e');
      return null;
    }
  }

  /// Deletes wallet
  Future<void> deleteWallet(String id) async {
    await _secureStorage.delete(key: 'wallet_$id');
    state = AsyncValue.data(wallets.where((w) => w.id != id).toList());
  }

  /// Saves wallet to secure storage
  Future<void> _saveWalletToStorage(Wallet wallet) async {
    await _secureStorage.write(
      key: 'wallet_${wallet.id}',
      value: jsonEncode(wallet.keys.toJson()),
    );
  }

  /// Loads all wallets from secure storage
  Future<void> _loadWalletsFromStorage() async {
    try {
      final allData = await _secureStorage.readAll();
      final walletEntries = allData.entries.where((e) => e.key.startsWith('wallet_'));

      final loadedWallets = <Wallet>[];
      for (final entry in walletEntries) {
        final keys = WalletKeys.fromJson(jsonDecode(entry.value));
        loadedWallets.add(Wallet(id: entry.key.substring(7), keys: keys));
      }

      state = AsyncValue.data(loadedWallets);
    } catch (e, st) {
      lastError = WalletError('Failed to load wallets: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Signs transaction using wallet's private key
  Future<String> signTransaction(String walletId, String dataToSign) async {
    loadingStatus = WalletLoadingStatus.sending;
    lastError = null;

    try {
      final wallet = wallets.firstWhere(
        (w) => w.id == walletId,
        orElse: () => throw Exception('Wallet not found'),
      );

      final privateKeyBytes = await _walletService.decryptPrivateKey(
        encryptedPrivateKeyBase64: wallet.keys.encryptedPrivateKeyBase64,
        saltBase64: wallet.keys.saltBase64,
        ivBase64: wallet.keys.ivBase64,
      );

      final signatureBase64 = await _walletService.signTransactionBase64(
        privateKeyBytes: privateKeyBytes,
        data: dataToSign,
      );

      loadingStatus = WalletLoadingStatus.idle;
      return signatureBase64;
    } catch (e, st) {
      loadingStatus = WalletLoadingStatus.error;
      lastError = WalletError('Failed to sign transaction: $e');
      return '';
    }
  }

  /// Sends transaction (stub)
  Future<bool> sendTransaction(String walletId, String dataToSend) async {
    try {
      final signature = await signTransaction(walletId, dataToSend);
      if (signature.isEmpty) return false;

      // TODO: Replace with actual blockchain/backend call
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Periodic balance sync (stub)
  void _startBalanceSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      loadingStatus = WalletLoadingStatus.syncing;
      // TODO: fetch balances or transactions
      await Future.delayed(const Duration(milliseconds: 500));
      loadingStatus = WalletLoadingStatus.idle;
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

/// Riverpod provider
final walletManagerProvider =
    StateNotifierProvider<WalletManager, AsyncValue<List<Wallet>>>(
  (ref) => WalletManager(WalletService(), const FlutterSecureStorage()),
);

