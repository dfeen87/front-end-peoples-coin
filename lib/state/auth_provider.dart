// lib/state/auth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../service/api_client.dart';
import '../models/user_account.dart';

/// --- Auth State ---
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final fb_auth.User? firebaseUser;
  final UserAccount? userAccount;
  final AuthStatus status;
  final String? error;

  const AuthState({
    this.firebaseUser,
    this.userAccount,
    this.status = AuthStatus.initial,
    this.error,
  });

  AuthState copyWith({
    fb_auth.User? firebaseUser,
    UserAccount? userAccount,
    AuthStatus? status,
    String? error,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userAccount: userAccount ?? this.userAccount,
      status: status ?? this.status,
      error: error,
    );
  }

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
}

/// --- Auth Notifier ---
class AuthNotifier extends StateNotifier<AuthState> {
  final PeoplesCoinApiClient _apiClient;
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  StreamSubscription<fb_auth.User?>? _authSub;

  // Dev user credentials for quick local testing
  static const _devEmail = 'dfeen87@brightacts.com';
  static const _devPassword = 'bleigh1!';

  AuthNotifier(this._apiClient) : super(AuthState.initial()) {
    _authSub = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Handle Firebase auth changes
  Future<void> _onAuthStateChanged(fb_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      state = state.copyWith(
        firebaseUser: null,
        userAccount: null,
        status: AuthStatus.unauthenticated,
        error: null,
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, firebaseUser: firebaseUser);

    try {
      final idToken = await firebaseUser.getIdToken();
      final account = await _apiClient.getAuthenticatedUserProfile(idToken: idToken);
      state = state.copyWith(
        firebaseUser: firebaseUser,
        userAccount: account,
        status: AuthStatus.authenticated,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        firebaseUser: null,
        userAccount: null,
        status: AuthStatus.error,
        error: 'Failed to fetch user profile: $e',
      );
    }
  }

  /// Sign in with email/password
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    if (email == _devEmail && password == _devPassword) {
      await _signInWithDevUser();
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // `_onAuthStateChanged` handles backend fetch
    } on fb_auth.FirebaseAuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: _firebaseErrorMessage(e));
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: 'Unexpected error: $e');
    }
  }

  /// Sign up new user
  Future<void> signUp(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on fb_auth.FirebaseAuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: _firebaseErrorMessage(e));
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: 'Unexpected error: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Dev/mock user sign in
  Future<void> _signInWithDevUser() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    final mockUser = _MockUser(email: _devEmail);
    state = state.copyWith(firebaseUser: mockUser);

    try {
      final account = await _apiClient.getAuthenticatedUserProfile(idToken: 'mock_id_token');
      state = state.copyWith(
        firebaseUser: mockUser,
        userAccount: account,
        status: AuthStatus.authenticated,
      );
    } catch (e) {
      state = state.copyWith(
        firebaseUser: null,
        userAccount: null,
        status: AuthStatus.error,
        error: 'Failed to fetch mock user profile: $e',
      );
    }
  }

  /// Convert FirebaseAuthException codes to user-friendly messages
  String _firebaseErrorMessage(fb_auth.FirebaseAuthException e) {
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

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

/// --- Provider ---
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

/// --- Mock user for dev/testing ---
class _MockUser implements fb_auth.User {
  @override
  final String email;

  _MockUser({required this.email});

  @override
  String get uid => 'mock_uid_${email.hashCode}';
  @override
  String? get displayName => 'Dev User';
  @override
  bool get isAnonymous => false;
  @override
  bool get isEmailVerified => true;
  @override
  fb_auth.UserMetadata get metadata => _MockUserMetadata();
  @override
  List<fb_auth.UserInfo> get providerData => [];
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_id_token';

  // --- All other methods throw unimplemented ---
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockUserMetadata implements fb_auth.UserMetadata {
  @override
  DateTime get creationTime => DateTime.now();
  @override
  DateTime get lastSignInTime => DateTime.now();
}

