import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

  /// Unlocks wallet by ID using PIN. Returns unlocked Wallet in memory.
  Future<Wallet?> unlockWallet({required String id, required String pin}) async {
    loadingStatus = WalletLoadingStatus.unlocking;
    lastError = null;

    try {
      final walletJson = await _secureStorage.read(key: 'wallet_$id');
      if (walletJson == null) throw Exception('Wallet not found');

      final Map<String, dynamic> walletMap = jsonDecode(walletJson);
      final keys = WalletKeys.fromJson(walletMap);

      // Verify PIN by attempting private key decryption
      await _walletService.decryptPrivateKey(
        encryptedPrivateKeyBase64: keys.encryptedPrivateKeyBase64,
        encryptionPassword: pin,
        saltBase64: keys.saltBase64,
        ivBase64: keys.ivBase64,
      );

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

  /// Deletes wallet from secure storage and updates state.
  Future<void> deleteWallet(String id) async {
    await _secureStorage.delete(key: 'wallet_$id');
    final updatedWallets = wallets.where((w) => w.id != id).toList();
    state = AsyncValue.data(updatedWallets);
  }

  /// Securely saves wallet keys (never store PIN).
  Future<void> _saveWalletToStorage(Wallet wallet) async {
    final walletJson = jsonEncode(wallet.keys.toJson());
    await _secureStorage.write(key: 'wallet_${wallet.id}', value: walletJson);
  }

  /// Loads wallets from secure storage (without PINs).
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

  /// Signs transaction data using the wallet's private key (PIN in memory required)
  /// Returns Base64-encoded signature.
  Future<String> signTransaction(String walletId, String dataToSign) async {
    loadingStatus = WalletLoadingStatus.sending;
    lastError = null;

    try {
      final wallet = wallets.firstWhere((w) => w.id == walletId, orElse: () => throw Exception('Wallet not found'));
      if (wallet.pin == null) throw Exception('Wallet is locked. Unlock with PIN first.');

      final privateKeyBytes = await _walletService.decryptPrivateKey(
        encryptedPrivateKeyBase64: wallet.keys.encryptedPrivateKeyBase64,
        encryptionPassword: wallet.pin!,
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

  /// Placeholder for sending a transaction (stub).
  Future<bool> sendTransaction(String walletId, String dataToSend) async {
    try {
      final signature = await signTransaction(walletId, dataToSend);
      if (signature.isEmpty) return false;

      // TODO: Replace with actual backend/blockchain transaction submission
      await Future.delayed(const Duration(milliseconds: 500));

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Periodic sync for balances or transactions (stub for now)
  void _startBalanceSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      loadingStatus = WalletLoadingStatus.syncing;
      // TODO: Fetch balances or transactions from backend/blockchain
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

/// Riverpod provider for WalletManager
final walletManagerProvider = StateNotifierProvider<WalletManager, AsyncValue<List<Wallet>>>(
  (ref) => WalletManager(WalletService(), const FlutterSecureStorage()),
);

