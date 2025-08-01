import 'package:flutter/foundation.dart'; // For kDebugMode and ChangeNotifier
import '../models/user_account.dart';
import '../service/api_client.dart';

class UserProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  UserAccount? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserAccount? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider(this._apiClient);

  Future<void> fetchUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Replace this with real API call when ready
      await Future.delayed(const Duration(seconds: 1));
      _currentUser = UserAccount(
        id: userId,
        firebaseUid: 'firebase_123',
        balance: 1234.56,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        email: 'user@brightacts.com',
        username: 'GoodSamaritan',
      );
    } catch (e) {
      _error = "Failed to fetch user data: $e";
      _currentUser = null; // FIX: Clear the user if fetching fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // TODO: Your `MyPortfolioPage` and other pages rely on a `fetchUserActions` method.
  // This method is missing from this file and needs to be re-added.
  // Example of what it might look like:
  /*
  Future<void> fetchUserActions(String userId) async {
    // ...
  }
  */
}
