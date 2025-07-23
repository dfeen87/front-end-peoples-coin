import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/goodwill_action_to_send.dart';
import '../models/proposal_to_send.dart';
import '../models/vote_to_send.dart';
import '../models/goodwill_action.dart';
import '../models/proposal.dart';
import '../models/vote.dart';
import '../models/user_account.dart';

class PeoplesCoinApiClient {
  final String _baseUrl;

  PeoplesCoinApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? "http://10.0.2.2:5000";

  /// Checks if the backend API is healthy and reachable.
  Future<bool> isApiHealthy() async {
    final uri = Uri.parse('$_baseUrl/metabolic/status');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print("API health check failed: $e");
      return false;
    }
  }

  /// Fetches user account details by user ID.
  /// Returns null if not found or error occurs.
  Future<UserAccount?> getUserById(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/$userId');
    try {
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserAccount.fromJson(data['user']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch user account: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  /// Submits a new goodwill action to the backend.
  Future<Map<String, dynamic>> submitGoodwill(GoodwillActionToSend action) async {
    final uri = Uri.parse('$_baseUrl/metabolic/submit_goodwill');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(action.toJson()),
      );
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 202) {
        return {'success': true, 'data': responseBody};
      } else {
        return {
          'success': false,
          'error': responseBody['error'] ?? 'Unknown API error',
          'details': responseBody['details'],
        };
      }
    } catch (e) {
      print("Failed to submit goodwill action: $e");
      return {'success': false, 'error': 'Could not connect to the server.'};
    }
  }

  /// Creates a new governance proposal.
  Future<Map<String, dynamic>> createProposal(ProposalToSend proposal) async {
    final uri = Uri.parse('$_baseUrl/api/v1/governance/proposals');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(proposal.toJson()),
      );
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {
          'success': false,
          'error': responseBody['error'] ?? 'Unknown API error',
          'details': responseBody['details'],
        };
      }
    } catch (e) {
      print("Failed to create proposal: $e");
      return {'success': false, 'error': 'Could not connect to the server.'};
    }
  }

  /// Submits a vote on a specific proposal.
  Future<Map<String, dynamic>> submitVote(VoteToSend vote) async {
    final uri = Uri.parse('$_baseUrl/api/v1/governance/proposals/${vote.proposalId}/vote');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(vote.toJson()),
      );
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {
          'success': false,
          'error': responseBody['error'] ?? 'Unknown API error',
          'details': responseBody['details'],
        };
      }
    } catch (e) {
      print("Failed to submit vote: $e");
      return {'success': false, 'error': 'Could not connect to the server.'};
    }
  }

  /// Fetches a list of governance proposals, optionally filtered by status.
  Future<List<Proposal>> listProposals({String? status}) async {
    final uri = Uri.parse('$_baseUrl/api/v1/governance/proposals');
    final queryParameters = <String, String>{};
    if (status != null) {
      queryParameters['status'] = status;
    }

    try {
      final response = await http.get(
        uri.replace(queryParameters: queryParameters),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> proposalList = data['proposals'];
        return proposalList.map((json) => Proposal.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load proposals');
      }
    } catch (e) {
      print("Failed to list proposals: $e");
      throw Exception('Failed to load proposals: $e');
    }
  }

  /// Fetches detailed information on a specific proposal.
  Future<Proposal?> getProposalDetails(String proposalId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/governance/proposals/$proposalId');
    try {
      final response = await http.get(uri, headers: {'Content-Type': 'application/json; charset=UTF-8'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Proposal.fromJson(data['proposal']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load proposal details');
      }
    } catch (e) {
      print("Failed to get proposal details: $e");
      throw Exception('Failed to get proposal details: $e');
    }
  }

  // NEW: Method to fetch all goodwill actions for a specific user.
  Future<List<GoodwillAction>> getUserGoodwillActions(String userId) async {
    // Assuming an endpoint like /api/v1/users/{userId}/goodwill-actions
    final uri = Uri.parse('$_baseUrl/api/v1/users/$userId/goodwill-actions');
    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        // You may need to add Authorization headers here if your endpoint is protected
        // headers: {
        //   'Content-Type': 'application/json; charset=UTF-8',
        //   'Authorization': 'Bearer YOUR_AUTH_TOKEN',
        // },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming the API returns a list of actions under a key, e.g., 'actions'
        final List<dynamic> actionList = data['actions'];
        return actionList.map((json) => GoodwillAction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load goodwill actions (HTTP ${response.statusCode})');
      }
    } catch (e) {
      print("Failed to get user goodwill actions: $e");
      throw Exception('Failed to get user goodwill actions: $e');
    }
  }
}
