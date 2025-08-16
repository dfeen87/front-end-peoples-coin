import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../service/api_client.dart';
import '../models/wallet_models.dart'; // <-- ensure you have Wallet model

enum WalletStatus { idle, loading, loaded, error }

// --- State ---
class WalletState {
  final Wallet? wallet;
  final WalletStatus status;
  final String? error;

  const WalletState({
    this.wallet,
    this.status = WalletStatus.idle,
    this.error,
  });

  WalletState copyWith({
    Wallet? wallet,
    WalletStatus? status,
    String? error,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      status: status ?? this.status,
      error: error,
    );
  }

  factory WalletState.initial() => const WalletState();
}

// --- Notifier ---
class WalletNotifier extends StateNotifier<WalletState> {
  final PeoplesCoinApiClient _apiClient;

  WalletNotifier(this._apiClient) : super(WalletState.initial());

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not signed in');
    final token = await user.getIdToken();
    if (token.isEmpty) throw Exception('Failed to get Firebase ID token');
    return token;
  }

  /// Fetch wallet details from API
  Future<void> fetchWallet(String walletIdFromUser) async {
    state = state.copyWith(status: WalletStatus.loading, error: null);

    try {
      final idToken = await _getIdToken();
      final walletJson =
          await _apiClient.getWalletDetails(walletIdFromUser, idToken);

      final wallet = Wallet.fromJson(walletJson);

      state = state.copyWith(
        wallet: wallet,
        status: WalletStatus.loaded,
      );
    } catch (e) {
      state = state.copyWith(
        status: WalletStatus.error,
        error: 'Failed to fetch wallet: $e',
      );
      if (kDebugMode) print('[WalletNotifier] Error fetching wallet: $e');
    }
  }

  /// Send funds and refresh wallet balance
  Future<void> sendFunds({
    required String recipientWalletId,
    required double amount,
  }) async {
    if (state.wallet?.id == null) throw Exception('No wallet loaded');

    state = state.copyWith(status: WalletStatus.loading, error: null);

    try {
      final idToken = await _getIdToken();
      await _apiClient.sendFunds(
        fromWalletId: state.wallet!.id,
        toWalletId: recipientWalletId,
        amount: amount,
        idToken: idToken,
      );

      // Refresh wallet balance after transaction
      await fetchWallet(state.wallet!.id);

      state = state.copyWith(status: WalletStatus.loaded);
    } catch (e) {
      state = state.copyWith(
        status: WalletStatus.error,
        error: 'Failed to send funds: $e',
      );
      if (kDebugMode) print('[WalletNotifier] Error sending funds: $e');
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// --- Provider ---
final walletProviderNotifier =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return WalletNotifier(apiClient);
});

