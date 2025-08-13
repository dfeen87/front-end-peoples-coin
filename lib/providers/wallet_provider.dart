// lib/providers/wallet_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/api_client.dart';

enum WalletStatus { idle, loading, loaded, error }

// --- State ---
class WalletState {
  final String? walletId;
  final double balance;
  final WalletStatus status;
  final String? error;

  const WalletState({
    this.walletId,
    this.balance = 0.0,
    this.status = WalletStatus.idle,
    this.error,
  });

  WalletState copyWith({
    String? walletId,
    double? balance,
    WalletStatus? status,
    String? error,
  }) {
    return WalletState(
      walletId: walletId ?? this.walletId,
      balance: balance ?? this.balance,
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

  Future<void> fetchWallet(String walletIdFromUser) async {
    state = state.copyWith(status: WalletStatus.loading, error: null);

    try {
      final idToken = await _getIdToken();
      final walletData = await _apiClient.getWalletDetails(walletIdFromUser, idToken);

      state = state.copyWith(
        walletId: walletData['wallet_id'] as String? ?? walletIdFromUser,
        balance: (walletData['balance'] as num?)?.toDouble() ?? 0.0,
        status: WalletStatus.loaded,
      );
    } catch (e) {
      state = state.copyWith(status: WalletStatus.error, error: 'Failed to fetch wallet: $e');
      if (kDebugMode) print('[WalletNotifier] Error fetching wallet: $e');
    }
  }

  Future<void> sendFunds({
    required String recipientWalletId,
    required double amount,
  }) async {
    if (state.walletId == null) throw Exception('No wallet loaded');

    state = state.copyWith(status: WalletStatus.loading, error: null);

    try {
      final idToken = await _getIdToken();
      await _apiClient.sendFunds(
        fromWalletId: state.walletId!,
        toWalletId: recipientWalletId,
        amount: amount,
        idToken: idToken,
      );

      // Refresh wallet balance
      await fetchWallet(state.walletId!);

      state = state.copyWith(status: WalletStatus.loaded);
    } catch (e) {
      state = state.copyWith(status: WalletStatus.error, error: 'Failed to send funds: $e');
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
  final apiClient = PeoplesCoinApiClient();
  return WalletNotifier(apiClient);
});

