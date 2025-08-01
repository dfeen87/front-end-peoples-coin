// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // Needed to get the auth token

// Your UserModel class should be here. I'm including a placeholder based on
// the new user data structure we defined on the backend. You may need to
// adjust this to match your actual model.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String balance;
  final int goodwillCoins;
  final List<CardModel> cards;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.balance,
    required this.goodwillCoins,
    required this.cards,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse the list of cards from the JSON response
    var cardList = json['cards'] as List;
    List<CardModel> cardModels = cardList.map((cardJson) => CardModel.fromJson(cardJson)).toList();

    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      balance: json['balance'],
      goodwillCoins: json['goodwill_coins'],
      cards: cardModels,
    );
  }
}

// Model for the card data we'll receive from the backend
class CardModel {
  final String id;
  final String type;
  final String last4;

  CardModel({
    required this.id,
    required this.type,
    required this.last4,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'],
      type: json['type'],
      last4: json['last4'],
    );
  }
}

class ApiService {
  // Use the correct base URL for your frontend from the user's provided code.
  final String _baseUrl = "https://peoples-coin-service-105378934751.us-east4.run.app";

  // --- NEW METHOD ---
  // Fetches the user profile from your backend after a successful Firebase sign-in
  Future<UserModel> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    // Get the Firebase token to securely authenticate with your backend
    final token = await user.getIdToken();

    // *** FIX: Changed the URL path to match the new backend endpoint ***
    // The correct path is '/api/auth/users/me'
    final url = Uri.parse('$_baseUrl/api/auth/users/me');

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
        throw Exception('Failed to load user profile. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred while fetching user profile: $e');
    }
  }
}

