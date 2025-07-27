import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode

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

  PeoplesCoinApiClient({String? baseUrl})
      : baseUrl = baseUrl ?? dotenv.env['API_URL'] ?? 'https://peoples-coin-service-105378934751.us-central1.run.app';

  // === User ===
  Future<UserAccount> getUserById(String userId) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return UserAccount.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch user account. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserById: $e');
      }
      rethrow; // Re-throw to allow higher-level error handling
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/username-check/$username');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['available'] == true;
      }
      throw Exception('Failed to check username availability. Status: ${response.statusCode}, Body: ${response.body}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkUsernameAvailability: $e');
      }
      rethrow;
    }
  }

  // --- THIS FUNCTION IS CORRECTED ---
  Future<void> createUserWallet({
    required String username,
    required String publicKey,
    required String encryptedPrivateKey,
    // The 'recaptchaToken' parameter has been removed.
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/register-wallet');
    final body = json.encode({
      'username': username,
      'public_key': publicKey,
      'encrypted_private_key': encryptedPrivateKey,
      // The 'recaptcha_token' field has been removed from the body.
    });

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create user wallet. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in createUserWallet: $e');
      }
      rethrow;
    }
  }

  // === GoodwillActions ===
  Future<List<GoodwillAction>> getUserGoodwillActions(String userId) async {
    final uri = Uri.parse('$baseUrl/api/v1/users/$userId/goodwill-actions');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => GoodwillAction.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch goodwill actions. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserGoodwillActions: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitGoodwill(GoodwillActionToSend actionToSend) async {
    final uri = Uri.parse('$baseUrl/metabolic/submit_goodwill');
    try {
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
    } catch (e) {
      if (kDebugMode) {
        print('Error in submitGoodwill: $e');
      }
      rethrow;
    }
  }

  // === Proposals ===
  Future<List<Proposal>> listProposals({String? status}) async {
    var url = '$baseUrl/api/v1/governance/proposals';
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }
    final uri = Uri.parse(url);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Proposal.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch proposals. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in listProposals: $e');
      }
      rethrow;
    }
  }

  Future<Proposal> getProposalDetails(String proposalId) async {
    final uri = Uri.parse('$baseUrl/api/v1/governance/proposals/$proposalId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return Proposal.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch proposal details. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getProposalDetails: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createProposal(ProposalToSend proposalToSend) async {
    final uri = Uri.parse('$baseUrl/api/v1/governance/proposals');
    try {
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
    } catch (e) {
      if (kDebugMode) {
        print('Error in createProposal: $e');
      }
      rethrow;
    }
  }

  // === Votes ===
  Future<Map<String, dynamic>> submitVote(VoteToSend voteToSend) async {
    final uri = Uri.parse('$baseUrl/api/v1/governance/proposals/${voteToSend.proposalId}/vote');
    try {
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
    } catch (e) {
      if (kDebugMode) {
        print('Error in submitVote: $e');
      }
      rethrow;
    }
  }

  // === Ledger ===
  Future<List<PublicLedgerEntry>> getLedgerEntries() async {
    final uri = Uri.parse('$baseUrl/api/v1/ledger/public');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => PublicLedgerEntry.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch public ledger. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getLedgerEntries: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendLoves({
    required String senderWalletId,
    required String recipientWalletId,
    required int amount,
    String? memo,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/transactions/send');
    final body = json.encode({
      'sender_id': senderWalletId,
      'recipient_id': recipientWalletId,
      'amount': amount,
      if (memo != null && memo.isNotEmpty) 'memo': memo,
    });

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to send loves. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in sendLoves: $e');
      }
      rethrow;
    }
  }

  // === Metabolic status check ===
  Future<String> checkMetabolicStatus() async {
    final uri = Uri.parse('$baseUrl/metabolic/status');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to check metabolic status. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkMetabolicStatus: $e');
      }
      rethrow;
    }
  }
}

