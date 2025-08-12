// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_account.dart';
import '../service/api_client.dart';
import '../models/goodwill_action.dart';

class UserProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  UserAccount? _currentUser;
  bool _isLoading = false;
  String? _error;

  List<GoodwillAction> _userActions = [];
  bool _isFetchingActions = false;
  String? _actionsError;

  // Wallet-specific state
  bool _isFetchingWallet = false;
  String? _walletError;

  UserProvider(this._apiClient);

  // User profile getters
  UserAccount? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;

  // Goodwill actions getters
  List<GoodwillAction> get userActions => _userActions;
  bool get isFetchingActions => _isFetchingActions;
  bool get hasActionsError => _actionsError != null;
  String? get actionsError => _actionsError;

  // Wallet getters (reading from currentUser fields)
  bool get isFetchingWallet => _isFetchingWallet;
  String? get walletError => _walletError;

  String get walletAddress => _currentUser?.walletId ?? '';
  String get walletPublicKey => _currentUser?.publicKey ?? '';
  String get encryptedPrivateKey => _currentUser?.encryptedPrivateKey ?? '';
  double get balance => _currentUser?.balance ?? 0.0;

  /// Always get fresh Firebase ID token
  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not signed in.');
    final token = await user.getIdToken();
    if (token.isEmpty) throw Exception('Failed to get Firebase ID token.');
    return token;
  }

  void setCurrentUser(UserAccount? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  /// Fetch authenticated user profile securely (includes wallet info)
  Future<void> fetchUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final idToken = await _getIdToken();
      _currentUser = await _apiClient.getAuthenticatedUserProfile(idToken: idToken);
      if (kDebugMode) {
        print('[UserProvider] Fetched user: ${_currentUser?.username}');
      }
    } catch (e) {
      _error = "Failed to fetch user data: $e";
      _currentUser = null;
      if (kDebugMode) {
        print('[UserProvider] Error fetching user: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch authenticated user's goodwill actions securely
  Future<void> fetchUserActions() async {
    if (_currentUser == null) return;

    _isFetchingActions = true;
    _actionsError = null;
    notifyListeners();

    try {
      final idToken = await _getIdToken();
      _userActions = await _apiClient.getUserGoodwillActions(userId: _currentUser!.id, idToken: idToken);
      if (kDebugMode) {
        print('[UserProvider] Fetched ${_userActions.length} user actions.');
      }
    } catch (e) {
      _actionsError = "Failed to fetch your Bright Acts: $e";
      if (kDebugMode) {
        print('[UserProvider] Error fetching user actions: $e');
      }
    } finally {
      _isFetchingActions = false;
      notifyListeners();
    }
  }

  /// Refresh wallet info separately if needed
  Future<void> refreshWallet() async {
    if (_currentUser == null) {
      _walletError = "No user signed in.";
      notifyListeners();
      return;
    }

    _isFetchingWallet = true;
    _walletError = null;
    notifyListeners();

    try {
      final idToken = await _getIdToken();
      final updatedUser = await _apiClient.getAuthenticatedUserProfile(idToken: idToken);
      _currentUser = updatedUser;
      if (kDebugMode) {
        print('[UserProvider] Wallet info refreshed');
      }
    } catch (e) {
      _walletError = "Failed to refresh wallet data: $e";
      if (kDebugMode) {
        print('[UserProvider] Error refreshing wallet: $e');
      }
    } finally {
      _isFetchingWallet = false;
      notifyListeners();
    }
  }

  /// Update user's wallet keys (public + encrypted private) in backend
  Future<void> updateWalletKeys({
    required String publicKey,
    required String encryptedPrivateKey,
  }) async {
    if (_currentUser == null) {
      throw Exception("No user signed in.");
    }

    final idToken = await _getIdToken();

    try {
      // TODO: Implement your API client method that updates wallet keys and returns updated user
      // final updatedUser = await _apiClient.updateUserWalletKeys(idToken, publicKey, encryptedPrivateKey);

      // For now, just update locally (simulate success)
      _currentUser = _currentUser!.copyWith(
        publicKey: publicKey,
        encryptedPrivateKey: encryptedPrivateKey,
      );
      notifyListeners();
      if (kDebugMode) {
        print('[UserProvider] Wallet keys updated locally');
      }
    } catch (e) {
      throw Exception('Failed to update wallet keys: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearActionsError() {
    _actionsError = null;
    notifyListeners();
  }

  void clearWalletError() {
    _walletError = null;
    notifyListeners();
  }
}

