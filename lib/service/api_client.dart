// lib/service/api_client.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_account.dart';
import '../models/wallet_models.dart';
import '../models/proposal.dart';
import '../models/goodwill_action.dart';
import '../models/goodwill_token.dart';
import '../models/ledger_entry.dart';
import '../models/proposal_to_send.dart';
import '../models/vote_to_send.dart';

/// Core API client for network operations
class PeoplesCoinApiClient {
  final String _baseUrl;
  final http.Client _client;
  static const Duration _timeoutDuration = Duration(seconds: 15);

  PeoplesCoinApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            'https://peoples-coin-service-105378934751.us-central1.run.app';

  // --- Low-level helpers ---
  Map<String, String> _headers({String? idToken}) => {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      };

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    if (queryParams == null || queryParams.isEmpty) {
      return Uri.parse('$_baseUrl/$endpoint');
    }
    final query = queryParams.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent('${e.value}')}')
        .join('&');
    return Uri.parse('$_baseUrl/$endpoint?$query');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = response.body.isNotEmpty ? json.decode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      // Normalize non-map JSON success into a map wrapper to keep callers happy.
      return {'data': decoded};
    }
    // Try to surface a meaningful error message
    String message = 'Unknown error';
    if (decoded is Map && decoded['message'] is String) {
      message = decoded['message'] as String;
    } else if (decoded is String) {
      message = decoded;
    }
    throw ApiClientException(
      message,
      statusCode: response.statusCode,
    );
  }

  // --- Generic requests ---
  Future<Map<String, dynamic>> getJson(
    String endpoint, {
    String? idToken,
    Map<String, dynamic>? queryParams,
  }) async {
    final res = await _client
        .get(_buildUri(endpoint, queryParams), headers: _headers(idToken: idToken))
        .timeout(_timeoutDuration);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint, {
    String? idToken,
    Map<String, dynamic>? body,
  }) async {
    final res = await _client
        .post(
          _buildUri(endpoint),
          headers: _headers(idToken: idToken),
          body: json.encode(body ?? {}),
        )
        .timeout(_timeoutDuration);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> putJson(
    String endpoint, {
    String? idToken,
    Map<String, dynamic>? body,
  }) async {
    final res = await _client
        .put(
          _buildUri(endpoint),
          headers: _headers(idToken: idToken),
          body: json.encode(body ?? {}),
        )
        .timeout(_timeoutDuration);
    return _handleResponse(res);
  }

  void dispose() => _client.close();

  // --- High-level API methods ---

  // User
  Future<UserAccount> getAuthenticatedUserProfile({required String idToken}) async {
    final jsonMap = await getJson('users/me', idToken: idToken);
    // If server returned {data: {...}} normalize:
    final data = (jsonMap['data'] is Map) ? jsonMap['data'] : jsonMap;
    return UserAccount.fromJson(Map<String, dynamic>.from(data));
  }

  /// Goodwill Tokens for current user
  /// Accepts either:
  ///   { "tokens": [ ... ] }
  /// or a raw list in { "data": [ ... ] }
  Future<List<GoodwillToken>> getUserGoodwillTokens({required String idToken}) async {
    final jsonMap = await getJson('users/goodwill-tokens', idToken: idToken);
    dynamic raw = jsonMap['tokens'] ?? jsonMap['data'];
    if (raw is! List) {
      // Some backends might return the array at the root (normalized to 'data' in _handleResponse)
      raw = jsonMap['data'] ?? [];
    }
    final list = (raw as List)
        .map((e) => GoodwillToken.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return list;
  }

  Future<bool> checkUsernameAvailability(String username) async {
    final jsonMap =
        await getJson('users/check-username', queryParams: {'username': username});
    if (jsonMap.containsKey('data') && jsonMap['available'] == null) {
      // Normalize {data: {...}}
      return (jsonMap['data'] as Map)['available'] == true;
    }
    return jsonMap['available'] == true;
  }

  /// Create backend user + wallet and return the created UserAccount
  Future<UserAccount> createUserAndWallet({
    required String username,
    required String recaptchaToken,
    required String idToken,
  }) async {
    final jsonMap = await postJson(
      'users/create',
      idToken: idToken,
      body: {
        'username': username,
        'recaptchaToken': recaptchaToken,
      },
    );
    final data = (jsonMap['data'] is Map) ? jsonMap['data'] : jsonMap;
    return UserAccount.fromJson(Map<String, dynamic>.from(data));
  }

  // Wallet
  Future<Map<String, dynamic>> getWalletDetails(String walletId, String idToken) async {
    return await getJson('wallets/$walletId', idToken: idToken);
  }

  Future<void> sendFunds({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required String idToken,
    String? senderWalletId, // matches your ledger_provider usage
  }) async {
    await postJson(
      'wallets/send',
      idToken: idToken,
      body: {
        'fromWalletId': fromWalletId,
        'toWalletId': toWalletId,
        'amount': amount,
        if (senderWalletId != null) 'senderWalletId': senderWalletId,
      },
    );
  }

  // Goodwill Actions
  Future<List<GoodwillAction>> getUserGoodwillActions({required String idToken}) async {
    final jsonMap = await getJson('goodwill-actions', idToken: idToken);
    final raw = (jsonMap['actions'] ?? jsonMap['data']) as List;
    return raw
        .map((e) => GoodwillAction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> submitGoodwill({
    required String idToken,
    required Map<String, dynamic> goodwillAction,
  }) async {
    return await postJson(
      'goodwill-actions',
      idToken: idToken,
      body: goodwillAction,
    );
  }

  // Loves/Currency Operations
  Future<void> sendLoves({
    required String idToken,
    required String recipientId,
    required int amount,
    String? message,
  }) async {
    await postJson(
      'loves/send',
      idToken: idToken,
      body: {
        'recipientId': recipientId,
        'amount': amount,
        if (message != null) 'message': message,
      },
    );
  }

  // Proposals
  Future<List<Proposal>> listProposals({
    String? status,
    required String idToken,
  }) async {
    final jsonMap = await getJson(
      'proposals',
      idToken: idToken,
      queryParams: status != null ? {'status': status} : null,
    );
    final raw = (jsonMap['proposals'] ?? jsonMap['data']) as List;
    return raw
        .map((e) => Proposal.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Proposal> getProposalDetails({
    required String proposalId,
    required String idToken,
  }) async {
    final jsonMap = await getJson('proposals/$proposalId', idToken: idToken);
    final data = (jsonMap['data'] is Map) ? jsonMap['data'] : jsonMap;
    return Proposal.fromJson(Map<String, dynamic>.from(data));
  }

  /// Create a proposal; returns backend response map (e.g., includes id/status)
  Future<Map<String, dynamic>> createProposal({
    required String idToken,
    required ProposalToSend proposal,
  }) async {
    return await postJson(
      'proposals',
      idToken: idToken,
      body: proposal.toJson(),
    );
  }

  /// Submit a vote; returns backend response map (ack/status)
  Future<Map<String, dynamic>> submitVote({
    required VoteToSend vote,
    required String idToken,
  }) async {
    return await postJson(
      'proposals/${vote.proposalId}/vote',
      idToken: idToken,
      body: vote.toJson(),
    );
  }

  // LEGACY: Keep old method for backward compatibility
  Future<void> submitVoteLegacy({
    required String idToken,
    required String proposalId,
    required String choice,
  }) async {
    await postJson(
      'proposals/$proposalId/vote',
      idToken: idToken,
      body: {'choice': choice},
    );
  }

  // Ledger
  Future<List<LedgerEntry>> getLedgerEntries({required String idToken}) async {
    final jsonMap = await getJson('ledger', idToken: idToken);
    final raw = (jsonMap['entries'] ?? jsonMap['data']) as List;
    return raw
        .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<LedgerEntry>> searchLedger({
    required String idToken,
    required String query,
  }) async {
    final jsonMap =
        await getJson('ledger/search', idToken: idToken, queryParams: {'q': query});
    final raw = (jsonMap['entries'] ?? jsonMap['data']) as List;
    return raw
        .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class ApiClientException implements Exception {
  final String message;
  final int? statusCode;
  ApiClientException(this.message, {this.statusCode});
  @override
  String toString() =>
      statusCode != null ? 'ApiClientException($statusCode): $message' : 'ApiClientException: $message';
}

/// Riverpod provider for global API client
final apiClientProvider = Provider<PeoplesCoinApiClient>(
  (ref) => PeoplesCoinApiClient(),
);

