import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Add this for ChangeNotifier
import '../models/public_ledger_entry.dart';
import '../services/api_client.dart';

class LedgerProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  List<PublicLedgerEntry> _ledgerEntries = [];
  bool _isLoading = false;
  String? _error;

  List<PublicLedgerEntry> get ledgerEntries => _ledgerEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  LedgerProvider(this._apiClient);

  Future<void> fetchLedgerEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // --- FIXED: Call the renamed method in ApiClient ---
      _ledgerEntries = await _apiClient.getLedgerEntries();
    } catch (e) {
      _error = 'Failed to fetch ledger entries: $e';
      if (kDebugMode) {
        print('Error fetching ledger entries: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendLoves({
    required String senderWalletId,
    required String recipientWalletId, // This should be recipientWalletId
    required int amount,
    String? memo,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiClient.sendLoves(
        senderWalletId: senderWalletId,
        recipientWalletId: recipientWalletId, // --- FIXED: Use recipientWalletId
        amount: amount,
        memo: memo,
      );

      // After a successful send, refresh the ledger entries to reflect the change
      await fetchLedgerEntries();
    } catch (e) {
      _error = 'Failed to send loves: $e';
      if (kDebugMode) {
        print('Error sending loves: $e');
      }
      notifyListeners();
    } finally {
      _isLoading = false;
      // notifyListeners() is already called by fetchLedgerEntries on success
      // or explicitly above if there's an error and fetch doesn't run.
    }
  }
}
