// lib/providers/wallet_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../service/api_client.dart';

enum WalletStatus { idle, loading, loaded, error }

class WalletProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  String? _walletId;
  double _balance = 0.0;
  WalletStatus _status = WalletStatus.idle;
  String? _error;

  String? get walletId => _walletId;
  double get balance => _balance;
  WalletStatus get status => _status;
  String? get error => _error;

  WalletProvider(this._apiClient);

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not signed in');
    final token = await user.getIdToken();
    if (token.isEmpty) throw Exception('Failed to get Firebase ID token');
    return token;
  }

  /// Call this after user signs in or when you want to refresh wallet data
  Future<void> fetchWallet(String walletIdFromUser) async {
    _status = WalletStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final idToken = await _getIdToken();

      // Make sure your API client returns a Map<String, dynamic> with 'wallet_id' and 'balance'
      final walletData = await _apiClient.getWalletDetails(walletIdFromUser, idToken);

      _walletId = walletData['wallet_id'] as String? ?? walletIdFromUser;
      _balance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;

      _status = WalletStatus.loaded;
    } catch (e) {
      _error = 'Failed to fetch wallet: $e';
      _status = WalletStatus.error;
      if (kDebugMode) print('[WalletProvider] Error fetching wallet: $e');
    }

    notifyListeners();
  }

  /// Placeholder for sending funds - extend this method when ready
  Future<void> sendFunds({
    required String recipientWalletId,
    required double amount,
  }) async {
    if (_walletId == null) throw Exception('No wallet loaded');

    _status = WalletStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final idToken = await _getIdToken();

      await _apiClient.sendFunds(
        fromWalletId: _walletId!,
        toWalletId: recipientWalletId,
        amount: amount,
        idToken: idToken,
      );

      // Refresh wallet balance after sending funds
      await fetchWallet(_walletId!);

      _status = WalletStatus.loaded;
    } catch (e) {
      _error = 'Failed to send funds: $e';
      _status = WalletStatus.error;
      if (kDebugMode) print('[WalletProvider] Error sending funds: $e');
      notifyListeners();
      rethrow;
    }

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

