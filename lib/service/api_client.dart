import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' as browser_http
    if (dart.library.io) 'package:http/http.dart';

class PeoplesCoinApiClient {
  final http.Client _client;
  final String baseUrl;

  PeoplesCoinApiClient({required this.baseUrl})
      : _client = kIsWeb ? browser_http.BrowserClient() : http.Client();

  /// Check if a username is available
  Future<bool> checkUsernameAvailability(String username) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/username-check/$username');

    final response = await _client.get(uri, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'] == true;
    } else {
      throw Exception('Failed to check username availability: ${response.body}');
    }
  }

  /// Create a user wallet
  Future<void> createUserWallet({
    required String username,
    required String publicKey,
    required String encryptedPrivateKey,
    required String recaptchaToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/register-wallet');
    final body = jsonEncode({
      'username': username,
      'publicKey': publicKey,
      'encryptedPrivateKey': encryptedPrivateKey,
      'recaptchaToken': recaptchaToken,
    });

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to register user wallet: ${response.body}');
    }
  }

  /// Clean up the HTTP client
  void dispose() {
    _client.close();
  }
}

