// lib/state/ledger_provider.dart

import 'package:flutter/foundation.dart';
import 'dart:collection'; // Required for UnmodifiableListView

// Import your PublicLedgerEntry model (assuming it exists and is correct)
import '../models/public_ledger_entry.dart';
// Import your API client
import '../service/api_client.dart'; // Ensure this path is correct for PeoplesCoinApiClient

class LedgerProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient; // Your API client instance

  // Private fields to hold the state
  List<PublicLedgerEntry> _publicLedgerEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Public getters to access the state
  UnmodifiableListView<PublicLedgerEntry> get publicLedgerEntries => UnmodifiableListView(_publicLedgerEntries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor to inject the API client dependency
  LedgerProvider(this._apiClient);

  /// Fetches the public ledger entries from backend API
  Future<void> fetchPublicLedgerEntries() async {
    _isLoading = true;
    _errorMessage = null; // Clear any previous errors
    notifyListeners(); // Notify listeners that loading has started

    try {
      // Call the API client method to get ledger entries
      _publicLedgerEntries = await _apiClient.getLedgerEntries();
      if (kDebugMode) print('[LedgerProvider] Fetched ${_publicLedgerEntries.length} public ledger entries.');
      _errorMessage = null; // Clear error on success
    } catch (e) {
      _errorMessage = "Failed to fetch public ledger: $e";
      if (kDebugMode) print('[LedgerProvider] Error fetching public ledger: $e');
    } finally {
      _isLoading = false; // Always set loading to false when done
      notifyListeners(); // Notify listeners that state has changed (either loaded or error)
    }
  }

  /// Sends loves to a recipient wallet ID from a sender wallet ID with specified amount and optional memo.
  /// Returns true if successful, false otherwise.
  Future<bool> sendLoves({
    required String senderWalletId,
    required String recipientWalletId,
    required int amount,
    String? memo, // Added optional memo parameter
  }) async {
    if (amount <= 0) {
      _errorMessage = "Amount of loves to send must be greater than zero.";
      notifyListeners();
      return false;
    }

    _isLoading = true; // Set loading true before API call
    _errorMessage = null; // Clear any previous errors
    notifyListeners(); // Notify listeners that sending process has started

    try {
      final response = await _apiClient.sendLoves(
        senderWalletId: senderWalletId,
        recipientWalletId: recipientWalletId,
        amount: amount,
        memo: memo, // Pass memo
      );

      // Assuming your API client's sendLoves returns a Map with a 'success' key
      if (response['success'] == true) {
        if (kDebugMode) {
          print('[LedgerProvider] Successfully sent $amount loves from $senderWalletId to $recipientWalletId');
        }
        // Refresh ledger after sending to reflect updated balances and entries
        // Calling fetchPublicLedgerEntries will automatically update _isLoading and _errorMessage
        // and call notifyListeners().
        await fetchPublicLedgerEntries();
        return true;
      } else {
        // Handle API-specific error messages if your backend provides them
        _errorMessage = response['message'] ?? 'Failed to send loves.'; // Changed from 'error' to 'message' as a common key
        notifyListeners(); // Notify listeners about the error
        return false;
      }
    } catch (e) {
      _errorMessage = 'Unexpected error sending loves: $e';
      if (kDebugMode) print('[LedgerProvider] Error sending loves: $e');
      notifyListeners(); // Notify listeners about the unexpected error
      return false;
    } finally {
      // _isLoading will be set to false by fetchPublicLedgerEntries() if it's successful,
      // or directly by the catch block if an error occurs.
      // We only need to ensure it's false if no `fetchPublicLedgerEntries` call happens
      // or in case of early exit. Redundant but safe.
      _isLoading = false;
      // No extra notifyListeners() here, as it's handled by fetchPublicLedgerEntries or error catch.
    }
  }

  /// Clears current error state
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
