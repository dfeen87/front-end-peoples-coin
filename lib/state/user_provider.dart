// lib/state/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../services/api_service.dart';
import '../models/user_account.dart';
import '../models/goodwill_token.dart';
import '../models/goodwill_action.dart';
import 'auth_provider.dart';

/// -----------------------------------------------------------------------------
/// USER ACCOUNT SERVICE PROVIDER
/// -----------------------------------------------------------------------------
final userAccountServiceProvider = Provider<UserAccountService>((ref) {
  return UserAccountService();
});

/// -----------------------------------------------------------------------------
/// USER ACCOUNT NOTIFIER
/// -----------------------------------------------------------------------------
class UserAccountNotifier extends StateNotifier<AsyncValue<UserAccount?>> {
  final UserAccountService _service;
  final Ref _ref;

  UserAccountNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await fetchUser();
  }

  /// Fetches the current authenticated user profile.
  Future<void> fetchUser() async {
    state = const AsyncValue.loading();
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final idToken = await firebaseUser.getIdToken();
      final userAccount = await _service.getUserAccount(firebaseUser.uid);
      state = AsyncValue.data(userAccount);

      if (kDebugMode) {
        print('[UserAccountNotifier] Fetched user: ${userAccount.username}');
      }
    } catch (e, st) {
      state = AsyncValue.error('Failed to fetch user data: $e', st);
      if (kDebugMode) {
        print('[UserAccountNotifier] Error: $e');
      }
    }
  }

  /// Clears the current user account state.
  void clearUser() => state = const AsyncValue.data(null);
}

/// -----------------------------------------------------------------------------
/// PROVIDERS
/// -----------------------------------------------------------------------------

/// Provides the current authenticated user account state.
final userAccountProvider =
    StateNotifierProvider<UserAccountNotifier, AsyncValue<UserAccount?>>(
  (ref) => UserAccountNotifier(ref.read(userAccountServiceProvider), ref),
);

/// Provides a list of the current user's goodwill actions.
final userGoodwillActionsProvider = FutureProvider<List<GoodwillAction>>((ref) async {
  final userAccountState = ref.watch(userAccountProvider);

  final user = userAccountState.value;
  if (user == null) return [];

  final service = ref.read(userAccountServiceProvider);
  try {
    return await service.getUserGoodwillActions(user.id);
  } catch (e) {
    if (kDebugMode) print('[UserGoodwillActionsProvider] Error: $e');
    return [];
  }
});

/// Provides a list of the current user's goodwill tokens.
final userGoodwillTokensProvider = FutureProvider<List<GoodwillToken>>((ref) async {
  final userAccountState = ref.watch(userAccountProvider);

  final user = userAccountState.value;
  if (user == null) return [];

  final service = ref.read(userAccountServiceProvider);
  try {
    return await service.getUserGoodwillTokens(user.id);
  } catch (e) {
    if (kDebugMode) print('[UserGoodwillTokensProvider] Error: $e');
    return [];
  }
});

