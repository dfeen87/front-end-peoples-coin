// lib/app_state_providers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'service/api_client.dart';

/// Main app state class holding shared state and services.
/// You can expand this with more providers or services as needed.
class PeoplesCoinAppState extends ChangeNotifier {
  final PeoplesCoinApiClient apiClient;

  PeoplesCoinAppState({PeoplesCoinApiClient? apiClient})
      : apiClient = apiClient ?? PeoplesCoinApiClient();

  // --- Example of state variables you might want to keep ---
  // String? _currentUsername;
  // bool _isLoggedIn = false;

  // String? get currentUsername => _currentUsername;
  // set currentUsername(String? username) {
  //   _currentUsername = username;
  //   notifyListeners();
  // }

  // bool get isLoggedIn => _isLoggedIn;
  // set isLoggedIn(bool loggedIn) {
  //   _isLoggedIn = loggedIn;
  //   notifyListeners();
  // }

  // --- Delegated API client methods ---

  /// Checks if the given username is available by delegating to the API client.
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      return await apiClient.checkUsernameAvailability(username);
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkUsernameAvailability: $e');
      }
      rethrow;
    }
  }

  /// Example: Add more delegation methods to wrap API calls here...

  // Future<UserAccount> getUserById(String userId) => apiClient.getUserById(userId);
  // Future<void> createUserAccount(...) => apiClient.createUserAccount(...);
  // etc.

  // --- Add any additional shared app state and methods below ---
}

