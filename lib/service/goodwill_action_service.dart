import 'dart:convert';
import 'package:your_app_name/service/api_client.dart';
import 'package:your_app_name/models/goodwill_action.dart';
import 'package:your_app_name/models/goodwill_action_to_send.dart';

/// A dedicated service for all goodwill action-related API calls.
class GoodwillActionService {
  final PeoplesCoinApiClient _client;

  GoodwillActionService(this._client);

  /// Submits a new goodwill action to the backend.
  Future<Map<String, dynamic>> submitGoodwill({
    required GoodwillActionToSend goodwillAction,
    required String idToken,
  }) async {
    final url = 'goodwill';
    final body = json.encode(goodwillAction.toJson());
    final response = await _client.post(
      url,
      body,
      idToken: idToken,
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to submit goodwill action: ${response.statusCode} - ${response.body}');
    }
  }

  /// Fetches a list of goodwill actions for a specific user.
  Future<List<GoodwillAction>> getUserGoodwillActions({
    required String userId,
    required String idToken,
  }) async {
    final url = 'goodwill/user/$userId';
    final response = await _client.get(
      url,
      idToken: idToken,
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => GoodwillAction.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to fetch goodwill actions: ${response.statusCode} - ${response.body}');
    }
  }

  /// Fetches the status of a specific goodwill action.
  Future<String> getGoodwillStatus(String actionId, String idToken) async {
    final url = 'goodwill/status/$actionId';
    final response = await _client.get(
      url,
      idToken: idToken,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] ?? 'UNKNOWN';
    } else {
      throw Exception(
        'Failed to fetch goodwill status: ${response.statusCode} - ${response.body}');
    }
  }
}

