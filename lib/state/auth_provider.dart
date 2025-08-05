import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../models/user_account.dart';
import '../service/api_client.dart';

/// Manages user authentication state using Firebase Auth and integrates with backend user data.
class AuthProvider with ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final PeoplesCoinApiClient _apiClient;

  fb_auth.User? _user;
  UserAccount? _userAccount;
  String? _error;

  // `_isLoading` is for actions like the sign-in button press.
  bool _isLoading = false;

  // `_isInitializing` is ONLY for the initial app startup authentication check.
  bool _isInitializing = true;

  // --- Public Getters ---
  fb_auth.User? get user => _user;
  UserAccount? get userAccount => _userAccount;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing; // The router will use this.

  AuthProvider(this._apiClient) {
    // Listen to auth state changes and let a single handler manage the logic.
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// This is the single source of truth for handling auth changes.
  /// It runs on app startup and after any sign-in/sign-out event.
  Future<void> _onAuthStateChanged(fb_auth.User? firebaseUser) async {
    // If the user object is the same, no need to do anything.
    if (firebaseUser?.uid == _user?.uid && !_isInitializing) return;
    
    _user = firebaseUser;

    if (firebaseUser != null) {
      // If a user is logged in, always fetch their associated backend profile.
      try {
        _userAccount = await _apiClient.getUserById(firebaseUser.uid);
      } catch (e) {
        print('Error fetching user account: $e');
        // If the backend profile is missing, we treat it as a failed login.
        _userAccount = null;
        _user = null; // Force sign out.
      }
    } else {
      // If no user from Firebase, clear the local user profile.
      _userAccount = null;
    }

    // This check ensures we only flip the `isInitializing` flag once on app startup.
    if (_isInitializing) {
      _isInitializing = false;
    }
    
    // Ensure loading indicators from sign-in/sign-up are turned off.
    _isLoading = false;

    // Notify all listeners that the final, complete state is ready.
    notifyListeners();
  }

  /// Sign in with email and password.
  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    // Dev user credentials for quick local testing
    const devEmail = "dfeen87@brightacts.com";
    const devPassword = "bleigh1!";

    if (email == devEmail && password == devPassword) {
      return _signInWithMockUser(email);
    }

    // --- Standard Firebase Sign In ---
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // This call will trigger the `_onAuthStateChanged` listener, which handles the rest.
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return {'success': true, 'message': 'Signed in successfully!'};
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = _firebaseErrorMessage(e);
      _isLoading = false;
      notifyListeners(); // Notify to show the error.
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners(); // Notify to show the error.
      return {'success': false, 'error': _error};
    }
  }

  /// Special handler for the mock developer user.
  /// This does not trigger the Firebase listener, so it manages its own state.
  Future<Map<String, dynamic>> _signInWithMockUser(String email) async {
    _isLoading = true;
    notifyListeners();

    _user = UserMock(email: email);
    try {
      _userAccount = await _apiClient.getUserById(_user!.uid);
    } catch (e) {
      print('Error fetching mock user account: $e');
      _userAccount = null;
      _user = null; // Failed to get profile, so fail the login.
    }

    if (_isInitializing) {
      _isInitializing = false;
    }
    _isLoading = false;
    notifyListeners();
    return {'success': true, 'message': 'Dev user signed in successfully!'};
  }

  /// Register new user with email and password.
  Future<Map<String, dynamic>> signUpWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // This call will trigger the `_onAuthStateChanged` listener.
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // NOTE: If you create a backend user profile here, the listener will fetch it.
      return {'success': true, 'message': 'Account created successfully!'};
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = _firebaseErrorMessage(e);
      _isLoading = false;
      notifyListeners(); // Notify to show the error.
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners(); // Notify to show the error.
      return {'success': false, 'error': _error};
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    // The `_onAuthStateChanged` listener will handle clearing the state
    // when it receives the `null` user from Firebase.
    await _auth.signOut();
  }

  /// Helper to convert Firebase error codes to user-friendly messages.
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
}

// --- Your Mock Classes (Unchanged) ---
class UserMock implements fb_auth.User {
  @override
  final String email;

  UserMock({required this.email});

  @override
  String get uid => 'mock_uid_${email.hashCode}';

  @override
  String? get displayName => 'Mock User';

  @override
  bool get isAnonymous => false;

  @override
  bool get isEmailVerified => true;

  @override
  fb_auth.UserMetadata get metadata => UserMetadata(
        creationTime: DateTime.now(),
        lastSignInTime: DateTime.now(),
      );

  // --- All other required overrides for fb_auth.User ---
  @override
  String? get phoneNumber => null;
  @override
  String? get photoURL => null;
  @override
  List<fb_auth.UserInfo> get providerData => [];
  @override
  String? get refreshToken => null;
  @override
  String? get tenantId => null;
  @override
  Future<void> sendEmailVerification([fb_auth.ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<fb_auth.User> unlink(String providerId) async {throw UnimplementedError();}
  @override
  Future<fb_auth.UserCredential> linkWithProvider(fb_auth.AuthProvider provider) async {throw UnimplementedError();}
  @override
  Future<fb_auth.UserCredential> reauthenticateWithProvider(fb_auth.AuthProvider provider) async {throw UnimplementedError();}
  @override
  Future<fb_auth.UserCredential> linkWithPopup(fb_auth.AuthProvider provider) async {throw UnimplementedError();}
  @override
  Future<void> linkWithRedirect(fb_auth.AuthProvider provider) async {throw UnimplementedError();}
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {return 'mock_id_token';}
  @override
  Future<void> reload() async {}
  @override
  Future<fb_auth.UserCredential> linkWithCredential(fb_auth.AuthCredential credential) {throw UnimplementedError();}
  @override
  Future<void> delete() {throw UnimplementedError();}
  @override
  Future<void> updateEmail(String newEmail) {throw UnimplementedError();}
  @override
  Future<void> updatePassword(String newPassword) {throw UnimplementedError();}
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) {throw UnimplementedError();}
  @override
  Future<void> updateDisplayName(String? displayName) {throw UnimplementedError();}
  @override
  Future<void> updatePhotoURL(String? photoURL) {throw UnimplementedError();}
  @override
  Future<void> updatePhoneNumber(fb_auth.PhoneAuthCredential credential) {throw UnimplementedError();}
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [fb_auth.ActionCodeSettings? actionCodeSettings]) {throw UnimplementedError();}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UserMetadata implements fb_auth.UserMetadata {
  @override
  final DateTime creationTime;
  @override
  final DateTime lastSignInTime;
  UserMetadata({required this.creationTime, required this.lastSignInTime});
}
