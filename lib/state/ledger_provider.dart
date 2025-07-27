import 'package:flutter/foundation.dart';
import '../models/public_ledger_entry.dart';
import '../service/api_client.dart';

class LedgerProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  List<PublicLedgerEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  // Public getters
  List<PublicLedgerEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  LedgerProvider(this._apiClient);

  /// Fetches the public ledger entries from backend API
  Future<void> fetchLedgerEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _apiClient.getPublicLedger();
      if (kDebugMode) print('[LedgerProvider] Fetched ${_entries.length} ledger entries.');
    } catch (e) {
      _error = "Failed to fetch public ledger: $e";
      if (kDebugMode) print('[LedgerProvider] Error fetching ledger: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sends loves to a target wallet ID with specified amount.
  /// Returns true if successful, false otherwise.
  Future<bool> sendLoves({
    required String targetWalletId,
    required int amount,
    required String senderUserId,
  }) async {
    if (amount <= 0) {
      _error = "Amount of loves to send must be greater than zero.";
      notifyListeners();
      return false;
    }

    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.sendLoves(
        targetWalletId: targetWalletId,
        amount: amount,
        senderUserId: senderUserId,
      );

      if (response['success'] == true) {
        if (kDebugMode) {
          print('[LedgerProvider] Successfully sent $amount loves to $targetWalletId');
        }
        // Optionally refresh ledger after sending
        await fetchLedgerEntries();
        return true;
      } else {
        _error = response['error'] ?? 'Failed to send loves.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unexpected error sending loves: $e';
      if (kDebugMode) print('[LedgerProvider] Error sending loves: $e');
      notifyListeners();
      return false;
    }
  }

  /// Clears current error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

