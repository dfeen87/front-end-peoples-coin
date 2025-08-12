import 'package:flutter/foundation.dart';
import '../models/public_ledger_entry.dart';
import '../service/api_client.dart';

class LedgerProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;
  String? _currentSearchQuery;

  // --- State for Public Ledger Entries (with Pagination) ---
  List<PublicLedgerEntry> _publicLedgerEntries = [];
  bool _isInitialLoading = false;
  bool _isFetchingMore = false;
  String? _errorMessage;

  // --- State for sending loves ---
  bool _isSendingLoves = false;

  // --- Getters ---
  List<PublicLedgerEntry> get publicLedgerEntries => _publicLedgerEntries;
  bool get isInitialLoading => _isInitialLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get errorMessage => _errorMessage;
  bool get isSendingLoves => _isSendingLoves;

  LedgerProvider(this._apiClient);

  /// Fetch public ledger entries.
  /// If [isRefresh] is true, clears existing entries and reloads from start.
  /// Otherwise, fetches next page based on last entry ID.
  Future<void> fetchPublicLedgerEntries({bool isRefresh = false}) async {
    // Prevent overlapping fetches
    if (_isInitialLoading || _isFetchingMore) return;

    _errorMessage = null;

    if (isRefresh) {
      _isInitialLoading = true;
      _publicLedgerEntries = [];
    } else {
      _isFetchingMore = true;
    }
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

  /// Set search query and refresh ledger entries.
  Future<void> search(String? query) async {
    final cleanedQuery = (query ?? '').trim();
    _currentSearchQuery = cleanedQuery.isEmpty ? null : cleanedQuery;
    await fetchPublicLedgerEntries(isRefresh: true);
  }

  /// Send loves transaction and refresh ledger on success.
  Future<void> sendLoves({
    required String senderWalletId,
    required String recipientWalletId,
    required int amount,
    String? memo,
  }) async {
    _isSendingLoves = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.sendLoves(
        senderWalletId: senderWalletId,
        recipientWalletId: recipientWalletId,
        amount: amount,
        memo: memo,
      );

      await fetchPublicLedgerEntries(isRefresh: true);
    } catch (e) {
      _errorMessage = 'Failed to send loves: $e';
      if (kDebugMode) {
        print('Error sending loves: $e');
      }
    } finally {
      _isSendingLoves = false;
      notifyListeners();
    }
  }
}

