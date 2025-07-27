// lib/state/auth_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
// You might not need this specific import if not directly using AuthProvider from platform_interface
// import 'package:firebase_auth_platform_interface/src/auth_provider.dart' as fb_auth_platform_provider;

import '../models/user_account.dart';
import '../service/api_client.dart';

/// Manages user authentication state using Firebase Auth and integrates with backend user data.
/// Supports dev user mock login and real Firebase login.
class AuthProvider with ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  fb_auth.User? _user;
  bool _isLoading = true; // Set to true initially for app startup check
  String? _error;

  UserAccount? _userAccount;
  bool _isUserAccountLoading = false;

  final PeoplesCoinApiClient _apiClient;

  fb_auth.User? get user => _user;
  bool get isLoading => _isLoading; // This now also reflects the initial startup check
  String? get error => _error;
  UserAccount? get userAccount => _userAccount;
  bool get isUserAccountLoading => _isUserAccountLoading;

  // Add a Completer to signal when the initial auth state check is complete
  final Completer<void> _initialAuthCheckCompleter = Completer<void>();

  AuthProvider(this._apiClient) {
    // Listen to Firebase auth state changes to update current user and fetch user data
    _auth.authStateChanges().listen((fb_auth.User? firebaseUser) async {
      _user = firebaseUser;
      _isLoading = false; // Auth state determined
      _error = null;

      if (firebaseUser != null) {
        _isUserAccountLoading = true;
        // Only notify if we are not already in the middle of a login/signup
        // to avoid redundant rebuilds during the initial sequence.
        // For the initial setup, we notify within the checkCurrentUser.
        if (!_initialAuthCheckCompleter.isCompleted) {
            notifyListeners(); // Notify for _isUserAccountLoading change
        }


        try {
          _userAccount = await _apiClient.getUserById(firebaseUser.uid);
        } catch (e) {
          print('Error fetching user account: $e');
          _userAccount = null;
        } finally {
          _isUserAccountLoading = false;
          // Notify after user account data is fetched
          notifyListeners();
          // Complete the completer once the initial auth state and user data are loaded
          if (!_initialAuthCheckCompleter.isCompleted) {
            _initialAuthCheckCompleter.complete();
          }
        }
      } else {
        _userAccount = null;
        _isUserAccountLoading = false;
        notifyListeners();
        // Complete if no user is found, means initial check is done
        if (!_initialAuthCheckCompleter.isCompleted) {
          _initialAuthCheckCompleter.complete();
        }
      }
    });
  }

  /// NEW METHOD: Ensures the initial Firebase authentication state check is complete.
  /// Used by AppStartupController to await readiness.
  Future<void> checkCurrentUser() async {
    // Wait for the _initialAuthCheckCompleter to complete, which is done
    // by the authStateChanges listener once it processes the initial state.
    await _initialAuthCheckCompleter.future;
  }


  /// Sign in with email and password.
  /// If credentials match dev user, mock login is used.
  /// Otherwise, real Firebase authentication is performed.
  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Dev user credentials — hardcoded for quick dev login
      const devEmail = "dfeen87@brightacts.com";
      const devPassword = "bleigh1!";

      if (email == devEmail && password == devPassword) {
        // Mock user login for dev/testing
        _user = UserMock(email: email);

        _isUserAccountLoading = true;
        notifyListeners();

        try {
          _userAccount = await _apiClient.getUserById(_user!.uid);
        } catch (e) {
          print('Error fetching mock user account: $e');
          _userAccount = null;
        } finally {
          _isUserAccountLoading = false;
          notifyListeners();
        }

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': 'Dev user signed in successfully!'};
      }

      // Normal Firebase sign-in flow
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _user = credential.user;

      _isUserAccountLoading = true;
      notifyListeners();

      _userAccount = await _apiClient.getUserById(_user!.uid);

      _isUserAccountLoading = false;
      _isLoading = false;
      notifyListeners();

      return {'success': true, 'message': 'Signed in successfully!'};
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = _firebaseErrorMessage(e);
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      print('Sign-in Error: $e');
      return {'success': false, 'error': _error};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register new user with email and password using Firebase Auth
  Future<Map<String, dynamic>> signUpWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _user = credential.user;

      // TODO: Optionally send email verification or create user in your backend API

      _isUserAccountLoading = true;
      notifyListeners();

      _userAccount = await _apiClient.getUserById(_user!.uid);

      _isUserAccountLoading = false;
      _isLoading = false;
      notifyListeners();

      return {'success': true, 'message': 'Account created successfully!'};
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = _firebaseErrorMessage(e);
      print('Firebase Sign-Up Error: ${e.code} - ${e.message}');
      return {'success': false, 'error': _error};
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      print('Sign-Up Error: $e');
      return {'success': false, 'error': _error};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signOut();
      _user = null;
      _userAccount = null;
      print('User signed out.');
    } catch (e) {
      _error = 'Failed to sign out: $e';
      print('Sign-out Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to convert Firebase error codes to user-friendly messages
  String _firebaseErrorMessage(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}

/// Mock User class for dev/testing login without Firebase backend
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
  Future<void> sendEmailVerification([fb_auth.ActionCodeSettings? actionCodeSettings]) async {
    print('Mock user sendEmailVerification called.');
  }

  @override
  Future<fb_auth.User> unlink(String providerId) async {
    throw UnimplementedError('unlink not implemented for UserMock.');
  }

  @override
  Future<fb_auth.UserCredential> linkWithProvider(fb_auth.AuthProvider provider) async { // Changed fb_auth_platform_provider.AuthProvider to fb_auth.AuthProvider
    throw UnimplementedError('linkWithProvider not implemented for UserMock.');
  }

  @override
  Future<fb_auth.UserCredential> reauthenticateWithProvider(fb_auth.AuthProvider provider) async { // Changed fb_auth_platform_provider.AuthProvider to fb_auth.AuthProvider
    throw UnimplementedError('reauthenticateWithProvider not implemented for UserMock.');
  }

  @override
  Future<fb_auth.UserCredential> linkWithPopup(fb_auth.AuthProvider provider) async { // Changed fb_auth_platform_provider.AuthProvider to fb_auth.AuthProvider
    throw UnimplementedError('linkWithPopup not implemented for UserMock.');
  }

  @override
  Future<void> linkWithRedirect(fb_auth.AuthProvider provider) async { // Changed fb_auth_platform_provider.AuthProvider to fb_auth.AuthProvider
    throw UnimplementedError('linkWithRedirect not implemented for UserMock.');
  }

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    return 'mock_id_token_${email.hashCode}';
  }

  @override
  Future<void> reload() async {
    print('Mock user reload called.');
  }

  @override
  Future<fb_auth.UserCredential> linkWithCredential(fb_auth.AuthCredential credential) {
    throw UnimplementedError('linkWithCredential not implemented for UserMock.');
  }

  @override
  Future<void> delete() {
    throw UnimplementedError('delete not implemented for UserMock.');
  }

  @override
  Future<void> updateEmail(String newEmail) {
    throw UnimplementedError('updateEmail not implemented for UserMock.');
  }

  @override
  Future<void> updatePassword(String newPassword) {
    throw UnimplementedError('updatePassword not implemented for UserMock.');
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) {
    throw UnimplementedError('updateProfile not implemented for UserMock.');
  }

  @override
  Future<void> updateDisplayName(String? displayName) {
    throw UnimplementedError('updateDisplayName not implemented for UserMock.');
  }

  @override
  Future<void> updatePhotoURL(String? photoURL) {
    throw UnimplementedError('updatePhotoURL not implemented for UserMock.');
  }

  @override
  Future<void> updatePhoneNumber(fb_auth.PhoneAuthCredential credential) {
    throw UnimplementedError('updatePhoneNumber not implemented for UserMock.');
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [fb_auth.ActionCodeSettings? actionCodeSettings]) {
    throw UnimplementedError('verifyBeforeUpdateEmail not implemented for UserMock.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) return null;
    throw UnimplementedError('UserMock: ${invocation.memberName} not implemented');
  }
}

class UserMetadata implements fb_auth.UserMetadata {
  @override
  final DateTime creationTime;

  @override
  final DateTime lastSignInTime;

  UserMetadata({required this.creationTime, required this.lastSignInTime});
}
