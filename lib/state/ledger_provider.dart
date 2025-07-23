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
  
  Future<void> fetchLedgerEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // This is the live API call.
      _entries = await _apiClient.getPublicLedger();

    } catch (e) {
      _error = "Failed to fetch public ledger: $e";
    }

    _isLoading = false;
    notifyListeners();
  }
}
