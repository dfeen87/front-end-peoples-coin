import 'package:flutter/foundation.dart';
import '../models/user_account.dart';
import '../services/api_client.dart';

class UserProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  UserAccount? _userAccount;
  bool _isLoading = false;
  String? _error;

  UserAccount? get userAccount => _userAccount;
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
      _userAccount = UserAccount(
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

