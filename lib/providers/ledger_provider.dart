import 'package:flutter/foundation.dart';
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
      _ledgerEntries = await _apiClient.getLedgerEntries();
    } catch (e) {
      _error = 'Failed to fetch ledger entries: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

