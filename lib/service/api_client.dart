import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_account.dart';
import '../models/goodwill_action.dart';
import '../models/proposal.dart';
import '../models/proposal_to_send.dart';
import '../models/vote_to_send.dart';
import '../models/ledger_entry.dart';
import '../models/wallet.dart';

/// This is a service class responsible for all API communication.
/// It is not tied to any state management and is provided by Riverpod.
class PeoplesCoinApiClient {
  final String _baseUrl;
  final http.Client _client;

  PeoplesCoinApiClient({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl = "https://peoples-coin-service-105378934751.us-central1.run.app";

  // Default timeout for all HTTP requests
  static const Duration _timeoutDuration = Duration(seconds: 15);

  /// Helper: Create auth headers with the Firebase ID token
  Map<String, String> _buildAuthHeaders(String idToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
  }

  /// Helper: Handle HTTP GET with timeout
  Future<http.Response> _getWithTimeout(Uri url, Map<String, String>? headers) async {
    return _client.get(url, headers: headers).timeout(_timeoutDuration);
  }

  /// Helper: Handle HTTP POST with timeout
  Future<http.Response> _postWithTimeout(Uri url, Map<String, String> headers, String body) async {
    return _client.post(url, headers: headers, body: body).timeout(_timeoutDuration);
  }

  // === User & Wallet Management ===

  /// Public (no-auth) endpoint to check username availability
  Future<bool> checkUsernameAvailability(String username) async {
    final encodedUsername = Uri.encodeComponent(username);
    final url = Uri.parse('$_baseUrl/users/check-username/$encodedUsername');

    try {
      final response = await _getWithTimeout(url, null);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['available'] ?? false;
      } else {
        return false;
      }
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (kDebugMode) print('Exception checking username availability: $e');
      return false;
    }
  }

  /// Create user and wallet post-signup
  Future<UserAccount> createUserAndWallet({
    required String username,
    required String recaptchaToken,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/api/auth/users/create');
    final headers = _buildAuthHeaders(idToken);

    final body = json.encode({
      'username': username,
      'recaptcha_token': recaptchaToken,
    });

    final response = await _postWithTimeout(url, headers, body);

    if (response.statusCode == 201) {
      final jsonMap = json.decode(response.body);
      return UserAccount.fromJson(jsonMap);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception('Failed to create user: ${errorBody['message']}');
    }
  }

  /// Get authenticated user's profile data
  Future<UserAccount> getAuthenticatedUserProfile({required String idToken}) async {
    final url = Uri.parse('$_baseUrl/api/auth/users/me');
    final headers = _buildAuthHeaders(idToken);
    final response = await _getWithTimeout(url, headers);

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

  /// Get the user's wallet details, including the balance.
  Future<Wallet> getWallet({
    required String walletId,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/api/auth/wallet/$walletId');
    final headers = _buildAuthHeaders(idToken);
    final response = await _getWithTimeout(url, headers);

    if (response.statusCode == 200) {
      return Wallet.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get wallet details: ${response.body}');
    }
  }

  // === Goodwill Actions ===

  Future<Map<String, dynamic>> submitGoodwill({
    required Map<String, dynamic> goodwillAction,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/goodwill');
    final headers = _buildAuthHeaders(idToken);
    final body = json.encode(goodwillAction);
    final response = await _postWithTimeout(url, headers, body);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to submit goodwill action: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<GoodwillAction>> getUserGoodwillActions({
    required String userId,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/goodwill/user/$userId');
    final headers = _buildAuthHeaders(idToken);
    final response = await _getWithTimeout(url, headers);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => GoodwillAction.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to fetch goodwill actions: ${response.statusCode} - ${response.body}');
    }
  }

  // === Proposals ===

  Future<List<Proposal>> listProposals({required String idToken, String? status}) async {
    final urlStr = status == null ? '$_baseUrl/proposals' : '$_baseUrl/proposals?status=$status';
    final url = Uri.parse(urlStr);
    final headers = _buildAuthHeaders(idToken);
    final response = await _getWithTimeout(url, headers);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => Proposal.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to fetch proposals: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Proposal> getProposalDetails({required String proposalId, required String idToken}) async {
    final url = Uri.parse('$_baseUrl/proposals/$proposalId');
    final headers = _buildAuthHeaders(idToken);
    final response = await _getWithTimeout(url, headers);

    if (response.statusCode == 200) {
      return Proposal.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          'Failed to fetch proposal details: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createProposal({
    required ProposalToSend proposal,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/proposals');
    final headers = _buildAuthHeaders(idToken);
    final body = json.encode(proposal.toJson());
    final response = await _postWithTimeout(url, headers, body);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to create proposal: ${response.statusCode} - ${response.body}');
    }
  }

  // === Votes ===

  Future<Map<String, dynamic>> submitVote({required VoteToSend vote, required String idToken}) async {
    final url = Uri.parse('$_baseUrl/votes');
    final headers = _buildAuthHeaders(idToken);
    final body = json.encode(vote.toJson());
    final response = await _postWithTimeout(url, headers, body);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to submit vote: ${response.statusCode} - ${response.body}');
    }
  }

  // === Loves ===

  /// Send Loves from one wallet to another.
  Future<Map<String, dynamic>> sendLoves({
    required String senderWallet,
    required String recipientWallet,
    required int amount,
    String? memo,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/loves/send');
    final headers = _buildAuthHeaders(idToken);
    final body = json.encode({
      'sender_wallet': senderWallet,
      'recipient_wallet': recipientWallet,
      'amount': amount,
      if (memo != null) 'memo': memo,
    });
    final response = await _postWithTimeout(url, headers, body);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to send loves: ${response.statusCode} - ${response.body}');
    }
  }

  // === Ledger ===

  Future<List<LedgerEntry>> getLedgerEntries({required String idToken, int page = 1}) async {
    final url = Uri.parse('$_baseUrl/ledger?page=$page');
    final headers = _buildAuthHeaders(idToken);
    final response = await _getWithTimeout(url, headers);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => LedgerEntry.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to fetch ledger entries: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<LedgerEntry>> searchLedger({required String query, required String idToken}) async {
    final url = Uri.parse('$_baseUrl/ledger/search?query=$query');
    final headers = _buildAuthHeaders(idToken);
    final response = await _getWithTimeout(url, headers);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => LedgerEntry.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to search ledger: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> getGoodwillStatus(String actionId, String idToken) async {
    final url = Uri.parse('$_baseUrl/goodwill/status/$actionId');
    final headers = _buildAuthHeaders(idToken);

    final response = await _getWithTimeout(url, headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] ?? 'UNKNOWN';
    } else {
      throw Exception(
          'Failed to fetch goodwill status: ${response.statusCode} - ${response.body}');
    }
  }
}

// A Riverpod provider to make the API client available throughout the app.
final apiClientProvider = Provider<PeoplesCoinApiClient>((ref) {
  return PeoplesCoinApiClient();
});

