// lib/providers/ledger_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/public_ledger_entry.dart';
import '../models/ledger_entry.dart'; // Add this import
import '../service/api_client.dart';

// --- State ---
class LedgerState {
  final List<PublicLedgerEntry> entries;
  final bool isInitialLoading;
  final bool isFetchingMore;
  final bool isSendingLoves;
  final String? errorMessage;
  final String? currentSearchQuery;

  const LedgerState({
    this.entries = const [],
    this.isInitialLoading = false,
    this.isFetchingMore = false,
    this.isSendingLoves = false,
    this.errorMessage,
    this.currentSearchQuery,
  });

  LedgerState copyWith({
    List<PublicLedgerEntry>? entries,
    bool? isInitialLoading,
    bool? isFetchingMore,
    bool? isSendingLoves,
    String? errorMessage,
    String? currentSearchQuery,
  }) {
    return LedgerState(
      entries: entries ?? this.entries,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      isSendingLoves: isSendingLoves ?? this.isSendingLoves,
      errorMessage: errorMessage,
      currentSearchQuery: currentSearchQuery ?? this.currentSearchQuery,
    );
  }

  factory LedgerState.initial() => const LedgerState();
}

// --- Notifier ---
class LedgerNotifier extends StateNotifier<LedgerState> {
  final PeoplesCoinApiClient _apiClient;

  LedgerNotifier(this._apiClient) : super(LedgerState.initial());

  /// Fetch ledger entries (with optional refresh)
  Future<void> fetchPublicLedgerEntries({
    bool isRefresh = false,
    required String idToken, // Add required idToken
  }) async {
    if (state.isInitialLoading || state.isFetchingMore) return;

    state = state.copyWith(
      errorMessage: null,
      isInitialLoading: isRefresh,
      isFetchingMore: !isRefresh,
      entries: isRefresh ? [] : state.entries,
    );

    try {
      List<LedgerEntry> apiEntries;
      
      if (state.currentSearchQuery != null && state.currentSearchQuery!.isNotEmpty) {
        // Use search API when there's a query
        apiEntries = await _apiClient.searchLedger(
          idToken: idToken,
          query: state.currentSearchQuery!,
        );
      } else {
        // Use regular fetch API
        apiEntries = await _apiClient.getLedgerEntries(idToken: idToken);
      }
      
      // Convert LedgerEntry to PublicLedgerEntry if needed
      final newEntries = apiEntries.map((entry) => _convertToPublicLedgerEntry(entry)).toList();
      
      state = state.copyWith(
        entries: isRefresh ? newEntries : [...state.entries, ...newEntries],
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to fetch ledger entries: $e');
    } finally {
      state = state.copyWith(isInitialLoading: false, isFetchingMore: false);
    }
  }

  /// Convert LedgerEntry to PublicLedgerEntry
  PublicLedgerEntry _convertToPublicLedgerEntry(LedgerEntry entry) {
    // You'll need to adjust this based on your actual model structures
    return PublicLedgerEntry(
      id: entry.id,
      // Map other fields as needed based on your models
      // This is a placeholder - adjust according to your actual PublicLedgerEntry structure
    );
  }

  /// Set search query and refresh ledger
  Future<void> search(String? query, {required String idToken}) async {
    final cleanedQuery = (query ?? '').trim();
    state = state.copyWith(
      currentSearchQuery: cleanedQuery.isEmpty ? null : cleanedQuery
    );
    await fetchPublicLedgerEntries(isRefresh: true, idToken: idToken);
  }

  /// Send loves and refresh ledger
  Future<void> sendLoves({
    required String recipientId, // Changed to match API client
    required int amount,
    required String idToken, // Add required idToken
    String? message, // Changed from memo to message to match API client
  }) async {
    state = state.copyWith(isSendingLoves: true, errorMessage: null);

    try {
      // Use the correct API method signature
      await _apiClient.sendLoves(
        idToken: idToken,
        recipientId: recipientId,
        amount: amount, // Remove the ! since amount is already non-nullable
        message: message,
      );
      
      // Refresh the ledger after sending
      await fetchPublicLedgerEntries(isRefresh: true, idToken: idToken);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to send loves: $e');
    } finally {
      state = state.copyWith(isSendingLoves: false);
    }
  }

  /// Send funds between wallets
  Future<void> sendFunds({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required String idToken,
  }) async {
    state = state.copyWith(isSendingLoves: true, errorMessage: null); // Reuse loading state

    try {
      await _apiClient.sendFunds(
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        idToken: idToken,
      );
      
      // Refresh the ledger after sending
      await fetchPublicLedgerEntries(isRefresh: true, idToken: idToken);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to send funds: $e');
    } finally {
      state = state.copyWith(isSendingLoves: false);
    }
  }
}

// --- Provider ---
final ledgerProviderNotifier =
    StateNotifierProvider<LedgerNotifier, LedgerState>((ref) {
  final apiClient = ref.watch(apiClientProvider); // Use the provider instead of creating new instance
  return LedgerNotifier(apiClient);
});
