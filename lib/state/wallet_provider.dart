// lib/state/wallet_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../service/wallet_service.dart';
import '../service/wallet_manager.dart';
import '../state/user_provider.dart';
import '../models/user_account.dart';
import '../models/wallet_models.dart';
import '../service/api_client.dart'; // Assuming this is your API client

/// The primary provider for all wallet-related state and actions.
/// It combines the functionality of the old WalletFacilitator and WalletManager.
///
/// This AsyncNotifier handles the lifecycle of the user's wallet:
/// 1. Initializes the wallet when the user logs in.
/// 2. Fetches the wallet balance from the backend.
/// 3. Provides methods for wallet actions like signing transactions.
class WalletNotifier extends AsyncNotifier<WalletState> {
  final _apiClient = PeoplesCoinApiClient();

  @override
  Future<WalletState> build() async {
    // We use ref.watch to automatically re-run this provider if the user or token changes.
    ref.listen(userAccountProvider, (_, next) {
      next.when(
        data: (user) async {
          // If a user logs in, initialize their wallet.
          if (user != null && state.value?.userAccount?.id != user.id) {
            await initializeWallet(user);
          }
        },
        loading: () {}, // Do nothing on loading
        error: (e, st) => state = AsyncValue.error(e, st),
      );
    });

    final userAccount = await ref.watch(userAccountProvider.future);
    if (userAccount != null) {
      await initializeWallet(userAccount);
    }
    
    // Initial state with a null wallet.
    return WalletState(
      currentWallet: null,
      userAccount: userAccount,
      balance: 0.0,
    );
  }

  /// Initializes the wallet for a specific user.
  Future<void> initializeWallet(UserAccount userAccount) async {
    state = const AsyncValue.loading();
    try {
      final sessionToken = await _getSessionToken();
      if (sessionToken == null) {
        throw Exception('User session token is not available.');
      }

      final walletManager = ref.read(walletManagerProvider);
      final wallet = await walletManager.initializeWallet(userAccount: userAccount, sessionToken: sessionToken);

      final balance = await _fetchBalance(wallet.id);

      state = AsyncValue.data(
        WalletState(
          currentWallet: wallet,
          userAccount: userAccount,
          balance: balance,
        ),
      );

    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Fetches the wallet balance from the backend.
  Future<double> _fetchBalance(String walletId) async {
    try {
      final response = await _apiClient.getWalletBalance(walletId);
      return response['balance'] as double;
    } catch (e) {
      // In a real app, you might want to handle API errors more gracefully.
      return 0.0;
    }
  }

  /// Signs a transaction using the current wallet.
  Future<String?> signTransaction(String dataToSign) async {
    final sessionToken = await _getSessionToken();
    if (sessionToken == null || state.value?.currentWallet == null) {
      state = AsyncValue.error('No wallet is initialized or session is invalid.', StackTrace.empty);
      return null;
    }
    
    try {
      state = AsyncValue.data(state.value!.copyWith(isLoading: true));
      final walletManager = ref.read(walletManagerProvider);
      final signature = await walletManager.signTransaction(
        dataToSign: dataToSign,
        sessionToken: sessionToken,
      );
      state = AsyncValue.data(state.value!.copyWith(isLoading: false));
      return signature;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
  
  /// Helper to get the Firebase session token.
  Future<String?> _getSessionToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }
}

/// The state class for the wallet provider.
class WalletState {
  final Wallet? currentWallet;
  final UserAccount? userAccount;
  final double balance;
  final bool isLoading;
  final String? errorMessage;

  WalletState({
    required this.currentWallet,
    required this.userAccount,
    required this.balance,
    this.isLoading = false,
    this.errorMessage,
  });

  WalletState copyWith({
    Wallet? currentWallet,
    UserAccount? userAccount,
    double? balance,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WalletState(
      currentWallet: currentWallet ?? this.currentWallet,
      userAccount: userAccount ?? this.userAccount,
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// The provider for the new WalletNotifier.
final walletProvider = AsyncNotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);

/// A provider that exposes just the wallet balance for UI widgets.
final walletBalanceProvider = Provider<AsyncValue<double>>((ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.map(
    data: (data) => AsyncValue.data(data.value.balance),
    error: (error) => AsyncValue.error(error.error, error.stackTrace),
    loading: (_) => const AsyncValue.loading(),
  );
});

// Providers for dependencies (WalletService and WalletManager)
final walletServiceProvider = Provider((ref) => WalletService());

final walletManagerProvider = Provider<WalletManager>((ref) {
  final walletService = ref.watch(walletServiceProvider);
  const secureStorage = FlutterSecureStorage();
  return WalletManager(walletService, secureStorage);
});
