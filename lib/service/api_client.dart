import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

import '../models/user_account.dart';
import '../models/goodwill_action.dart';
import '../models/goodwill_action_to_send.dart';
import '../models/proposal.dart';
import '../models/proposal_to_send.dart';
import '../models/vote_to_send.dart';
import '../models/public_ledger_entry.dart';

// ------------------ Custom exceptions ------------------

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;
  ApiException(this.message, {this.statusCode, this.responseBody});
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

// ------------------ API Client ------------------

class PeoplesCoinApiClient {
  final String baseUrl;
  final http.Client _httpClient;
  final String? firebaseApiKey;

  PeoplesCoinApiClient({
    http.Client? httpClient,
    String? baseUrl,
    String? firebaseApiKey,
  })  : _httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ??
            dotenv.env['API_URL'] ??
            'https://peoples-coin-service-105378934751.us-central1.run.app',
        firebaseApiKey = firebaseApiKey ?? dotenv.env['FIREBASE_API_KEY'];

  static const _timeout = Duration(seconds: 15);

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
      };

  // ------------------ Low-level HTTP helpers ------------------

  Future<dynamic> _get(String endpoint) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    try {
      final response = await _httpClient.get(uri).timeout(_timeout);
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

  Future<dynamic> _post(String endpoint,
      {required Map<String, dynamic> body}) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    try {
      final response = await _httpClient
          .post(uri, headers: _jsonHeaders, body: json.encode(body))
          .timeout(_timeout);
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

  // ------------------ Firebase REST API Signup ------------------

  /// Sign up user using Firebase REST API with email and password
  Future<Map<String, dynamic>> firebaseSignUp({
    required String email,
    required String password,
  }) async {
    if (firebaseApiKey == null || firebaseApiKey!.isEmpty) {
      throw ApiException('Firebase API key is not set in environment variables.');
    }

    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$firebaseApiKey',
    );

    final body = {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    };

    try {
      final response = await _httpClient
          .post(url, headers: _jsonHeaders, body: json.encode(body))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        throw ApiException(
          'Firebase sign-up failed: $errorMessage',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } on SocketException {
      throw NetworkException('Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    }
  }

  // ------------------ Auth & Security ------------------

  Future<bool> verifyRecaptchaToken(String token) async {
    final response =
        await _post('api/v1/recaptcha/verify', body: {'token': token});
    return response['success'] == true;
  }

  Future<Map<String, dynamic>> getPowChallenge() async {
    final data = await _get('immune/pow_challenge');
    return data as Map<String, dynamic>;
  }

  Future<bool> verifyPow({
    required String challenge,
    required String nonce,
  }) async {
    final response = await _post('immune/verify_pow',
        body: {'challenge': challenge, 'nonce': nonce});
    return response['success'] == true;
  }

  // ------------------ Sign-up & User ------------------

  Future<bool> checkUsernameAvailability(String username) async {
    final endpoint =
        'api/v1/users/username-check/${Uri.encodeComponent(username)}';
    final uri = Uri.parse('$baseUrl/$endpoint');
    try {
      final response = await _httpClient.get(uri).timeout(_timeout);
      final data = _handleResponse(response);
      return data['available'] == true;
    } on SocketException {
      throw NetworkException('Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    } catch (e) {
      if (kDebugMode) {
        print('Error checking username availability: $e');
      }
      rethrow;
    }
  }

  /// Create user account on backend.
  /// If recaptchaToken is provided, sends it as 'recaptcha_token' field.
  Future<void> createUserAccount({
    required String firebaseUid,
    required String email,
    String? username,
    String? recaptchaToken,
  }) async {
    final body = {
      'firebase_uid': firebaseUid,
      'email': email,
      if (username != null) 'username': username,
      if (recaptchaToken != null) 'recaptcha_token': recaptchaToken,
    };
    await _post('api/v1/users', body: body);
  }

  Future<UserAccount> getUserById(String userId) async {
    final data = await _get('api/v1/users/$userId');
    return UserAccount.fromJson(data);
  }

  // ------------------ Wallet ------------------

  Future<void> createUserWallet({
    required String username,
    required String publicKey,
    required String encryptedPrivateKey,
  }) =>
      _post('api/v1/users/register-wallet', body: {
        'username': username,
        'public_key': publicKey,
        'encrypted_private_key': encryptedPrivateKey,
      });

  // ------------------ Goodwill ------------------

  Future<List<GoodwillAction>> getUserGoodwillActions(String userId) async {
    final List<dynamic> data =
        await _get('api/v1/users/$userId/goodwill-actions');
    return data.map((item) => GoodwillAction.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> submitGoodwill(
      GoodwillActionToSend actionToSend) async {
    return await _post('metabolic/submit_goodwill',
        body: actionToSend.toJson()) as Map<String, dynamic>;
  }

  // ------------------ Governance ------------------

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

  Future<Map<String, dynamic>> createProposal(
      ProposalToSend proposalToSend) async {
    return await _post('api/v1/governance/proposals',
        body: proposalToSend.toJson()) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitVote(VoteToSend voteToSend) async {
    return await _post(
        'api/v1/governance/proposals/${voteToSend.proposalId}/vote',
        body: voteToSend.toJson()) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getVotingResults(String proposalId) async {
    final data = await _get('api/v1/governance/proposals/$proposalId/results');
    return {
      'forVotes': data['forVotes'],
      'againstVotes': data['againstVotes']
    };
  }

  // ------------------ Ledger ------------------

  Future<List<PublicLedgerEntry>> getLedgerEntries({int page = 1}) async {
    final List<dynamic> data =
        await _get('api/v1/ledger/public?page=$page');
    return data.map((item) => PublicLedgerEntry.fromJson(item)).toList();
  }

  Future<List<PublicLedgerEntry>> searchLedger(
      {required String query}) async {
    final endpoint =
        'api/v1/ledger/search?q=${Uri.encodeComponent(query)}';
    final List<dynamic> data = await _get(endpoint);
    return data.map((item) => PublicLedgerEntry.fromJson(item)).toList();
  }

  // ------------------ Transactions ------------------

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

  // ------------------ Metabolic ------------------

  Future<String> checkMetabolicStatus() async {
    final uri = Uri.parse('$baseUrl/metabolic/status');
    try {
      final response = await _httpClient.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw ApiException('Failed to check metabolic status',
            statusCode: response.statusCode);
      }
    } on SocketException {
      throw NetworkException('Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException('The request timed out. Please try again.');
    }
  }
}

