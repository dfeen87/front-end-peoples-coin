import 'dart:convert';
import 'package:your_app_name/service/api_client.dart';
import 'package:your_app_name/models/ledger_entry.dart';

/// A dedicated service for all Loves and Ledger-related API calls.
class LovesLedgerService {
  final PeoplesCoinApiClient _client;

  LovesLedgerService(this._client);

  /// Send Loves from one wallet to another.
  Future<Map<String, dynamic>> sendLoves({
    required String senderWallet,
    required String recipientWallet,
    required int amount,
    String? memo,
    required String idToken,
  }) async {
    const url = 'loves/send';
    final body = json.encode({
      'sender_wallet': senderWallet,
      'recipient_wallet': recipientWallet,
      'amount': amount,
      if (memo != null) 'memo': memo,
    });
    final response = await _client.post(
      url,
      body,
      idToken: idToken,
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to send loves: ${response.statusCode} - ${response.body}');
    }
  }

  /// Fetches a list of ledger entries.
  Future<List<LedgerEntry>> getLedgerEntries({required String idToken, int page = 1}) async {
    final url = 'ledger?page=$page';
    final response = await _client.get(
      url,
      idToken: idToken,
    );
    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => LedgerEntry.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to fetch ledger entries: ${response.statusCode} - ${response.body}');
    }
  }

  /// Searches the ledger for specific entries.
  Future<List<LedgerEntry>> searchLedger({required String query, required String idToken}) async {
    final url = 'ledger/search?query=$query';
    final response = await _client.get(
      url,
      idToken: idToken,
    );
    if (response.statusCode == 200) {
      final List<dynamic> decoded = json.decode(response.body);
      return decoded.map((json) => LedgerEntry.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to search ledger: ${response.statusCode} - ${response.body}');
    }
  }
}

