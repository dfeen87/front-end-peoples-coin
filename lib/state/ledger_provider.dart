import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/public_ledger_entry.dart';
import '../services/api_client.dart';

class LedgerProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;
  String? _currentSearchQuery;
  int _currentPage = 1;
  bool _hasMorePages = true;
  
  // --- State for Public Ledger Entries (with Pagination) ---
  List<PublicLedgerEntry> _publicLedgerEntries = [];
  bool _isInitialLoading = false;
  bool _isFetchingMore = false;
  String? _errorMessage;
  
  // --- Getters for Public Ledger Entries ---
  List<PublicLedgerEntry> get publicLedgerEntries => _publicLedgerEntries;
  bool get isInitialLoading => _isInitialLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get errorMessage => _errorMessage;

  // Constructor
  LedgerProvider(this._apiClient);

  /// Fetches public ledger entries with support for pagination and refreshing.
  Future<void> fetchPublicLedgerEntries({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _publicLedgerEntries = [];
      _hasMorePages = true;
    } else if (!_hasMorePages) {
      return;
    }
    
    if (_isInitialLoading || _isFetchingMore) return;
    
    if (isRefresh) {
      _isInitialLoading = true;
    } else {
      _isFetchingMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final newEntries = _currentSearchQuery == null || _currentSearchQuery!.isEmpty
          ? await _apiClient.getLedgerEntries(page: _currentPage)
          : await _apiClient.searchLedger(query: _currentSearchQuery!);
      
      if (newEntries.isEmpty) {
        _hasMorePages = false;
      }
      
      if (isRefresh) {
        _publicLedgerEntries = newEntries;
      } else {
        _publicLedgerEntries.addAll(newEntries);
      }
      
      if (_hasMorePages) {
        _currentPage++;
      }

    } catch (e) {
      _errorMessage = 'Failed to fetch ledger entries: $e';
      if (kDebugMode) {
        print('Error fetching ledger entries: $e');
      }
    } finally {
      _isInitialLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }
  
  /// Searches the public ledger and refreshes the list.
  Future<void> search(String query) async {
    _currentSearchQuery = query.isEmpty ? null : query;
    await fetchPublicLedgerEntries(isRefresh: true);
  }

  /// Sends loves via the API and refreshes the public ledger.
  Future<void> sendLoves({
    required String senderWalletId,
    required String recipientWalletId,
    required int amount,
    String? memo,
  }) async {
    bool tempIsSending = true; // Use a temporary flag to manage this action's state
    notifyListeners();

    try {
      await _apiClient.sendLoves(
        senderWalletId: senderWalletId,
        recipientWalletId: recipientWalletId,
        amount: amount,
        memo: memo,
      );

      // After a successful send, refresh the ledger entries to reflect the change.
      await fetchPublicLedgerEntries(isRefresh: true);
    } catch (e) {
      _errorMessage = 'Failed to send loves: $e';
      if (kDebugMode) {
        print('Error sending loves: $e');
      }
      notifyListeners();
    } finally {
      tempIsSending = false;
    }
  }
}
