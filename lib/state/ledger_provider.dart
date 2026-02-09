import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/public_ledger_entry.dart';
import '../service/api_client.dart';

// 1. A provider to hold the PeoplesCoinApiClient dependency.
// This is a simple provider that can be overridden for testing.
final apiClientProvider = Provider<PeoplesCoinApiClient>((ref) {
  // Replace with your actual initialization logic for the API client.
  return PeoplesCoinApiClient();
});

// 2. A StateProvider to manage the search query.
// StateProvider is great for simple, single-value state like a String.
final ledgerSearchQueryProvider = StateProvider<String>((ref) => '');

// 3. A StateNotifier that holds the core logic and state.
// We use AsyncValue to automatically handle loading, data, and error states.
// PublicLedgerNotifier will manage the list of entries, pagination, and polling.
class PublicLedgerNotifier extends StateNotifier<AsyncValue<List<PublicLedgerEntry>>> {
  final Ref ref;
  final PeoplesCoinApiClient _apiClient;
  String? _currentSearchQuery;
  int _currentPage = 1;
  bool _hasMorePages = true;
  
  Timer? _pollingTimer;

  PublicLedgerNotifier(this.ref, this._apiClient) : super(const AsyncValue.loading()) {
    // Watch for changes in the search query. This will automatically
    // trigger a rebuild of this provider, effectively running the build
    // method of the provider below and re-fetching data.
    _currentSearchQuery = ref.watch(ledgerSearchQueryProvider);
    
    // Fetch initial data
    fetchPublicLedgerEntries(isRefresh: true);
    
    // Start polling on creation
    _startPollingGoodwillStatus();
  }

  /// Helper to get ID token for secure API calls
  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not signed in.');
    }
    final token = await user.getIdToken();
    if (token?.isEmpty == true) {
      throw Exception('Failed to get Firebase ID token.');
    }
    return token!;
  }

  /// Fetch ledger entries with optional refresh and pagination
  Future<void> fetchPublicLedgerEntries({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMorePages = true;
    } else if (!_hasMorePages) {
      return;
    }

    // Set loading state only if it's an initial fetch or refresh.
    // Riverpod's AsyncValue handles this for us.
    if (isRefresh) {
      state = const AsyncValue.loading();
    }

    try {
      final token = await _getIdToken();
      final List<dynamic> rawEntries;
      
      if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
        rawEntries = await _apiClient.searchLedger(
          query: _currentSearchQuery!, 
          idToken: token,
        );
      } else {
        // Fix: Remove the page parameter - the API method doesn't expect it
        rawEntries = await _apiClient.getLedgerEntries(
          idToken: token,
        );
      }

      final newEntries = rawEntries.map((json) => PublicLedgerEntry.fromJson(json)).toList();

      if (newEntries?.isEmpty == true) {
        _hasMorePages = false;
      }
      
      final currentData = state.value ?? [];
      final updatedList = isRefresh ? newEntries : [...currentData, ...newEntries];

      state = AsyncValue.data(updatedList);

      if (_hasMorePages) {
        _currentPage++;
      }
    } catch (e, st) {
      // Riverpod's AsyncValue automatically handles errors.
      state = AsyncValue.error(e, st);
    }
  }

  /// Poll backend every 30 seconds to check for goodwill status updates
  void _startPollingGoodwillStatus() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // We don't need to check for a user or token here. We can just
      // re-fetch the data, and if the token is missing, the fetch method
      // will handle the error.
      fetchPublicLedgerEntries(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

// 4. The main provider for the public ledger.
// It uses StateNotifierProvider to expose the StateNotifier.
// The .autoDispose modifier ensures the provider is cleaned up when no
// longer used, which is great for resource management.
final publicLedgerProvider = StateNotifierProvider.autoDispose<PublicLedgerNotifier, AsyncValue<List<PublicLedgerEntry>>>(
  (ref) {
    // We pass the ref and the apiClient dependency into the notifier.
    final apiClient = ref.watch(apiClientProvider);
    return PublicLedgerNotifier(ref, apiClient);
  },
);

// 5. A separate provider for sending "Loves".
// This is a good practice to keep side-effects separate from state.
// This function will handle the API call and then invalidate the ledger
// provider to trigger a refresh.
final sendLovesProvider = Provider<Future<void> Function({
  required String senderWallet,
  required String recipientWallet,
  required int amount,
  String? memo,
})>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ({
    required String senderWallet,
    required String recipientWallet,
    required int amount,
    String? memo,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User is not signed in.');
      }
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw Exception('Missing Firebase ID token.');
      }
      
      // Fix: Remove sendLovesData parameter wrapper
      // Pass the parameters directly to match the API method signature
      await apiClient.sendLoves(
        recipientId: recipientWallet,
        amount: amount,
        message: memo,
        idToken: token,
      );
      
      // Invalidate the ledger provider to force a refresh.
      ref.invalidate(publicLedgerProvider);
    } catch (e) {
      // It's up to the UI to catch this error, as the provider
      // itself doesn't hold the state for this action.
      rethrow;
    }
  };
});
