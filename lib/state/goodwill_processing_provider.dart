import 'package:flutter/foundation.dart';
import '../models/goodwill_action.dart'; // For the response model
import '../models/goodwill_action_to_send.dart'; // For the request model
import '../services/api_client.dart'; // For backend submission

/// Manages the process of submitting a goodwill action, including
/// potential on-device AI processing before sending to the backend.
class GoodwillProcessingProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;
  // AmbientAiService is removed for web compatibility, so no _ambientAiService here.

  bool _isProcessing = false;
  String? _processingError;
  GoodwillAction? _lastSubmittedAction; // Store the result of the last successful submission

  bool get isProcessing => _isProcessing;
  String? get processingError => _processingError;
  GoodwillAction? get lastSubmittedAction => _lastSubmittedAction;

  // Update constructor: now only takes _apiClient as parameter.
  GoodwillProcessingProvider(this._apiClient);

  /// Initiates and processes a goodwill action.
  /// This method will eventually include on-device AI logic.
  Future<Map<String, dynamic>> submitGoodwillAction({
    required String userId,
    required String actionType,
    required String description,
    required int lovesValue, // This could eventually be influenced by Ambient AI
    Map<String, dynamic>? contextualData,
  }) async {
    _isProcessing = true;
    _processingError = null;
    _lastSubmittedAction = null;
    notifyListeners(); // Notify UI that processing has started

    try {
      // --- Phase 1: On-device Ambient AI Processing (Simulated/Placeholder) ---
      // Removed AmbientAiService usage for web compatibility.
      // When implementing Ambient AI for web, this section will be replaced with
      // Dart FFI for JavaScript interop, or a dedicated web AI library.
      // For now, we skip this step.
      print('GoodwillProcessing: On-device AI processing skipped for web compatibility.');
      
      // Ensure contextualData is non-null for GoodwillActionToSend by providing an empty map if it's null.
      final Map<String, dynamic> finalContextualData = contextualData ?? {};


      // --- Phase 2: Prepare and Send to Backend API ---
      final actionToSend = GoodwillActionToSend(
        userId: userId,
        actionType: actionType,
        description: description,
        timestamp: DateTime.now().toUtc(), // Client-side timestamp
        lovesValue: lovesValue,
        contextualData: finalContextualData, // Pass the non-nullable map
      );

      final result = await _apiClient.submitGoodwill(actionToSend);

      if (result['success']) {
        _lastSubmittedAction = GoodwillAction.fromJson(result['data']);
        print('Goodwill action successfully submitted and processed: ${_lastSubmittedAction!.id}');
        return {'success': true, 'message': 'Goodwill action accepted and queued.', 'action': _lastSubmittedAction};
      } else {
        _processingError = result['error'] ?? 'An unknown error occurred during submission.';
        print('Goodwill action submission failed: $_processingError');
        return {'success': false, 'error': _processingError, 'details': result['details']};
      }
    } catch (e) {
      _processingError = "An unexpected error occurred: $e";
      print('Error in submitGoodwillAction: $e');
      return {'success': false, 'error': _processingError};
    } finally {
      _isProcessing = false;
      notifyListeners(); // Notify UI that processing has completed (success or failure)
    }
  }
}
