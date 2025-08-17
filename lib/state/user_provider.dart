// lib/state/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../service/api_client.dart';
import '../models/user_account.dart';
import '../models/goodwill_token.dart';
import '../models/goodwill_action.dart';

/// -----------------------------------------------------------------------------
/// AUTH STATE PROVIDER (fixes: firebaseAuthStateChangesProvider missing)
/// -----------------------------------------------------------------------------
final firebaseAuthStateChangesProvider =
    StreamProvider<auth.User?>((ref) => auth.FirebaseAuth.instance.authStateChanges());

/// -----------------------------------------------------------------------------
/// USER ACCOUNT NOTIFIER
/// -----------------------------------------------------------------------------
class UserAccountNotifier extends StateNotifier<AsyncValue<UserAccount?>> {
  final PeoplesCoinApiClient _apiClient;

  UserAccountNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async => fetchUser();

  /// Fetches the current authenticated user profile from API.
  Future<void> fetchUser() async {
    state = const AsyncValue.loading();
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final idToken = await firebaseUser.getIdToken();
      if (idToken?.isEmpty == true) {
        throw Exception('Failed to obtain Firebase ID token.');
      }

      final userAccount =
          await _apiClient.getAuthenticatedUserProfile(idToken: idToken!);

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
  (ref) => UserAccountNotifier(ref.read(apiClientProvider)),
);

/// Provides a list of the current user's goodwill actions.
final userGoodwillActionsProvider = FutureProvider<List<GoodwillAction>>((ref) async {
  final userAccountState = ref.watch(userAccountProvider);

  final user = userAccountState.value;
  if (user == null) return [];

  try {
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return [];

    final idToken = await firebaseUser.getIdToken();
    if (idToken?.isEmpty == true) return [];

    final apiClient = ref.read(apiClientProvider);
    
    // Fix: Remove userId parameter - the API method doesn't expect it
    // The user identity comes from the idToken
    return await apiClient.getUserGoodwillActions(
      idToken: idToken!,
    );
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

  try {
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return [];

    final idToken = await firebaseUser.getIdToken();
    if (idToken?.isEmpty == true) return [];

    final apiClient = ref.read(apiClientProvider);
    
    // Fix: This should probably call getUserGoodwillTokens, not getUserGoodwillActions
    // And remove the userId parameter
    return await apiClient.getUserGoodwillTokens(
      idToken: idToken!,
    );
  } catch (e) {
    if (kDebugMode) print('[UserGoodwillTokensProvider] Error: $e');
    return [];
  }
});
