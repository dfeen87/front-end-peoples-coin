import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/public_ledger_entry.dart';
import '../service/api_client.dart';

class LedgerProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;
  String? _currentSearchQuery;
  int _currentPage = 1;
  bool _hasMorePages = true;

  List<PublicLedgerEntry> _publicLedgerEntries = [];
  bool _isInitialLoading = false;
  bool _isFetchingMore = false;
  String? _errorMessage;

  Timer? _pollingTimer;

  // --- Getters ---
  List<PublicLedgerEntry> get publicLedgerEntries => _publicLedgerEntries;
  bool get isInitialLoading => _isInitialLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get errorMessage => _errorMessage;

  LedgerProvider(this._apiClient) {
    // Load ledger on creation
    fetchPublicLedgerEntries(isRefresh: true);

    // Start polling backend for goodwill status changes
    _startPollingGoodwillStatus();
  }

  /// Helper to get ID token for secure API calls
  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not signed in.');
    final token = await user.getIdToken();
    if (token.isEmpty) throw Exception('Failed to get Firebase ID token.');
    return token;
  }

  /// Fetch ledger entries with optional refresh and pagination
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
      final token = await _getIdToken();

      final List<dynamic> rawEntries = (_currentSearchQuery == null || _currentSearchQuery!.isEmpty)
          ? await _apiClient.getLedgerEntries(page: _currentPage, idToken: token)
          : await _apiClient.searchLedger(query: _currentSearchQuery!, idToken: token);

      final newEntries = rawEntries.map((json) => PublicLedgerEntry.fromJson(json)).toList();

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
      if (kDebugMode) print('Error fetching ledger entries: $e');
    } finally {
      _isInitialLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  /// Search the public ledger
  Future<void> search(String query) async {
    _currentSearchQuery = query.isEmpty ? null : query;
    await fetchPublicLedgerEntries(isRefresh: true);
  }

  /// Send loves and refresh ledger
  Future<void> sendLoves({
    required String senderWallet,
    required String recipientWallet,
    required int amount,
    String? memo,
  }) async {
    try {
      final token = await _getIdToken();

      await _apiClient.sendLoves(
        sendLovesData: {
          'senderWalletId': senderWallet,
          'recipientWalletId': recipientWallet,
          'amount': amount,
          'memo': memo,
        },
        idToken: token,
      );

      await fetchPublicLedgerEntries(isRefresh: true);
    } catch (e) {
      _errorMessage = 'Failed to send loves: $e';
      if (kDebugMode) print('Error sending loves: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Poll backend every 30 seconds to check for goodwill status updates
  void _startPollingGoodwillStatus() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final token = await _getIdToken();

        // Implement your API call to check if any goodwill actions changed status
        // For example, you could fetch latest goodwill actions or a dedicated endpoint
        // Here, just fetch ledger entries as a simple proxy to detect changes:
        final entries = await _apiClient.getLedgerEntries(page: 1, idToken: token);

        if (entries.isNotEmpty) {
          if (kDebugMode) {
            print('Polling: Goodwill status may have changed, refreshing ledger...');
          }
          await fetchPublicLedgerEntries(isRefresh: true);
        }
      } catch (e) {
        if (kDebugMode) print('Polling error: $e');
      }
    });
  }

  /// Clean up timer when provider disposed
  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

