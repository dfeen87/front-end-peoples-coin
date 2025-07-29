// lib/state/ledger_provider.dart

import 'package:flutter/foundation.dart';
import 'dart:collection'; // Required for UnmodifiableListView

import '../models/public_ledger_entry.dart';
import '../service/api_client.dart';

class LedgerProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  // --- PRIVATE STATE ---
  List<PublicLedgerEntry> _publicLedgerEntries = [];
  String? _errorMessage;

  // --- PAGINATION STATE ---
  int _currentPage = 1;
  bool _hasMore = true;
  // Separate loading states for initial load vs. fetching more
  bool _isInitialLoading = false;
  bool _isFetchingMore = false;

  // --- ACTION-SPECIFIC STATE ---
  bool _isSendingLoves = false;


  // --- PUBLIC GETTERS ---
  UnmodifiableListView<PublicLedgerEntry> get publicLedgerEntries => UnmodifiableListView(_publicLedgerEntries);
  String? get errorMessage => _errorMessage;

  // Renamed for clarity in the UI
  bool get isInitialLoading => _isInitialLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get isSendingLoves => _isSendingLoves;


  LedgerProvider(this._apiClient);


  /// --- ENHANCED: Now supports pagination and refresh ---
  /// Fetches ledger entries page by page.
  Future<void> fetchPublicLedgerEntries({bool isRefresh = false}) async {
    // On refresh, reset state completely
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _publicLedgerEntries = [];
    }

    // Prevent duplicate calls if we're already fetching or there's no more data
    if (_isFetchingMore || !_hasMore) return;

    // Set appropriate loading states
    if (isRefresh || _publicLedgerEntries.isEmpty) {
      _isInitialLoading = true;
    } else {
      _isFetchingMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      // Assumes your API client is updated to take a 'page' parameter
      final newEntries = await _apiClient.getLedgerEntries(page: _currentPage);

      if (newEntries.isNotEmpty) {
        _publicLedgerEntries.addAll(newEntries);
        _currentPage++;
      } else {
        // If the API returns an empty list, we've reached the end
        _hasMore = false;
      }
    } catch (e) {
      _errorMessage = "Failed to fetch public ledger: $e";
      if (kDebugMode) print('[LedgerProvider] Error fetching public ledger: $e');
    } finally {
      _isInitialLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  /// --- ENHANCED: Now handles its own loading state and avoids a full list refresh ---
  /// This prevents the user's scroll position from being reset after sending Loves.
  Future<bool> sendLoves({
    required String senderWalletId,
    required String recipientWalletId,
    required int amount,
    String? memo,
  }) async {
    if (amount <= 0) {
      _errorMessage = "Amount must be greater than zero.";
      notifyListeners();
      return false;
    }

    _isSendingLoves = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.sendLoves(
        senderWalletId: senderWalletId,
        recipientWalletId: recipientWalletId,
        amount: amount,
        memo: memo,
      );

      if (response['success'] == true) {
        // Don't auto-refresh the whole list. The UI can show a success message,
        // and the user can pull-to-refresh to see the new transaction at the top.
        // This provides a much better UX in an infinitely-scrolled list.
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to send loves.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Unexpected error sending loves: $e';
      return false;
    } finally {
      _isSendingLoves = false;
      notifyListeners();
    }
  }

  /// --- NEW: Method for handling search ---
  /// This replaces the current list with search results.
  Future<void> searchEntries(String query) async {
    // If the query is empty, just refresh the main list.
    if (query.trim().isEmpty) {
      await fetchPublicLedgerEntries(isRefresh: true);
      return;
    }

    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Assumes your API client has a method for searching
      _publicLedgerEntries = await _apiClient.searchLedger(query: query);
    } catch (e) {
      _errorMessage = "Search failed: $e";
    } finally {
      _isInitialLoading = false;
      // In search mode, we aren't paginating, so these are false.
      _isFetchingMore = false;
      _hasMore = false;
      notifyListeners();
    }
  }

  /// Clears current error state
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
