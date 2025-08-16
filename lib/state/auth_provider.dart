// lib/providers/auth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../service/api_client.dart';
import '../models/user_account.dart';

/// --- Auth Status Enum ---
enum AuthStatus { loading, authenticated, unauthenticated, error }

/// --- Auth Notifier ---
class AuthNotifier extends StateNotifier<AsyncValue<UserAccount?>> {
  final Ref _ref;
  final fb_auth.FirebaseAuth _firebaseAuth;
  final PeoplesCoinApiClient _apiClient;
  late final Stream<fb_auth.User?> _authStateChanges;
  late final StreamSubscription<fb_auth.User?> _authSub;

  AuthNotifier(this._ref, this._firebaseAuth, this._apiClient)
      : super(const AsyncValue.loading()) {
    _authStateChanges = _firebaseAuth.authStateChanges();
    _authSub = _authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        state = const AsyncValue.loading();
        try {
          state = await AsyncValue.guard(() async => _fetchBackendUser(firebaseUser));
        } catch (e, st) {
          state = AsyncValue.error('Failed to fetch backend user: $e', st);
          if (kDebugMode) print('[AuthNotifier] Error during auth change: $e');
        }
      } else {
        state = const AsyncValue.data(null);
      }
    });

    // Ensure listener is cancelled when provider is disposed
    _ref.onDispose(() => _authSub.cancel());
  }

  /// Sign in with email/password
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = await AsyncValue.guard(() async => _fetchBackendUser(credential.user!));
    } catch (e, st) {
      state = AsyncValue.error('Failed to sign in: $e', st);
      if (kDebugMode) print('[AuthNotifier] SignIn error: $e');
    }
  }

  /// Sign up + create backend user
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String recaptchaToken,
  }) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final idToken = await credential.user!.getIdToken();
      await _apiClient.createUserAndWallet(
        username: username,
        recaptchaToken: recaptchaToken,
        idToken: idToken,
      );

      state = await AsyncValue.guard(() async => _fetchBackendUser(credential.user!));
    } catch (e, st) {
      state = AsyncValue.error('Failed to sign up: $e', st);
      if (kDebugMode) print('[AuthNotifier] SignUp error: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error('Failed to sign out: $e', st);
      if (kDebugMode) print('[AuthNotifier] SignOut error: $e');
    }
  }

  /// Update Firebase profile and refresh backend user
  Future<void> updateProfile({String? name, String? email}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    state = await AsyncValue.guard(() async {
      if (name != null) await user.updateDisplayName(name);
      if (email != null) await user.updateEmail(email);
      return _fetchBackendUser(user);
    });
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
      state = const AsyncValue.data(null);
    }
  }

  /// Fetch backend user profile from API
  Future<UserAccount> _fetchBackendUser(fb_auth.User firebaseUser) async {
    final idToken = await firebaseUser.getIdToken();
    return _apiClient.getAuthenticatedUserProfile(idToken: idToken);
  }
}

/// --- Providers ---
final firebaseAuthProvider = Provider<fb_auth.FirebaseAuth>(
  (ref) => fb_auth.FirebaseAuth.instance,
);

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserAccount?>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(ref, auth, apiClient);
});

/// Current authenticated user account (backend model)
final currentUserProvider = Provider<UserAccount?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value;
});

/// Auth status enum (UI-friendly)
final authStatusProvider = Provider<AuthStatus>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (user) => user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    loading: () => AuthStatus.loading,
    error: (_, __) => AuthStatus.error,
  );
});

/// Is authenticated (bool shortcut)
final isAuthenticatedProvider =
    Provider<bool>((ref) => ref.watch(authStatusProvider) == AuthStatus.authenticated);

/// Is email verified (from Firebase, not backend)
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final fbUser = ref.watch(firebaseAuthProvider).currentUser;
  return fbUser?.emailVerified ?? false;
});

