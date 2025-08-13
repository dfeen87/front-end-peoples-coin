import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:your_app_name/service/api_client.dart'; // Assumes your ApiClient is here
import 'package:your_app_name/models/user_account.dart'; // Assumes the UserAccount model is here

/// A service class for interacting with the user account API endpoint.
class UserAccountService {
  final ApiClient _client;
  final String _baseUrl = 'v1/user_accounts';

  UserAccountService(this._client);

  /// Fetches a user's account details by their ID.
  /// Returns a [UserAccount] instance on success, or null on failure.
  Future<UserAccount?> getUserAccount(String userId) async {
    try {
      final response = await _client.get('$_baseUrl/$userId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return UserAccount.fromJson(json);
      } else {
        // Handle API errors (e.g., user not found)
        return null;
      }
    } catch (e) {
      // Handle network errors
      return null;
    }
  }

  /// Updates a user's profile information.
  /// Returns the updated [UserAccount] on success, or null on failure.
  Future<UserAccount?> updateUserProfile(
      String userId, Map<String, dynamic> updateData) async {
    try {
      final response = await _client.put(
        '$_baseUrl/$userId',
        jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return UserAccount.fromJson(json);
      } else {
        // Handle API errors
        return null;
      }
    } catch (e) {
      // Handle network errors
      return null;
    }
  }
}

