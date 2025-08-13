import 'dart:convert';
import 'package:your_app_name/service/api_client.dart';
import 'package:your_app_name/models/proposal.dart';
import 'package:your_app_name/models/proposal_to_send.dart';

/// A dedicated service for all proposal-related API calls.
class ProposalService {
  final PeoplesCoinApiClient _client;

  ProposalService(this._client);

  /// Fetches a list of all proposals from the backend.
  Future<List<Proposal>> listProposals({required String idToken, String? status}) async {
    final url = status == null ? 'proposals' : 'proposals?status=$status';
    final response = await _client.get(
      url,
      idToken: idToken,
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => Proposal.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to fetch proposals: ${response.statusCode} - ${response.body}');
    }
  }

  /// Fetches the details of a specific proposal.
  Future<Proposal> getProposalDetails({required String proposalId, required String idToken}) async {
    final url = 'proposals/$proposalId';
    final response = await _client.get(
      url,
      idToken: idToken,
    );

    if (response.statusCode == 200) {
      return Proposal.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        'Failed to fetch proposal details: ${response.statusCode} - ${response.body}');
    }
  }

  /// Creates a new proposal.
  Future<Map<String, dynamic>> createProposal({
    required ProposalToSend proposal,
    required String idToken,
  }) async {
    final url = 'proposals';
    final body = json.encode(proposal.toJson());
    final response = await _client.post(
      url,
      body,
      idToken: idToken,
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to create proposal: ${response.statusCode} - ${response.body}');
    }
  }
}

