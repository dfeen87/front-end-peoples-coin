// lib/state/goodwill_processing_provider.dart
import 'package:flutter/material.dart';
import '../service/api_client.dart';
import '../models/goodwill_action.dart';
import '../models/goodwill_action_to_send.dart';

/// Manages the process of submitting a goodwill action, including
/// potential on-device AI processing before sending to the backend.
class GoodwillProcessingProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  bool _isProcessingGoodwill = false;
  String? _error;
  GoodwillAction? _lastSubmittedAction;

  bool get isProcessingGoodwill => _isProcessingGoodwill;
  String? get error => _error;
  GoodwillAction? get lastSubmittedAction => _lastSubmittedAction;

  GoodwillProcessingProvider(this._apiClient);

  /// Initiates and processes a goodwill action.
  /// Returns true on success, false on failure.
  Future<bool> submitGoodwill({
    required String performerUserId,
    required String actionType,
    required String description,
    required int lovesValue,
    Map<String, dynamic>? contextualData,
  }) async {
    _isProcessingGoodwill = true;
    _error = null;
    _lastSubmittedAction = null;
    notifyListeners();

    try {
      // If you want to add AI or pre-processing here, do it before sending

      final finalContextualData = contextualData ?? {};

      final actionToSend = GoodwillActionToSend(
        performerUserId: performerUserId,
        actionType: actionType,
        description: description,
        lovesValue: lovesValue,
        contextualData: finalContextualData,
        timestamp: DateTime.now().toUtc(),
      );

      final result = await _apiClient.submitGoodwill(actionToSend);

      if (result['success'] == true) {
        _lastSubmittedAction = GoodwillAction.fromJson(result['data']);
        return true;
      } else {
        _error = result['error'] ?? 'An unknown error occurred during submission.';
        return false;
      }
    } catch (e) {
      _error = "An unexpected error occurred: $e";
      return false;
    } finally {
      _isProcessingGoodwill = false;
      notifyListeners();
    }
  }
}

