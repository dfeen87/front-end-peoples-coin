import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/goodwill_action.dart';
import '../service/api_client.dart';

class GoodwillActionsProvider with ChangeNotifier {
  final PeoplesCoinApiClient _apiClient;

  List<GoodwillAction> _actions = [];
  bool _isLoading = false;
  String? _error;

  String? _submitError;
  bool _isSubmitting = false;

  List<GoodwillAction> get actions => _actions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  GoodwillActionsProvider(this._apiClient);

  /// Fetch all goodwill actions for a given user
  Future<void> fetchUserActions({required String userId, required String idToken}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawList = await _apiClient.getUserGoodwillActions(userId: userId, idToken: idToken);
      _actions = rawList.map((json) => GoodwillAction.fromJson(json)).toList();
    } catch (e) {
      _error = 'Failed to fetch goodwill actions: $e';
      _actions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit a new goodwill action and start polling for its verification status
  Future<void> submitGoodwill({
    required Map<String, dynamic> actionToSend,
    required String idToken,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final response = await _apiClient.submitGoodwill(goodwillAction: actionToSend, idToken: idToken);

      final String actionId = response['id'] as String;

      // Add new action locally with initial PENDING_VERIFICATION status
      final newAction = GoodwillAction.fromJson({
        ...actionToSend,
        'id': actionId,
        'status': 'PENDING_VERIFICATION',
      });
      _actions.insert(0, newAction);
      notifyListeners();

      // Start polling for status updates until terminal state reached
      await _pollGoodwillStatus(actionId, idToken);
    } catch (e) {
      _submitError = 'Failed to submit goodwill action: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Internal polling loop to update goodwill action status
  Future<void> _pollGoodwillStatus(String actionId, String idToken) async {
    bool done = false;
    const pollInterval = Duration(seconds: 5);

    while (!done) {
      await Future.delayed(pollInterval);

      try {
        final statusString = await _apiClient.getGoodwillStatus(actionId, idToken);
        if (statusString == null || statusString.isEmpty) {
          done = true;
          continue;
        }

        final status = GoodwillAction._statusFromString(statusString);

        final index = _actions.indexWhere((a) => a.id == actionId);
        if (index != -1) {
          final updatedAction = _actions[index].copyWith(status: status);
          _actions[index] = updatedAction;
          notifyListeners();
        }

        // Stop polling on terminal states
        if (status == GoodwillStatus.verified || status == GoodwillStatus.rejected) {
          done = true;
        }
      } catch (_) {
        // Stop polling on error; could add retry logic here if desired
        done = true;
      }
    }
  }
}

