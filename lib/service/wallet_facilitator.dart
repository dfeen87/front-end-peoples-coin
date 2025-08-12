import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../service/wallet_service.dart';
import '../wallet_management.dart';
import '../providers/user_provider.dart';

class WalletFacilitatorState {
  final Wallet? currentWallet;
  final bool isLoading;
  final String? errorMessage;
  final double balance;

  WalletFacilitatorState({
    required this.currentWallet,
    required this.isLoading,
    required this.errorMessage,
    required this.balance,
  });

  WalletFacilitatorState copyWith({
    Wallet? currentWallet,
    bool? isLoading,
    String? errorMessage,
    double? balance,
  }) {
    return WalletFacilitatorState(
      currentWallet: currentWallet ?? this.currentWallet,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      balance: balance ?? this.balance,
    );
  }

  factory WalletFacilitatorState.initial() => WalletFacilitatorState(
        currentWallet: null,
        isLoading: false,
        errorMessage: null,
        balance: 0.0,
      );
}

class WalletFacilitator extends StateNotifier<WalletFacilitatorState> {
  final WalletManager _walletManager;
  final UserProvider _userProvider;

  WalletFacilitator(this._walletManager, this._userProvider)
      : super(WalletFacilitatorState.initial()) {
    // Select first wallet on init if available
    if (_walletManager.wallets.isNotEmpty) {
      state = state.copyWith(currentWallet: _walletManager.wallets.first);
    }
    // Subscribe to WalletManager changes
    _walletManager.addListener(_onWalletManagerUpdate);
  }

  void _onWalletManagerUpdate() {
    final wallets = _walletManager.wallets;
    if (wallets.isEmpty) {
      state = state.copyWith(currentWallet: null, balance: 0.0);
      return;
    }

    final currentId = state.currentWallet?.id;
    final updatedWallet = wallets.firstWhere(
      (w) => w.id == currentId,
      orElse: () => wallets.first,
    );

    // Only update state if wallet changed to reduce unnecessary UI rebuilds
    if (updatedWallet.id != currentId) {
      state = state.copyWith(currentWallet: updatedWallet);
    }
  }

  Future<void> createWallet(String pin) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _walletManager.createWallet(pin: pin);
      final newWallet = _walletManager.wallets.last;
      state = state.copyWith(currentWallet: newWallet, isLoading: false);

      // Sync keys with backend user profile
      await _syncKeysWithBackend(newWallet);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> unlockWallet(String walletId, String pin) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final wallet = await _walletManager.unlockWallet(id: walletId, pin: pin);
      if (wallet == null) throw Exception('Failed to unlock wallet');
      state = state.copyWith(currentWallet: wallet, isLoading: false);

      // Refresh user wallet info if applicable
      await _userProvider.refreshWallet();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refreshBalance() async {
    if (state.currentWallet == null) return;
    state = state.copyWith(isLoading: true);
    try {
      // TODO: Replace with real balance fetch from blockchain/backend
      await Future.delayed(const Duration(milliseconds: 500));
      // Simulated balance update
      state = state.copyWith(balance: 100.0, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<String?> signTransaction(String dataToSign) async {
    if (state.currentWallet == null) {
      state = state.copyWith(errorMessage: 'No wallet unlocked');
      return null;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final signature =
          await _walletManager.signTransaction(state.currentWallet!.id, dataToSign);
      state = state.copyWith(isLoading: false);
      return signature;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> _syncKeysWithBackend(Wallet wallet) async {
    try {
      await _userProvider.updateWalletKeys(
        publicKey: wallet.keys.publicKey,
        encryptedPrivateKey: wallet.keys.encryptedPrivateKey,
      );
    } catch (e) {
      if (state.errorMessage == null) {
        state = state.copyWith(errorMessage: 'Failed to sync wallet keys: $e');
      }
      // Consider logging or retrying
    }
  }

  @override
  void dispose() {
    _walletManager.removeListener(_onWalletManagerUpdate);
    super.dispose();
  }
}

final walletFacilitatorProvider =
    StateNotifierProvider<WalletFacilitator, WalletFacilitatorState>((ref) {
  final walletService = WalletService();
  final secureStorage = const FlutterSecureStorage();
  final walletManager = WalletManager(walletService, secureStorage);
  final userProvider = ref.watch(userProviderNotifier);

  return WalletFacilitator(walletManager, userProvider);
});

