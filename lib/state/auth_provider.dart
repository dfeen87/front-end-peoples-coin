import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_auth_platform_interface/src/auth_provider.dart' as fb_auth_platform_provider;

import '../models/user_account.dart';
import '../service/api_client.dart';

/// Manages user authentication state using Firebase Auth and integrates with reCAPTCHA Enterprise.
/// Also handles fetching the associated UserAccount data immediately upon successful authentication.
class AuthProvider with ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  fb_auth.User? _user;
  bool _isLoading = false;
  String? _error;

  UserAccount? _userAccount;
  bool _isUserAccountLoading = false;

  final PeoplesCoinApiClient _apiClient;

  fb_auth.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserAccount? get userAccount => _userAccount;
  bool get isUserAccountLoading => _isUserAccountLoading;

  AuthProvider(this._apiClient) {
    _auth.authStateChanges().listen((fb_auth.User? firebaseUser) async {
      _user = firebaseUser;
      _isLoading = false;
      _error = null;

      if (firebaseUser != null) {
        _isUserAccountLoading = true;
        notifyListeners();

        try {
          // Fetch UserAccount from API using firebaseUser.uid
          _userAccount = await _apiClient.getUserById(firebaseUser.uid);
        } catch (e) {
          print('Error fetching user account: $e');
          _userAccount = null;
        } finally {
          _isUserAccountLoading = false;
          notifyListeners();
        }
      } else {
        _userAccount = null;
        _isUserAccountLoading = false;
        notifyListeners();
      }
    });
  }

  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mock reCAPTCHA token (replace with actual implementation if needed)
      final String recaptchaToken = 'mock_recaptcha_token_${DateTime.now().millisecondsSinceEpoch}';
      print('reCAPTCHA token obtained (mocked for web): $recaptchaToken');

      // Mock sign-in for your specific test account
      if (email == "dfeen87@brightacts.com" && password == "bleigh1!") {
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
        }

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': 'Signed in successfully!'};
      } else {
        throw fb_auth.FirebaseAuthException(code: 'user-not-found', message: 'Invalid credentials.');
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = e.message;
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
}

/// Mock User class for testing login without Firebase backend
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
  Future<fb_auth.UserCredential> linkWithProvider(fb_auth_platform_provider.AuthProvider provider) async {
    throw UnimplementedError('linkWithProvider not implemented for UserMock.');
  }

  @override
  Future<fb_auth.UserCredential> reauthenticateWithProvider(fb_auth_platform_provider.AuthProvider provider) async {
    throw UnimplementedError('reauthenticateWithProvider not implemented for UserMock.');
  }

  @override
  Future<fb_auth.UserCredential> linkWithPopup(fb_auth_platform_provider.AuthProvider provider) async {
    throw UnimplementedError('linkWithPopup not implemented for UserMock.');
  }

  @override
  Future<void> linkWithRedirect(fb_auth_platform_provider.AuthProvider provider) async {
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
    print('UserMock: noSuchMethod called for ${invocation.memberName}');
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

