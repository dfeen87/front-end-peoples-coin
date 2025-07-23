// lib/state/user_provider.dart

import 'package:flutter/foundation.dart';
import '../models/user_account.dart';
import '../service/api_client.dart';
import '../models/goodwill_action.dart';

class UserProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  // Existing state for user account
  UserAccount? _userAccount;
  bool _isLoading = false;
  String? _error;

  // State for the user's portfolio of goodwill actions
  List<GoodwillAction> _userActions = [];
  bool _isFetchingActions = false;
  String? _actionsError;

  // Public getters for user account
  UserAccount? get userAccount => _userAccount;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;

  // Public getters for the portfolio
  List<GoodwillAction> get userActions => _userActions;
  bool get isFetchingActions => _isFetchingActions;
  bool get hasActionsError => _actionsError != null;
  String? get actionsError => _actionsError;

  UserProvider(this._apiClient);

  Future<void> fetchUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // NOTE: This is still using mock data for the user account.
      // You can update this to use a real API call later.
      await Future.delayed(const Duration(seconds: 1));
      _userAccount = UserAccount(
        id: userId,
        firebaseUid: 'firebase_uid_$userId',
        email: 'user_$userId@example.com',
        username: 'User_$userId',
        balance: 1000.00,
        bio: 'Simulated user for BrightActs.',
        profileImageUrl: 'https://example.com/profile.png',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _error = "Failed to fetch user data: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATED: This method now calls the API client to fetch live data.
  Future<void> fetchUserActions(String userId) async {
    _isFetchingActions = true;
    _actionsError = null;
    notifyListeners();

    try {
      // This is the new, live API call, replacing the mock data.
      _userActions = await _apiClient.getUserGoodwillActions(userId);
    } catch (e) {
      _actionsError = "Failed to fetch your Bright Acts: $e";
    } finally {
      _isFetchingActions = false;
      notifyListeners();
    }
  }
}
