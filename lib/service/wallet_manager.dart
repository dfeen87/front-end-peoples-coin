import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import 'wallet_service.dart';

class Wallet {
  final String id; // UUID or unique identifier
  final WalletKeys keys;

  /// PIN stored only in memory temporarily during unlock or creation.
  /// Never persist PIN as plain text.
  final String? pin;

  Wallet({
    required this.id,
    required this.keys,
    this.pin,
  });

  Wallet copyWith({String? pin}) => Wallet(
        id: id,
        keys: keys,
        pin: pin ?? this.pin,
      );
}

enum WalletLoadingStatus {
  idle,
  creating,
  unlocking,
  sending,
  syncing,
  error,
}

class WalletError {
  final String message;
  WalletError(this.message);
}

class WalletManager extends StateNotifier<AsyncValue<List<Wallet>>> {
  final WalletService _walletService;
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid = const Uuid();

  WalletManager(this._walletService, this._secureStorage) : super(const AsyncValue.data([])) {
    _loadWalletsFromStorage();
    _startBalanceSync();
  }

  WalletLoadingStatus loadingStatus = WalletLoadingStatus.idle;
  WalletError? lastError;

  Timer? _syncTimer;

  List<Wallet> get wallets => state.value ?? [];

  /// Creates a new wallet with given PIN, encrypts keys, and persists.
  Future<void> createWallet({required String pin}) async {
    loadingStatus = WalletLoadingStatus.creating;
    lastError = null;
    state = AsyncValue.loading();

    try {
      final keys = await _walletService.generateWalletKeys(encryptionPassword: pin);
      final id = _uuid.v4();

      final newWallet = Wallet(id: id, keys: keys, pin: pin);

      // Save wallet keys securely (without PIN)
      await _saveWalletToStorage(newWallet);

      final updatedWallets = [...wallets, newWallet.copyWith(pin: null)];

      state = AsyncValue.data(updatedWallets);
      loadingStatus = WalletLoadingStatus.idle;
    } catch (e, st) {
      loadingStatus = WalletLoadingStatus.error;
      lastError = WalletError('Failed to create wallet: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Attempts to unlock the wallet by ID using provided PIN.
  /// Returns the wallet with PIN in memory if successful, else null.
  Future<Wallet?> unlockWallet({required String id, required String pin}) async {
    loadingStatus = WalletLoadingStatus.unlocking;
    lastError = null;

    try {
      final walletJson = await _secureStorage.read(key: 'wallet_$id');
      if (walletJson == null) throw Exception('Wallet not found');

      final Map<String, dynamic> walletMap = jsonDecode(walletJson);

      final keys = WalletKeys.fromJson(walletMap);

      // Verify PIN by trying to decrypt private key
      await _walletService.decryptPrivateKey(
        encryptedPrivateKeyBase64: keys.encryptedPrivateKeyBase64,
        encryptionPassword: pin,
        saltBase64: keys.saltBase64,
        ivBase64: keys.ivBase64,
      );

      // Replace wallet with unlocked version (PIN in memory only)
      final unlockedWallet = Wallet(id: id, keys: keys, pin: pin);
      final updatedWallets = wallets.where((w) => w.id != id).toList()..add(unlockedWallet);

      state = AsyncValue.data(updatedWallets);
      loadingStatus = WalletLoadingStatus.idle;

      return unlockedWallet;
    } catch (e, st) {
      loadingStatus = WalletLoadingStatus.error;
      lastError = WalletError('Failed to unlock wallet: $e');
      return null;
    }
  }

  /// Securely saves the wallet keys to storage (never store PIN).
  Future<void> _saveWalletToStorage(Wallet wallet) async {
    final walletJson = jsonEncode(wallet.keys.toJson());
    await _secureStorage.write(key: 'wallet_${wallet.id}', value: walletJson);
  }

  /// Deletes wallet from secure storage and updates state.
  Future<void> deleteWallet(String id) async {
    await _secureStorage.delete(key: 'wallet_$id');
    final updatedWallets = wallets.where((w) => w.id != id).toList();
    state = AsyncValue.data(updatedWallets);
  }

  /// Loads all wallets from secure storage (without PINs).
  Future<void> _loadWalletsFromStorage() async {
    try {
      final allData = await _secureStorage.readAll();
      final walletEntries = allData.entries.where((e) => e.key.startsWith('wallet_'));

      final loadedWallets = <Wallet>[];

      for (final entry in walletEntries) {
        final keysJson = jsonDecode(entry.value);
        final keys = WalletKeys.fromJson(keysJson);

        loadedWallets.add(Wallet(id: entry.key.substring(7), keys: keys, pin: null));
      }

      state = AsyncValue.data(loadedWallets);
    } catch (e, st) {
      lastError = WalletError('Failed to load wallets: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Starts a periodic sync timer for balance/transactions (stub).
  void _startBalanceSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      loadingStatus = WalletLoadingStatus.syncing;
      // TODO: Implement actual sync logic with backend here.
      await Future.delayed(const Duration(milliseconds: 500));
      loadingStatus = WalletLoadingStatus.idle;
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  /// Signs transaction data with private key (stub).
  Future<String> signTransaction(String walletId, String dataToSign) async {
    // TODO: Replace with real cryptographic signing using private key and WalletService
    await Future.delayed(const Duration(milliseconds: 300));
    return 'signed_data_placeholder';
  }
}

final walletManagerProvider = StateNotifierProvider<WalletManager, AsyncValue<List<Wallet>>>(
  (ref) => WalletManager(WalletService(), const FlutterSecureStorage()),
);

