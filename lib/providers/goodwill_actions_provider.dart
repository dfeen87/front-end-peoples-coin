import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goodwill_action.dart';
import '../service/api_client.dart';
import 'app_state_providers.dart';

class GoodwillActionsState {
  final List<GoodwillAction> actions;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;
  final String? submitError;

  const GoodwillActionsState({
    this.actions = const [],
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
    this.submitError,
  });

  GoodwillActionsState copyWith({
    List<GoodwillAction>? actions,
    bool? isLoading,
    String? error,
    bool? isSubmitting,
    String? submitError,
  }) {
    return GoodwillActionsState(
      actions: actions ?? this.actions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
    );
  }

  factory GoodwillActionsState.initial() => const GoodwillActionsState();
}

class GoodwillActionsNotifier extends StateNotifier<GoodwillActionsState> {
  final PeoplesCoinApiClient _apiClient;

  GoodwillActionsNotifier(this._apiClient) : super(GoodwillActionsState.initial());

  Future<void> fetchUserActions({
    required String userId,
    required String idToken,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final rawList = await _apiClient.getUserGoodwillActions(
        userId: userId,
        idToken: idToken!,
      );
      final actions = rawList.map((json) => GoodwillAction.fromJson(json)).toList();
      state = state.copyWith(actions: actions);
    } catch (e) {
      state = state.copyWith(actions: [], error: 'Failed to fetch goodwill actions: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> submitGoodwill({
    required Map<String, dynamic> actionToSend,
    required String idToken,
  }) async {
    state = state.copyWith(isSubmitting: true, submitError: null);

    try {
      final response = await _apiClient.submitGoodwill(
        goodwillAction: actionToSend,
        idToken: idToken!,
      );

      final String actionId = response['id'] as String;

      final newAction = GoodwillAction.fromJson({
        ...actionToSend,
        'id': actionId,
        'status': 'PENDING_VERIFICATION',
      });

      state = state.copyWith(actions: [newAction, ...state.actions]);

      await _pollGoodwillStatus(actionId, idToken);
    } catch (e) {
      state = state.copyWith(submitError: 'Failed to submit goodwill action: $e');
      rethrow;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> _pollGoodwillStatus(String actionId, String idToken) async {
    bool done = false;
    const pollInterval = Duration(seconds: 5);

    while (!done) {
      await Future.delayed(pollInterval);

      try {
        final statusString = await _apiClient.getGoodwillStatus(actionId, idToken);
        if (statusString == null || statusString?.isEmpty == true) {
          done = true;
          continue;
        }

        final status = GoodwillAction._statusFromString(statusString);
        final index = state.actions.indexWhere((a) => a.id == actionId);

        if (index != -1) {
          final updatedActions = [...state.actions];
          updatedActions[index] = updatedActions[index].copyWith(status: status);
          state = state.copyWith(actions: updatedActions);
        }

        if (status == GoodwillStatus.verified || status == GoodwillStatus.rejected) {
          done = true;
        }
      } catch (e) {
        debugPrint('Error polling goodwill action status for $actionId: $e');
        done = true;
      }
    }
  }
}

final goodwillActionsProviderNotifier =
    StateNotifierProvider<GoodwillActionsNotifier, GoodwillActionsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GoodwillActionsNotifier(apiClient);
});

