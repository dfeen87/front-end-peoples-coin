import 'dart:convert';
import 'package:your_app_name/service/api_client.dart';
import 'package:your_app_name/models/vote_to_send.dart';

/// A dedicated service for all vote-related API calls.
class VoteService {
  final PeoplesCoinApiClient _client;

  VoteService(this._client);

  /// Submits a new vote to the backend.
  Future<Map<String, dynamic>> submitVote({required VoteToSend vote, required String idToken}) async {
    const url = 'votes';
    final body = json.encode(vote.toJson());
    final response = await _client.post(
      url,
      body,
      idToken: idToken,
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to submit vote: ${response.statusCode} - ${response.body}');
    }
  }
}

