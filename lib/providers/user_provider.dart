import 'package:flutter/foundation.dart';
import '../models/user_account.dart';
import '../services/api_client.dart';

/// Manages the state of the user account.
///
/// This class will hold the current user's data and provide methods
/// to fetch or update it. It uses ChangeNotifier to notify any widgets
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
      // This is a hypothetical function in our API client we'd need to add.
      // For now, we'll simulate it.
      // final user = await _apiClient.getUserDetails(userId);
      
      // --- SIMULATED DATA for now ---
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      final simulatedUser = UserAccount(
        id: userId,
        firebaseUid: 'firebase_123',
        balance: 1234.56,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        email: 'user@brightacts.com',
        username: 'GoodSamaritan',
      );
      // --- END SIMULATION ---

      _userAccount = simulatedUser; // Update the user data
    } catch (e) {
      _error = "Failed to fetch user data: $e";
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading is complete (with data or error)
    }
  }
}
