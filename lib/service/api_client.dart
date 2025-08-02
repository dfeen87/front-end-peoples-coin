import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Required for SocketException
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

// Import your models
import '../models/user_account.dart';
import '../models/goodwill_action.dart';
import '../models/goodwill_action_to_send.dart';
import '../models/proposal.dart';
import '../models/proposal_to_send.dart';
import '../models/vote_to_send.dart';
import '../models/public_ledger_entry.dart';

// ENHANCEMENT: Custom exceptions for better error handling in the UI
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;
  ApiException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class PeoplesCoinApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  // ENHANCEMENT: Inject http.Client for testability
  PeoplesCoinApiClient({http.Client? httpClient, String? baseUrl})
      : _httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? dotenv.env['API_URL'] ?? 'https://peoples-coin-service-105378934751.us-central1.run.app';

  static const _timeout = Duration(seconds: 15);
  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  // --- Centralized GET ---
  Future<dynamic> _get(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    try {
      final response = await _httpClient.get(uri, headers: _jsonHeaders).timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    } catch (e) {
      if (kDebugMode) print('Error in _get($endpoint): $e');
      rethrow;
    }
  }

  // --- Centralized POST ---
  Future<dynamic> _post(String endpoint, {required Map<String, dynamic> body}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    try {
      final response = await _httpClient.post(uri, headers: _jsonHeaders, body: json.encode(body)).timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    } catch (e) {
      if (kDebugMode) print('Error in _post($endpoint): $e');
      rethrow;
    }
  }

  // --- Response handler ---
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      throw ApiException(
        'Request failed',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  // === User ===

  Future<void> unifiedSignUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final url = Uri.parse('https://us-central1-brightacts-frontend-50f58.cloudfunctions.net/unifiedSignUp');
    final body = {
      'email': email,
      'password': password,
      'username': username,
    };
    try {
      final response = await _httpClient.post(url, headers: _jsonHeaders, body: json.encode(body)).timeout(_timeout);
      _handleResponse(response);
    } on SocketException {
      throw NetworkException('Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    }
  }

  Future<UserAccount> getUserById(String userId) async {
    final data = await _get('api/v1/users/$userId');
    return UserAccount.fromJson(data);
  }

  // Updated method: check username availability
  Future<bool> checkUsernameAvailability(String username) async {
    final url = Uri.parse('$baseUrl/users/username-check/${Uri.encodeComponent(username)}');
    try {
      final response = await _httpClient.get(url, headers: _jsonHeaders).timeout(_timeout);
      final data = _handleResponse(response);
      return data['available'] == true;
    } on SocketException {
      throw NetworkException('Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    } catch (e) {
      if (kDebugMode) print('Error checking username: $e');
      rethrow;
    }
  }

  Future<void> createUserAccount({
    required String firebaseUid,
    required String email,
    String? username,
  }) async {
    final body = {
      'firebase_uid': firebaseUid,
      'email': email,
      if (username != null) 'username': username,
    };
    await _post('api/v1/users', body: body);
  }

  Future<void> createUserWallet({
    required String username,
    required String publicKey,
    required String encryptedPrivateKey,
  }) => _post('api/v1/users/register-wallet', body: {
        'username': username,
        'public_key': publicKey,
        'encrypted_private_key': encryptedPrivateKey,
      });

  // === Goodwill Actions ===

  Future<List<GoodwillAction>> getUserGoodwillActions(String userId) async {
    final List<dynamic> data = await _get('api/v1/users/$userId/goodwill-actions');
    return data.map((item) => GoodwillAction.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> submitGoodwill(GoodwillActionToSend actionToSend) async {
    return await _post('metabolic/submit_goodwill', body: actionToSend.toJson()) as Map<String, dynamic>;
  }

  // === Proposals ===

  Future<List<Proposal>> listProposals({String? status}) async {
    var endpoint = 'api/v1/governance/proposals';
    if (status != null && status.isNotEmpty) {
      endpoint += '?status=$status';
    }
    final List<dynamic> data = await _get(endpoint);
    return data.map((item) => Proposal.fromJson(item)).toList();
  }

  Future<Proposal> getProposalDetails(String proposalId) async {
    final data = await _get('api/v1/governance/proposals/$proposalId');
    return Proposal.fromJson(data);
  }

  Future<Map<String, dynamic>> createProposal(ProposalToSend proposalToSend) async {
    return await _post('api/v1/governance/proposals', body: proposalToSend.toJson()) as Map<String, dynamic>;
  }

  // === Votes ===

  Future<Map<String, dynamic>> submitVote(VoteToSend voteToSend) async {
    return await _post('api/v1/governance/proposals/${voteToSend.proposalId}/vote', body: voteToSend.toJson()) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getVotingResults(String proposalId) async {
    final data = await _get('api/v1/governance/proposals/$proposalId/results');
    return {'forVotes': data['forVotes'], 'againstVotes': data['againstVotes']};
  }

  // === Ledger ===

  Future<List<PublicLedgerEntry>> getLedgerEntries({int page = 1}) async {
    final List<dynamic> data = await _get('api/v1/ledger/public?page=$page');
    return data.map((item) => PublicLedgerEntry.fromJson(item)).toList();
  }

  Future<List<PublicLedgerEntry>> searchLedger({required String query}) async {
    final endpoint = 'api/v1/ledger/search?q=${Uri.encodeComponent(query)}';
    final List<dynamic> data = await _get(endpoint);
    return data.map((item) => PublicLedgerEntry.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> sendLoves({
    required String senderWalletId,
    required String recipientWalletId,
    required int amount,
    String? memo,
  }) async {
    return await _post('api/v1/transactions/send', body: {
      'sender_id': senderWalletId,
      'recipient_id': recipientWalletId,
      'amount': amount,
      if (memo != null && memo.isNotEmpty) 'memo': memo,
    }) as Map<String, dynamic>;
  }

  // === Metabolic status check ===
  Future<String> checkMetabolicStatus() async {
    final uri = Uri.parse('$baseUrl/metabolic/status');
    try {
      final response = await _httpClient.get(uri, headers: _jsonHeaders).timeout(_timeout);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw ApiException('Failed to check metabolic status', statusCode: response.statusCode);
      }
    } on SocketException {
      throw NetworkException('Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    }
  }

  // === PoW Challenge & Verification ===

  Future<Map<String, dynamic>> getPowChallenge() async {
    final data = await _get('immune/pow_challenge');
    return data as Map<String, dynamic>;
  }

  Future<bool> verifyPow({
    required String challenge,
    required String nonce,
  }) async {
    final response = await _post('immune/verify_pow', body: {
      'challenge': challenge,
      'nonce': nonce,
    });
    return response['success'] == true;
  }
}

