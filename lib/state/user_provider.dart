import 'package:flutter/foundation.dart';
import '../models/user_account.dart';
import '../service/api_client.dart';
import '../models/goodwill_action.dart';

class UserProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  // --- User Account State ---
  UserAccount? _userAccount;
  bool _isLoading = false;
  String? _error;

  // --- User's Goodwill Actions (Portfolio) State ---
  List<GoodwillAction> _userActions = [];
  bool _isFetchingActions = false;
  String? _actionsError;

  // --- Getters for User Account ---
  UserAccount? get userAccount => _userAccount;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;

  // --- Getters for User Portfolio ---
  List<GoodwillAction> get userActions => _userActions;
  bool get isFetchingActions => _isFetchingActions;
  bool get hasActionsError => _actionsError != null;
  String? get actionsError => _actionsError;

  UserProvider(this._apiClient);

  /// Fetch user account info (currently mock, replace with API call when ready)
  Future<void> fetchUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulated delay and mock user data
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
      print(_error);
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
    } catch (e) {
      _actionsError = "Failed to fetch your Bright Acts: $e";
      print(_actionsError);
    } finally {
      _isFetchingActions = false;
      notifyListeners();
    }
  }
}

