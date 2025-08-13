// lib/state/auth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../service/api_client.dart';
import '../models/user_account.dart';
import '../service/wallet_manager.dart'; // We still need to import this.

/// Enum to represent the authentication status.
enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// --- Providers ---

// Provides a stream of Firebase user authentication state changes.
final firebaseAuthProvider = Provider<fb_auth.FirebaseAuth>((ref) {
  return fb_auth.FirebaseAuth.instance;
});

final firebaseAuthStateChangesProvider = StreamProvider<fb_auth.User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Provides the current user's backend profile (UserAccount), or null if unauthenticated.
final userAccountProvider = FutureProvider<UserAccount?>((ref) async {
  final firebaseUser = await ref.watch(firebaseAuthStateChangesProvider.future);
  if (firebaseUser == null) {
    return null;
  }

  final idToken = await firebaseUser.getIdToken();
  final apiClient = ref.watch(apiClientProvider);

  try {
    final userAccount = await apiClient.getAuthenticatedUserProfile(idToken: idToken);
    
    // We no longer call the WalletManager directly here.
    // The wallet initialization is now handled by a ref.listen in the wallet_provider.
    // This decouples the auth and wallet logic.
    
    return userAccount;
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching user profile: $e');
    }
    // We should log the user out here if their profile is not found.
    ref.read(authServiceProvider.notifier).signOut();
    return null;
  }
});

// A provider that listens to the userAccountProvider and provides a simple AuthStatus.
final authStatusProvider = Provider<AuthStatus>((ref) {
  final firebaseAuthState = ref.watch(firebaseAuthStateChangesProvider);
  final userAccountState = ref.watch(userAccountProvider);

  if (firebaseAuthState.isLoading || userAccountState.isLoading) {
    return AuthStatus.loading;
  }

  if (firebaseAuthState.hasError || userAccountState.hasError) {
    return AuthStatus.error;
  }

  final firebaseUser = firebaseAuthState.value;
  final userAccount = userAccountState.value;

  if (firebaseUser != null && userAccount != null) {
    return AuthStatus.authenticated;
  } else {
    return AuthStatus.unauthenticated;
  }
});

/// --- Auth Service Notifier ---
/// This notifier will handle the business logic of signing in and out.
class AuthServiceNotifier extends StateNotifier<void> {
  final Ref _ref;
  final fb_auth.FirebaseAuth _auth;
  final ApiClient _apiClient;

  AuthServiceNotifier(this._ref, this._auth, this._apiClient) : super(null);

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on fb_auth.FirebaseAuthException catch (e) {
      // Throw the specific exception so the UI can catch it.
      throw _firebaseAuthException(e);
    }
  }

  Future<void> signUp(String email, String password, {required String username, required String recaptchaToken}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final idToken = await userCredential.user!.getIdToken();

      // Call the backend to create the user account
      // The backend should also create the wallet associated with this user ID.
      await _apiClient.createUserAndWallet(
        username: username,
        recaptchaToken: recaptchaToken,
        idToken: idToken,
      );
      
      // The wallet initialization is now handled automatically by the wallet_provider
      // when it sees a new user account has been created.
      
    } on fb_auth.FirebaseAuthException catch (e) {
      throw _firebaseAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper method for friendly error messages
  String _firebaseAuthException(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email': return 'The email address is badly formatted.';
      case 'user-disabled': return 'This user has been disabled.';
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'This email is already in use.';
      case 'operation-not-allowed': return 'Operation not allowed. Please contact support.';
      case 'weak-password': return 'The password is too weak.';
      default: return e.message ?? 'Authentication error occurred.';
    }
  }
}

final authServiceProvider = StateNotifierProvider<AuthServiceNotifier, void>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthServiceNotifier(ref, auth, apiClient);
});
