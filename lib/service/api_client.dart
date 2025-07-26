import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/user_account.dart';
import '../models/goodwill_action.dart';
import '../models/goodwill_action_to_send.dart';
import '../models/proposal.dart';
import '../models/proposal_to_send.dart';
import '../models/vote.dart';
import '../models/vote_to_send.dart';
import '../models/public_ledger_entry.dart';

class PeoplesCoinApiClient {
  final String baseUrl;

  PeoplesCoinApiClient()
      : baseUrl = dotenv.env['API_URL'] ?? 'https://peoples-coin-service-105378934751.us-central1.run.app';

  // === User ===
  Future<UserAccount> getUserById(String userId) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/$userId');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return UserAccount.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch user account. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/username-check/$username');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['available'] == true;
    }
    throw Exception('Failed to check username availability. Status: ${response.statusCode}');
  }

  Future<void> createUserWallet({
    required String username,
    required String publicKey,
    required String encryptedPrivateKey,
    required String recaptchaToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/register-wallet');
    final body = json.encode({
      'username': username,
      'public_key': publicKey,
      'encrypted_private_key': encryptedPrivateKey,
      'recaptcha_token': recaptchaToken,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create user wallet. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // === GoodwillActions ===
  Future<List<GoodwillAction>> getUserGoodwillActions(String userId) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/$userId/goodwill-actions');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => GoodwillAction.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch goodwill actions. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> submitGoodwill(GoodwillActionToSend actionToSend) async {
    final uri = Uri.parse('$baseUrl/metabolic/submit_goodwill'); // Note: This path is different from the others
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(actionToSend.toJson()),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit goodwill. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // === Proposals ===
  Future<List<Proposal>> listProposals({String? status}) async {
    var url = '$baseUrl/api/v1/governance/proposals';
    if (status != null) {
      url += '?status=$status';
    }
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Proposal.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch proposals. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Proposal> getProposalDetails(String proposalId) async {
    final uri = Uri.parse('$baseUrl/api/v1/governance/proposals/$proposalId');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return Proposal.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch proposal details. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createProposal(ProposalToSend proposalToSend) async {
    final uri = Uri.parse('$baseUrl/api/v1/governance/proposals');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(proposalToSend.toJson()),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create proposal. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // === Votes ===
  Future<Map<String, dynamic>> submitVote(VoteToSend voteToSend) async {
    final uri = Uri.parse('$baseUrl/api/v1/governance/proposals/${voteToSend.proposalId}/vote');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(voteToSend.toJson()),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit vote. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // === Ledger ===
  Future<List<PublicLedgerEntry>> getPublicLedger() async {
    final uri = Uri.parse('$baseUrl/api/v1/ledger/public');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => PublicLedgerEntry.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch public ledger. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // === Metabolic status check example ===
  Future<String> checkMetabolicStatus() async {
    final uri = Uri.parse('$baseUrl/metabolic/status'); // Note: This path is different
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to check metabolic status. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
