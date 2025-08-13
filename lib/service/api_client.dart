import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import all the new service classes
import 'package:your_app_name/service/goodwill_action_service.dart';
import 'package:your_app_name/service/proposal_service.dart';
import 'package:your_app_name/service/vote_service.dart';
import 'package:your_app_name/service/user_account_service.dart';
import 'package:your_app_name/service/loves_ledger_service.dart';

/// A service class responsible for all low-level API communication.
/// It handles raw network requests and timeouts, and is not tied to any state management.
class PeoplesCoinApiClient {
  final String _baseUrl;
  final http.Client _client;

  PeoplesCoinApiClient({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl = "https://peoples-coin-service-105378934751.us-central1.run.app";

  // Default timeout for all HTTP requests
  static const Duration _timeoutDuration = Duration(seconds: 15);

  /// Helper: Create auth headers with the Firebase ID token
  Map<String, String> _buildAuthHeaders(String? idToken) {
    if (idToken == null) {
      return {
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
  }

  /// Generic HTTP GET method.
  Future<http.Response> get(String url, {String? idToken}) async {
    final fullUrl = Uri.parse('$_baseUrl/$url');
    final headers = _buildAuthHeaders(idToken);
    return _client.get(fullUrl, headers: headers).timeout(_timeoutDuration);
  }

  /// Generic HTTP POST method.
  Future<http.Response> post(String url, String body, {String? idToken}) async {
    final fullUrl = Uri.parse('$_baseUrl/$url');
    final headers = _buildAuthHeaders(idToken);
    return _client.post(fullUrl, headers: headers, body: body).timeout(_timeoutDuration);
  }

  /// Generic HTTP PUT method.
  Future<http.Response> put(String url, String body, {String? idToken}) async {
    final fullUrl = Uri.parse('$_baseUrl/$url');
    final headers = _buildAuthHeaders(idToken);
    return _client.put(fullUrl, headers: headers, body: body).timeout(_timeoutDuration);
  }
}

// A Riverpod provider to make the API client available throughout the app.
final apiClientProvider = Provider<PeoplesCoinApiClient>((ref) {
  return PeoplesCoinApiClient();
});

// A Riverpod provider for the GoodwillActionService.
final goodwillActionServiceProvider = Provider<GoodwillActionService>((ref) {
  final client = ref.watch(apiClientProvider);
  return GoodwillActionService(client);
});

// A Riverpod provider for the ProposalService.
final proposalServiceProvider = Provider<ProposalService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProposalService(client);
});

// A Riverpod provider for the VoteService.
final voteServiceProvider = Provider<VoteService>((ref) {
  final client = ref.watch(apiClientProvider);
  return VoteService(client);
});

// A Riverpod provider for the UserAccountService.
final userAccountServiceProvider = Provider<UserAccountService>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserAccountService(client);
});

// A Riverpod provider for the LovesLedgerService.
final lovesLedgerServiceProvider = Provider<LovesLedgerService>((ref) {
  final client = ref.watch(apiClientProvider);
  return LovesLedgerService(client);
});

