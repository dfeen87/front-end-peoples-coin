// lib/service/api_client.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_account.dart';
import '../models/goodwill_action.dart';
import '../models/proposal.dart';
import '../models/proposal_to_send.dart';
import '../models/vote_to_send.dart';
import '../models/ledger_entry.dart';

class PeoplesCoinApiClient {
  final String _baseUrl =
      "https://peoples-coin-service-105378934751.us-central1.run.app";

  // Default timeout for all HTTP requests
  static const Duration _timeoutDuration = Duration(seconds: 15);

  /// Helper: Get current Firebase ID token for auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }
    final token = await user.getIdToken(true);
    if (token.isEmpty) {
      throw Exception('Failed to get Firebase ID token.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Helper: Handle HTTP GET with retry and timeout
  Future<http.Response> _getWithRetry(Uri url, Map<String, String>? headers,
      {int retries = 3}) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await http.get(url, headers: headers).timeout(_timeoutDuration);
        return response;
      } on TimeoutException catch (_) {
        attempt++;
        if (attempt >= retries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      } catch (e) {
        attempt++;
        if (attempt >= retries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  /// Helper: Handle HTTP POST with retry and timeout
  Future<http.Response> _postWithRetry(Uri url, Map<String, String> headers, String body,
      {int retries = 3}) async {
    int attempt = 0;
    while (true) {
      try {
        final response =
            await http.post(url, headers: headers, body: body).timeout(_timeoutDuration);
        return response;
      } on TimeoutException catch (_) {
        attempt++;
        if (attempt >= retries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      } catch (e) {
        attempt++;
        if (attempt >= retries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  /// Public (no-auth) endpoint to check username availability
  Future<bool> checkUsernameAvailability(String username) async {
    final encodedUsername = Uri.encodeComponent(username);
    final url = Uri.parse('$_baseUrl/users/check-username/$encodedUsername');

    try {
      final response = await _getWithRetry(url, null);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['available'] ?? false;
      } else {
        print(
          'Failed to check username. '
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Exception checking username availability: $e');
      return false;
    }
  }

  /// Get authenticated user's profile data (secured)
  Future<UserAccount> getUserProfile() async {
    final url = Uri.parse('$_baseUrl/api/auth/users/me');
    final headers = await _getAuthHeaders();

    final response = await _getWithRetry(url, headers);

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return UserAccount.fromJson(jsonMap);
      } catch (e) {
        throw Exception('Failed to parse user profile JSON: $e');
      }
    } else {
      throw Exception(
          'Failed to fetch user profile: ${response.statusCode} - ${response.body}');
    }
  }

  /// Create user and wallet post-signup (secured)
  Future<void> createUserAndWallet({
    required String username,
    required String recaptchaToken,
    required String publicKey,
    required String encryptedPrivateKey,
  }) async {
    final url = Uri.parse('$_baseUrl/api/auth/users/create');
    final headers = await _getAuthHeaders();

    final body = json.encode({
      'username': username,
      'recaptcha_token': recaptchaToken,
      'public_key': publicKey,
      'encrypted_private_key': encryptedPrivateKey,
    });

    final response = await _postWithRetry(url, headers, body);

    if (response.statusCode == 201) {
      print('[createUserAndWallet] User & wallet created successfully.');
    } else if (response.statusCode == 409) {
      throw Exception('Username already exists. Body: ${response.body}');
    } else if (response.statusCode == 400) {
      throw Exception('Bad request — check payload. Body: ${response.body}');
    } else if (response.statusCode == 403) {
      throw Exception(
          'Forbidden — ID token or reCAPTCHA might be invalid. Body: ${response.body}');
    } else {
      throw Exception(
          'Unexpected error. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // === Goodwill Actions ===

  Future<Map<String, dynamic>> submitGoodwill({
    required Map<String, dynamic> goodwillAction,
  }) async {
    final url = Uri.parse('$_baseUrl/goodwill');
    final headers = await _getAuthHeaders();

    final body = json.encode(goodwillAction);
    final response = await _postWithRetry(url, headers, body);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to submit goodwill action: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<GoodwillAction>> getUserGoodwillActions({
    required String userId,
  }) async {
    final url = Uri.parse('$_baseUrl/goodwill/user/$userId');
    final headers = await _getAuthHeaders();

    final response = await _getWithRetry(url, headers);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => GoodwillAction.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to fetch goodwill actions: ${response.statusCode} - ${response.body}');
    }
  }

  // === Proposals ===

  Future<List<Proposal>> listProposals({String? status}) async {
    final urlStr =
        status == null ? '$_baseUrl/proposals' : '$_baseUrl/proposals?status=$status';
    final url = Uri.parse(urlStr);
    final headers = await _getAuthHeaders();

    final response = await _getWithRetry(url, headers);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => Proposal.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to fetch proposals: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Proposal> getProposalDetails({required String proposalId}) async {
    final url = Uri.parse('$_baseUrl/proposals/$proposalId');
    final headers = await _getAuthHeaders();

    final response = await _getWithRetry(url, headers);

    if (response.statusCode == 200) {
      return Proposal.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          'Failed to fetch proposal details: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createProposal({
    required ProposalToSend proposal,
  }) async {
    final url = Uri.parse('$_baseUrl/proposals');
    final headers = await _getAuthHeaders();

    final body = json.encode(proposal.toJson());
    final response = await _postWithRetry(url, headers, body);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to create proposal: ${response.statusCode} - ${response.body}');
    }
  }

  // === Votes ===

  Future<Map<String, dynamic>> submitVote({required VoteToSend vote}) async {
    final url = Uri.parse('$_baseUrl/votes');
    final headers = await _getAuthHeaders();

    final body = json.encode(vote.toJson());
    final response = await _postWithRetry(url, headers, body);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to submit vote: ${response.statusCode} - ${response.body}');
    }
  }

  // === Loves ===

  Future<Map<String, dynamic>> sendLoves({
    required Map<String, dynamic> sendLovesData,
  }) async {
    final url = Uri.parse('$_baseUrl/loves/send');
    final headers = await _getAuthHeaders();

    final body = json.encode(sendLovesData);
    final response = await _postWithRetry(url, headers, body);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to send loves: ${response.statusCode} - ${response.body}');
    }
  }

  // === Ledger ===

  Future<List<LedgerEntry>> getLedgerEntries({int page = 1}) async {
    final url = Uri.parse('$_baseUrl/ledger?page=$page');
    final headers = await _getAuthHeaders();

    final response = await _getWithRetry(url, headers);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => LedgerEntry.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to fetch ledger entries: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<LedgerEntry>> searchLedger({required String query}) async {
    final url = Uri.parse('$_baseUrl/ledger/search?query=$query');
    final headers = await _getAuthHeaders();

    final response = await _getWithRetry(url, headers);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => LedgerEntry.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to search ledger: ${response.statusCode} - ${response.body}');
    }
  }

  // === User Actions ===

  Future<List<Map<String, dynamic>>> fetchUserActions({required String userId}) async {
    final url = Uri.parse('$_baseUrl/actions/user/$userId');
    final headers = await _getAuthHeaders();

    final response = await _getWithRetry(url, headers);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception(
          'Failed to fetch user actions: ${response.statusCode} - ${response.body}');
    }
  }

  // === Goodwill Status ===

  Future<String> getGoodwillStatus(String actionId) async {
    final url = Uri.parse('$_baseUrl/goodwill/status/$actionId');
    final headers = await _getAuthHeaders();

    final response = await _getWithRetry(url, headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] ?? 'UNKNOWN';
    } else {
      throw Exception(
          'Failed to fetch goodwill status: ${response.statusCode} - ${response.body}');
    }
  }
}

