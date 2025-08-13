// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_account.dart';
import '../service/api_client.dart';
import '../models/goodwill_action.dart';

// -----------------------------------------------------------------------------
// USER ACCOUNT PROVIDER
// -----------------------------------------------------------------------------

/// StateNotifier that manages a single UserAccount object.
/// This is responsible for fetching the user's profile on startup or on demand.
class UserAccountNotifier extends StateNotifier<AsyncValue<UserAccount?>> {
  final PeoplesCoinApiClient _apiClient;

  UserAccountNotifier(this._apiClient) : super(const AsyncValue.data(null));

  /// Fetches the authenticated user profile securely.
  Future<void> fetchUser() async {
    state = const AsyncValue.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }
      
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to get Firebase ID token.');
      }

      final userAccount = await _apiClient.getAuthenticatedUserProfile(idToken: idToken);
      state = AsyncValue.data(userAccount);
      
      if (kDebugMode) {
        print('[UserAccountNotifier] Fetched user: ${userAccount.username}');
      }
    } catch (e, st) {
      state = AsyncValue.error('Failed to fetch user data: $e', st);
      if (kDebugMode) {
        print('[UserAccountNotifier] Error fetching user: $e');
      }
    }
  }

  /// Clears the current user account state.
  void clearUser() {
    state = const AsyncValue.data(null);
  }
}

/// The main provider for the UserAccountNotifier.
final userAccountProvider = StateNotifierProvider<UserAccountNotifier, AsyncValue<UserAccount?>>(
  (ref) => UserAccountNotifier(ref.watch(apiClientProvider)),
);

// -----------------------------------------------------------------------------
// USER GOODWILL ACTIONS PROVIDER
// -----------------------------------------------------------------------------

/// A FutureProvider that fetches the user's goodwill actions.
/// This provider depends on the userAccountProvider to get the user's ID.
/// It automatically refreshes if the userAccountProvider changes.
final userActionsProvider = FutureProvider<List<GoodwillAction>>((ref) async {
  final userAccountAsync = ref.watch(userAccountProvider);
  
  if (userAccountAsync.isLoading || userAccountAsync.value == null) {
    // Return an empty list or throw an error if the user is not available yet.
    // The UI will handle the loading state automatically.
    return [];
  }
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return [];
  }
  
  try {
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      return [];
    }

    final apiClient = ref.read(apiClientProvider);
    final actions = await apiClient.getUserGoodwillActions(
      userId: userAccountAsync.value!.id,
      idToken: idToken,
    );
    
    if (kDebugMode) {
      print('[UserActionsProvider] Fetched ${actions.length} user actions.');
    }
    
    return actions;
  } catch (e, st) {
    if (kDebugMode) {
      print('[UserActionsProvider] Error fetching user actions: $e');
    }
    // Riverpod's FutureProvider handles the error state automatically.
    // We can simply re-throw the error or return a handled state.
    throw Exception('Failed to fetch user actions: $e');
  }
});

