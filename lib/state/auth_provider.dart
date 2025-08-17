// lib/state/auth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../service/api_client.dart';
import '../models/user_account.dart';
import 'wallet_provider.dart';

/// --- Auth Status Enum ---
enum AuthStatus { loading, authenticated, unauthenticated, error }

/// --- Auth Notifier ---
class AuthNotifier extends StateNotifier<AsyncValue<UserAccount?>> {
  final Ref _ref;
  final fb_auth.FirebaseAuth _firebaseAuth;
  final PeoplesCoinApiClient _apiClient;
  late final StreamSubscription<fb_auth.User?> _authSub;

  UserAccount? _currentUser;

  AuthNotifier(this._ref, this._firebaseAuth, this._apiClient)
      : super(const AsyncValue.loading()) {
    _authSub = _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        await _handleUserAuthenticated(firebaseUser);
      } else {
        await _handleUserSignedOut();
      }
    });

    _ref.onDispose(() => _authSub.cancel());
  }

  UserAccount? get currentUser => _currentUser;

  /// Handle authenticated user state change
  Future<void> _handleUserAuthenticated(fb_auth.User firebaseUser) async {
    state = const AsyncValue.loading();
    try {
      final userAccount = await _fetchBackendUser(firebaseUser);
      _currentUser = userAccount;
      state = AsyncValue.data(userAccount);

      final walletId = userAccount.walletId;
      if (walletId != null) {
        _ref.read(walletProvider.notifier).fetchWallet(walletId);
        if (kDebugMode) {
          print('[AuthNotifier] Wallet fetch triggered after auth. Wallet ID: $walletId');
        }
      }
    } catch (e, stackTrace) {
      _currentUser = null;
      state = AsyncValue.error('Failed to fetch backend user: $e', stackTrace);
      if (kDebugMode) print('[AuthNotifier] Error during auth change: $e');
    }
  }

  /// Handle user signed out
  Future<void> _handleUserSignedOut() async {
    _currentUser = null;
    state = const AsyncValue.data(null);
    _ref.read(walletProvider.notifier).clearWallet();
    if (kDebugMode) print('[AuthNotifier] User signed out, wallet cleared');
  }

  /// Sign in
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = credential.user;
      if (fbUser == null) throw Exception('No Firebase user returned');

      final userAccount = await _fetchBackendUser(fbUser);
      _currentUser = userAccount;
      state = AsyncValue.data(userAccount);

      if (userAccount.walletId != null) {
        _ref.read(walletProvider.notifier).fetchWallet(userAccount.walletId!);
      }
    } catch (e, stackTrace) {
      _currentUser = null;
      state = AsyncValue.error('Failed to sign in: $e', stackTrace);
    }
  }

  /// Sign up
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

      final fbUser = credential.user;
      if (fbUser == null) throw Exception('Sign up failed: no Firebase user');

      final idToken = await fbUser.getIdToken();
      if (idToken == null) throw Exception('Failed to obtain Firebase ID token');

      final userAccount = await _apiClient.createUserAndWallet(
        username: username,
        recaptchaToken: recaptchaToken,
        idToken: idToken,
      );

      _currentUser = userAccount;
      state = AsyncValue.data(userAccount);

      if (userAccount.walletId != null) {
        _ref.read(walletProvider.notifier).fetchWallet(userAccount.walletId!);
      }
    } catch (e, stackTrace) {
      _currentUser = null;
      state = AsyncValue.error('Failed to sign up: $e', stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      state = const AsyncValue.data(null);
      _ref.read(walletProvider.notifier).clearWallet();
    } catch (e, stackTrace) {
      state = AsyncValue.error('Failed to sign out: $e', stackTrace);
    }
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    state = await AsyncValue.guard(() async {
      if (name != null) await user.updateDisplayName(name);
      if (email != null) await user.updateEmail(email);
      final updated = await _fetchBackendUser(user);
      _currentUser = updated;
      return updated;
    });
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    if (!user.emailVerified) await user.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) throw Exception('Email required');
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    try {
      await user.delete();
      _currentUser = null;
      state = const AsyncValue.data(null);
      _ref.read(walletProvider.notifier).clearWallet();
    } catch (e, stackTrace) {
      state = AsyncValue.error('Failed to delete account: $e', stackTrace);
    }
  }

  Future<void> refreshUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) {
      _currentUser = null;
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final userAccount = await _fetchBackendUser(fbUser);
      _currentUser = userAccount;
      state = AsyncValue.data(userAccount);
    } catch (e, stackTrace) {
      state = AsyncValue.error('Failed to refresh user: $e', stackTrace);
    }
  }

  Future<UserAccount> _fetchBackendUser(fb_auth.User firebaseUser) async {
    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) throw Exception('Failed to get Firebase ID token');
    return _apiClient.getAuthenticatedUserProfile(idToken: idToken);
  }

  bool get hasValidWallet => _currentUser?.walletId != null;
  String? get currentWalletId => _currentUser?.walletId;
}

/// Providers
final firebaseAuthProvider =
    Provider<fb_auth.FirebaseAuth>((ref) => fb_auth.FirebaseAuth.instance);

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserAccount?>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(ref, auth, apiClient);
});

final currentUserProvider = Provider<UserAccount?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value;
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (u) => u != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    loading: () => AuthStatus.loading,
    error: (_, __) => AuthStatus.error,
  );
});

final isAuthenticatedProvider =
    Provider<bool>((ref) => ref.watch(authStatusProvider) == AuthStatus.authenticated);

final isEmailVerifiedProvider = Provider<bool>((ref) {
  final fbUser = ref.watch(firebaseAuthProvider).currentUser;
  return fbUser?.emailVerified == true;
});

final currentUserFromNotifierProvider = Provider<UserAccount?>(
    (ref) => ref.watch(authNotifierProvider.notifier).currentUser);

final hasValidWalletProvider = Provider<bool>(
    (ref) => ref.watch(authNotifierProvider.notifier).hasValidWallet);

final currentWalletIdProvider = Provider<String?>(
    (ref) => ref.watch(authNotifierProvider.notifier).currentWalletId);

final authServiceProvider = authNotifierProvider;

