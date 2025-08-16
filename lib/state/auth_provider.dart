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
  final ApiClient _apiClient;

  AuthNotifier(this._ref, this._firebaseAuth, this._apiClient)
      : super(const AsyncValue.loading()) {
    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen((fb_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        state = const AsyncValue.loading();
        state = await AsyncValue.guard(() async => await _fetchBackendUser(firebaseUser));
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  /// Sign in
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _fetchBackendUser(credential.user!);
    });
  }

  /// Sign up
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String recaptchaToken,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final idToken = await credential.user!.getIdToken();

      // Create backend user + wallet
      await _apiClient.createUserAndWallet(
        username: username,
        recaptchaToken: recaptchaToken,
        idToken: idToken,
      );

      return await _fetchBackendUser(credential.user!);
    });
  }

  /// Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    state = const AsyncValue.data(null);
  }

  /// Update profile
  Future<void> updateProfile({String? name, String? email}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    state = await AsyncValue.guard(() async {
      if (name != null) await user.updateDisplayName(name);
      if (email != null) await user.updateEmail(email);
      return await _fetchBackendUser(user);
    });
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Send password reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
      state = const AsyncValue.data(null);
    }
  }

  /// Fetch backend user account
  Future<UserAccount> _fetchBackendUser(fb_auth.User firebaseUser) async {
    final idToken = await firebaseUser.getIdToken();
    return await _apiClient.getAuthenticatedUserProfile(idToken: idToken);
  }
}

/// --- Providers ---

final firebaseAuthProvider = Provider<fb_auth.FirebaseAuth>((ref) => fb_auth.FirebaseAuth.instance);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserAccount?>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(ref, auth, apiClient);
});

// Current user convenience provider
final currentUserProvider = Provider<UserAccount?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value;
});

// Auth status provider
final authStatusProvider = Provider<AuthStatus>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (user) => user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    loading: () => AuthStatus.loading,
    error: (_, __) => AuthStatus.error,
  );
});

// Is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) => ref.watch(authStatusProvider) == AuthStatus.authenticated);

// Is email verified
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isEmailVerified ?? false;
});

