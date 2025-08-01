import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/public_ledger_entry.dart';
import '../services/api_client.dart';

class LedgerProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;
  String? _currentSearchQuery;
  
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
    // Only fetch if not already loading or fetching more
    if (_isInitialLoading || _isFetchingMore) return;
    
    // Set loading states
    if (isRefresh) {
      _isInitialLoading = true;
      _publicLedgerEntries = [];
    } else {
      _isFetchingMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final lastId = _publicLedgerEntries.isNotEmpty ? _publicLedgerEntries.last.id : null;
      
      final newEntries = await _apiClient.getLedgerEntries(
        lastId: lastId,
        query: _currentSearchQuery,
      );
      
      if (isRefresh) {
        _publicLedgerEntries = newEntries;
      } else {
        _publicLedgerEntries.addAll(newEntries);
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
    // This is a simplified loading state for this specific action.
    // You may want to add a dedicated `_isSendingLoves` state.
    bool tempIsSending = true;
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
      // No need to notifyListeners() here if fetchPublicLedgerEntries already does.
    }
  }
}
