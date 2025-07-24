// lib/state/goodwill_processing_provider.dart
import 'package:flutter/material.dart';
import '../service/api_client.dart'; // Correct import path
import '../models/goodwill_action.dart'; // Added: Needed for _lastSubmittedAction type
import '../models/goodwill_action_to_send.dart';

/// Manages the process of submitting a goodwill action, including
/// potential on-device AI processing before sending to the backend.
class GoodwillProcessingProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient; // Dependency injection

  // Harmonized state variables and getters to match SubmitGoodwillPage's usage
  bool _isProcessingGoodwill = false;
  String? _error; // Renamed from _processingError to _error
  GoodwillAction? _lastSubmittedAction;

  // Public getters matching SubmitGoodwillPage's expectations
  bool get isProcessingGoodwill => _isProcessingGoodwill;
  String? get error => _error;
  GoodwillAction? get lastSubmittedAction => _lastSubmittedAction;

  // Constructor to receive the API client
  GoodwillProcessingProvider(this._apiClient);

  /// Initiates and processes a goodwill action.
  /// Harmonized parameters and return type to match SubmitGoodwillPage's usage.
  Future<bool> submitGoodwill({ // Method name changed from submitGoodwillAction to submitGoodwill
    required String performerUserId, // Parameter name aligned with GoodwillActionToSend
    required String actionType,
    required String description,
    required int lovesValue,
    Map<String, dynamic>? contextualData,
  }) async {
    _isProcessingGoodwill = true; // Use harmonized state variable
    _error = null; // Clear previous errors
    _lastSubmittedAction = null; // Clear previous result
    notifyListeners(); // Notify UI that processing has started

    try {
      print('GoodwillProcessing: On-device AI processing skipped for web compatibility.');

      final Map<String, dynamic> finalContextualData = contextualData ?? {};

      // Correctly construct GoodwillActionToSend with performerUserId and timestamp
      final actionToSend = GoodwillActionToSend(
        performerUserId: performerUserId, // Use correct parameter
        actionType: actionType,
        description: description,
        timestamp: DateTime.now().toUtc(), // Add client-side timestamp
        lovesValue: lovesValue,
        contextualData: finalContextualData,
      );

      final result = await _apiClient.submitGoodwill(actionToSend); // Call API client

      if (result['success'] == true) {
        _lastSubmittedAction = GoodwillAction.fromJson(result['data']); // Assuming backend returns GoodwillAction
        print('Goodwill action successfully submitted and processed: ${_lastSubmittedAction!.id}');
        return true; // Return bool as expected by SubmitGoodwillPage
      } else {
        _error = result['error'] ?? 'An unknown error occurred during submission.'; // Use harmonized error variable
        print('Goodwill action submission failed: $_error');
        return false; // Return bool as expected by SubmitGoodwillPage
      }
    } catch (e) {
      _error = "An unexpected error occurred: $e"; // Use harmonized error variable
      print('Error in submitGoodwill: $e');
      return false; // Return bool as expected by SubmitGoodwillPage
    } finally {
      _isProcessingGoodwill = false; // Reset processing flag
      notifyListeners(); // Notify UI that processing has completed
    }
  }
}
