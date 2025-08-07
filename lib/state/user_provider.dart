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

  UserAccount? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;

  List<GoodwillAction> get userActions => _userActions;
  bool get isFetchingActions => _isFetchingActions;
  bool get hasActionsError => _actionsError != null;
  String? get actionsError => _actionsError;

  UserProvider(this._apiClient);

  /// Always gets a fresh Firebase ID token
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

  /// Fetch authenticated user profile securely
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
  Future<void> fetchUserActions(String userId) async {
    _isFetchingActions = true;
    _actionsError = null;
    notifyListeners();

    try {
      final idToken = await _getIdToken();
      _userActions = await _apiClient.getUserGoodwillActions(userId: userId, idToken: idToken);
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearActionsError() {
    _actionsError = null;
    notifyListeners();
  }
}

