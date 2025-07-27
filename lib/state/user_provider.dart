// lib/state/user_provider.dart

import 'package:flutter/foundation.dart'; // For kDebugMode and ChangeNotifier
import '../models/user_account.dart';    // Your UserAccount model
import '../service/api_client.dart';      // Your ApiClient to fetch data
import '../models/goodwill_action.dart'; // Your GoodwillAction model

class UserProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient; // Dependency: Your API client

  // --- User Account State ---
  UserAccount? _currentUser; // This stores the current user's data
  bool _isLoading = false;
  String? _error;

  // --- User's Goodwill Actions (Portfolio) State ---
  List<GoodwillAction> _userActions = [];
  bool _isFetchingActions = false;
  String? _actionsError;

  // --- Getters for User Account ---
  // This getter is what all pages should use to access the current user
  UserAccount? get currentUser => _currentUser; // <-- This is the getter to use
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;

  // --- Getters for User Portfolio ---
  List<GoodwillAction> get userActions => _userActions;
  bool get isFetchingActions => _isFetchingActions;
  bool get hasActionsError => _actionsError != null;
  String? get actionsError => _actionsError;

  // Constructor: Requires an instance of PeoplesCoinApiClient
  UserProvider(this._apiClient);

  /// Sets the current user account and notifies listeners.
  /// This is typically called after a successful login or user data refresh.
  void setCurrentUser(UserAccount? user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Clears the current user account, effectively logging out the user.
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  /// Fetch user account info from the backend API.
  /// Replaces the mock data with an actual API call.
  Future<void> fetchUser(String userId) async {
    _isLoading = true;
    _error = null; // Clear previous errors
    notifyListeners();

    try {
      // Replace with your actual API call using _apiClient
      // Example: Assuming your API client has a getUserById method
      _currentUser = await _apiClient.getUserById(userId);
      if (kDebugMode) print('[UserProvider] Fetched user: ${_currentUser?.username}');
    } catch (e) {
      _error = "Failed to fetch user data: $e";
      if (kDebugMode) print('[UserProvider] Error fetching user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user's goodwill actions portfolio from backend
  Future<void> fetchUserActions(String userId) async {
    _isFetchingActions = true;
    _actionsError = null;
    notifyListeners();

    try {
      _userActions = await _apiClient.getUserGoodwillActions(userId);
      if (kDebugMode) print('[UserProvider] Fetched ${_userActions.length} user actions.');
    } catch (e) {
      _actionsError = "Failed to fetch your Bright Acts: $e";
      if (kDebugMode) print('[UserProvider] Error fetching user actions: $e');
    } finally {
      _isFetchingActions = false;
      notifyListeners();
    }
  }

  /// Clears current user-related error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clears current actions-related error state
  void clearActionsError() {
    _actionsError = null;
    notifyListeners();
  }
}
