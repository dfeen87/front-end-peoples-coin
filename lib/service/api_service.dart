// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // Needed to get the auth token

// Your UserModel class from before should be in this file
class UserModel {
  // ... (same as before)
}


class ApiService {
  final String _baseUrl = "https://peoples-coin-service-105378934751.us-east4.run.app";

  // ... (your existing registerUser method) ...

  // --- NEW METHOD ---
  // Fetches the user profile from your backend after a successful Firebase sign-in
  Future<UserModel> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    // Get the Firebase token to securely authenticate with your backend
    final token = await user.getIdToken();

    // TODO: Confirm the exact endpoint path with your backend developer.
    // I am assuming '/api/users/me' which is a common pattern.
    final url = Uri.parse('$_baseUrl/api/users/me');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Send the token for secure access
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return UserModel.fromJson(responseData);
      } else {
        throw Exception('Failed to load user profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching user profile: $e');
    }
  }
}
