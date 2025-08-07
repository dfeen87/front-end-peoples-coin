// lib/service/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/user_account.dart';
import '../models/goodwill_action.dart';
import '../models/proposal.dart';
import '../models/proposal_to_send.dart';
import '../models/vote_to_send.dart';
import '../models/ledger_entry.dart';

class PeoplesCoinApiClient {
  final String _baseUrl = dotenv.env['API_BASE_URL']?.trim() ?? '';

  PeoplesCoinApiClient() {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL is not set in environment variables');
    }
  }

  Map<String, String> _headers(String idToken) {
    if (idToken.isEmpty) {
      throw Exception('Missing ID token for authentication.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
  }

  // === USER PROFILE ===
  Future<UserAccount> getAuthenticatedUserProfile(idToken: {required String idToken}) async {
    final url = Uri.parse('$_baseUrl/users/profile');
    final response = await http.get(url, headers: _headers(idToken));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return UserAccount.fromJson(json);
    } else {
      throw Exception('Failed to fetch user profile: ${response.statusCode} - ${response.body}');
    }
  }

  // User creation (no auth)
  Future<void> createUser({
    required String username,
    required String publicKey,
    required String encryptedPrivateKey,
    String? recaptchaToken,
  }) async {
    final url = Uri.parse('$_baseUrl/users');
    final headers = {'Content-Type': 'application/json'};
    final body = {
      'username': username,
      'public_key': publicKey,
      'encrypted_private_key': encryptedPrivateKey,
      if (recaptchaToken != null) 'recaptcha_token': recaptchaToken,
    };

    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode != 201) {
      throw Exception('Failed to create user: ${response.statusCode} - ${response.body}');
    }
  }

  // User creation + wallet combined (used during signup)
  Future<Map<String, dynamic>> createUserAndWallet({required Map<String, dynamic> userData}) async {
    final url = Uri.parse('$_baseUrl/users/create-user-wallet');
    final headers = {'Content-Type': 'application/json'};
    final response = await http.post(url, headers: headers, body: jsonEncode(userData));

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create user and wallet: ${response.statusCode} - ${response.body}');
    }
  }

  // === GOODWILL ACTIONS ===
  Future<Map<String, dynamic>> submitGoodwill({
    required Map<String, dynamic> goodwillAction,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/goodwill');
    final response = await http.post(url, headers: _headers(idToken), body: jsonEncode(goodwillAction));

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit goodwill action: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<GoodwillAction>> getUserGoodwillActions(userId: {
    required String userId, idToken: required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/goodwill/user/$userId');
    final response = await http.get(url, headers: _headers(idToken));

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => GoodwillAction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch goodwill actions: ${response.statusCode} - ${response.body}');
    }
  }

  // === PROPOSALS ===
  Future<List<Proposal>> listProposals(status: {
    String? status,
    required String idToken,
  }, idToken: idToken) async {
    final urlStr = status == null ? '$_baseUrl/proposals' : '$_baseUrl/proposals?status=$status';
    final url = Uri.parse(urlStr);

    final response = await http.get(url, headers: _headers(idToken));
    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => Proposal.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch proposals: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Proposal> getProposalDetails(proposalId: {
    required String proposalId,
    required String idToken,
  }, idToken: idToken) async {
    final url = Uri.parse('$_baseUrl/proposals/$proposalId');
    final response = await http.get(url, headers: _headers(idToken));
    if (response.statusCode == 200) {
      return Proposal.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch proposal details: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createProposal(proposal: {
    required ProposalToSend proposal, idToken: required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/proposals');
    final response = await http.post(url, headers: _headers(idToken), body: jsonEncode(proposal.toJson()));

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create proposal: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> submitVote(vote: {
    required VoteToSend vote, idToken: required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/votes');
    final response = await http.post(url, headers: _headers(idToken), body: jsonEncode(vote.toJson()));

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit vote: ${response.statusCode} - ${response.body}');
    }
  }

  // === LOVES ===
  Future<Map<String, dynamic>> sendLoves({
    required Map<String, dynamic> sendLovesData,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/loves/send');
    final response = await http.post(url, headers: _headers(idToken), body: jsonEncode(sendLovesData));

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send loves: ${response.statusCode} - ${response.body}');
    }
  }

  // === LEDGER ===
  Future<List<LedgerEntry>> getLedgerEntries({
    int page = 1,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/ledger?page=$page');
    final response = await http.get(url, headers: _headers(idToken));

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => LedgerEntry.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch ledger entries: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<LedgerEntry>> searchLedger({
    required String query,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/ledger/search?query=$query');
    final response = await http.get(url, headers: _headers(idToken));

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => LedgerEntry.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search ledger: ${response.statusCode} - ${response.body}');
    }
  }

  // === USER ACTIONS ===
  Future<List<Map<String, dynamic>>> fetchUserActions({
    required String userId,
    required String idToken,
  }) async {
    final url = Uri.parse('$_baseUrl/actions/user/$userId');
    final response = await http.get(url, headers: _headers(idToken));

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception('Failed to fetch user actions: ${response.statusCode} - ${response.body}');
    }
  }

  // === USERNAME AVAILABILITY (public) ===
  Future<bool> checkUsernameAvailability(String username) async {
    final url = Uri.parse('$_baseUrl/users/check-username/$username');
    final headers = {'Content-Type': 'application/json'};
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'] == true;
    }
    throw Exception('Failed to check username availability: ${response.statusCode} - ${response.body}');
  }
}

