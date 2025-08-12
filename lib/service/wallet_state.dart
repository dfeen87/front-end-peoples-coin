import 'dart:async';

import 'package:flutter/foundation.dart';
import 'wallet_management.dart'; // Your wallet manager
import '../service/api_client.dart'; // Your intelligent backend client

/// Represents the combined wallet state exposed to UI
class WalletState {
  final double balance;
  final int goodwillTokens;
  final List<String> pendingTransactions;
  final bool isLoading;
  final String? errorMessage;

  WalletState({
    required this.balance,
    required this.goodwillTokens,
    required this.pendingTransactions,
    this.isLoading = false,
    this.errorMessage,
  });

  factory WalletState.initial() {
    return WalletState(
      balance: 0.0,
      goodwillTokens: 0,
      pendingTransactions: [],
      isLoading: false,
      errorMessage: null,
    );
  }

  WalletState copyWith({
    double? balance,
    int? goodwillTokens,
    List<String>? pendingTransactions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      goodwillTokens: goodwillTokens ?? this.goodwillTokens,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Updates wallet state from backend data safely.
  WalletState updatedWithBackendData(Map<String, dynamic> backendData) {
    return copyWith(
      balance: (backendData['balance'] is num) ? (backendData['balance'] as num).toDouble() : balance,
      goodwillTokens: backendData['goodwillTokens'] is int
          ? backendData['goodwillTokens'] as int
          : goodwillTokens,
      pendingTransactions: backendData['pendingTransactions'] is List
          ? List<String>.from(backendData['pendingTransactions'])
          : pendingTransactions,
      errorMessage: null,
      isLoading: false,
    );
  }
}

/// Service for managing wallet UI state and backend sync.
class WalletStateService extends ChangeNotifier {
  final WalletManager walletManager;
  final PeoplesCoinApiClient apiClient;

  WalletState _state = WalletState.initial();
  WalletState get state => _state;

  StreamSubscription<dynamic>? _backendEventsSub;

  WalletStateService({
    required this.walletManager,
    required this.apiClient,
  }) {
    _init();
  }

  /// Initializes backend event listening and triggers initial state load.
  void _init() {
    _backendEventsSub = apiClient.walletEventsStream.listen(_handleBackendEvent);
    refreshWalletState();
  }

  /// Handles incoming backend events to update wallet state.
  void _handleBackendEvent(dynamic event) {
    if (kDebugMode) {
      print('[WalletStateService] Backend event: $event');
    }
    if (event is Map<String, dynamic>) {
      final updatedState = _state.updatedWithBackendData(event);
      if (_state != updatedState) {
        _state = updatedState;
        notifyListeners();
      }
    }
  }

  /// Refreshes wallet state from backend API.
  Future<void> refreshWalletState() async {
    if (walletManager.wallets.isEmpty) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'No wallet loaded',
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final currentWallet = walletManager.wallets.last;
      final backendData = await apiClient.fetchWalletData(currentWallet.id);
      final updatedState = _state.updatedWithBackendData(backendData);
      if (_state != updatedState) {
        _state = updatedState;
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh wallet state: ${e.toString()}',
      );
    }
    notifyListeners();
  }

  /// Sends tokens from the current wallet to a specified address.
  Future<void> sendTokens(String toAddress, double amount) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final currentWallet = walletManager.wallets.last;
      await apiClient.sendTokens(currentWallet.id, toAddress, amount);
      await refreshWalletState();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send tokens: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  /// Properly disposes backend event subscription.
  @override
  void dispose() {
    _backendEventsSub?.cancel();
    super.dispose();
  }
}

