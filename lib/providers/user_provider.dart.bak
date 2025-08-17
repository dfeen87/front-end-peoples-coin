import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_account.dart';
import '../models/goodwill_action.dart';
import '../service/api_client.dart';
import 'app_state_providers.dart'; // <-- contains apiClientProvider

// --- State ---
class UserState {
  final UserAccount? currentUser;
  final bool isLoadingUser;
  final String? userError;

  final List<GoodwillAction> userActions;
  final bool isLoadingActions;
  final String? actionsError;

  const UserState({
    this.currentUser,
    this.isLoadingUser = false,
    this.userError,
    this.userActions = const [],
    this.isLoadingActions = false,
    this.actionsError,
  });

  bool get isLoading => isLoadingUser || isLoadingActions;

  UserState copyWith({
    UserAccount? currentUser,
    bool? isLoadingUser,
    String? userError,
    List<GoodwillAction>? userActions,
    bool? isLoadingActions,
    String? actionsError,
  }) {
    return UserState(
      currentUser: currentUser ?? this.currentUser,
      isLoadingUser: isLoadingUser ?? this.isLoadingUser,
      userError: userError,
      userActions: userActions ?? this.userActions,
      isLoadingActions: isLoadingActions ?? this.isLoadingActions,
      actionsError: actionsError,
    );
  }

  factory UserState.initial() => const UserState();
}

// --- Notifier ---
class UserNotifier extends StateNotifier<UserState> {
  final PeoplesCoinApiClient _apiClient;

  UserNotifier(this._apiClient) : super(UserState.initial());

  String _mapErrorToMessage(Object error) {
    if (error is TimeoutException) {
      return "Request timed out. Please try again.";
    }
    return error.toString();
  }

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not signed in.');

    final token = await user.getIdToken().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('ID token fetch timed out'),
    );

    if ((token ?? '')?.isEmpty == true) {
      throw Exception('Failed to get Firebase ID token.');
    }

    return token!;
  }

  Future<void> fetchUser({required String userId}) async {
    state = state.copyWith(isLoadingUser: true, userError: null);
    try {
      final idToken = await _getIdToken();
      final user = await _apiClient.getUserAccount(userId, idToken);
      state = state.copyWith(currentUser: user, isLoadingUser: false);
    } catch (e) {
      state = state.copyWith(
        userError: _mapErrorToMessage(e),
        currentUser: null,
        isLoadingUser: false,
      );
    }
  }

  Future<void> fetchUserActions({required String userId}) async {
    state = state.copyWith(isLoadingActions: true, actionsError: null);
    try {
      final idToken = await _getIdToken();
      final actions = await _apiClient.getUserGoodwillActions(
        userId: userId,
        idToken: idToken!,
      );
      state = state.copyWith(userActions: actions, isLoadingActions: false);
    } catch (e) {
      state = state.copyWith(
        actionsError: _mapErrorToMessage(e),
        userActions: [],
        isLoadingActions: false,
      );
    }
  }

  void updateGoodwillAction(GoodwillAction updatedAction) {
    final updatedList = [...state.userActions];
    final index = updatedList.indexWhere((a) => a.id == updatedAction.id);
    if (index != -1) {
      updatedList[index] = updatedAction;
      state = state.copyWith(userActions: updatedList);
    }
  }

  void clearUserData() {
    state = UserState.initial();
  }
}

// --- Provider ---
final userProviderNotifier =
    StateNotifierProvider<UserNotifier, UserState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserNotifier(apiClient);
});

