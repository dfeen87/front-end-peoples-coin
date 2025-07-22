import 'package:flutter/foundation.dart';
import '../models/user_account.dart'; // Make sure this import path is correct
import '../services/api_client.dart'; // Make sure this import path is correct

/// Manages the state of the user account.
///
/// This class will hold the current user's data and provide methods
/// to fetch or update it.
/// It uses ChangeNotifier to notify any widgets
/// that are listening when the user data changes.
class UserProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  // Private backing fields for the state
  UserAccount? _userAccount;
  bool _isLoading = false;
  String? _error;

  // Public getters to access the state safely
  UserAccount? get userAccount => _userAccount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider(this._apiClient);

  /// Fetches the user account data from the API.
  Future<void> fetchUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI that we are now loading

    try {
      // In a real app, you'd call your API client here to fetch user data:
      // _userAccount = await _apiClient.getUserDetails(userId);
      // For now, we'll simulate a user account.
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
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
      notifyListeners(); // Notify UI that loading is complete (with data or error)
    }
  }
}
