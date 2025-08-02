import 'package:flutter/gestures.dart';  
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../service/api_client.dart';
import '../service/recaptcha_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _usernameAvailable = false;
  bool _checkingUsername = false;
  String? _recaptchaToken;

  // IMPORTANT: Use your actual site key here or load from env
  static const String recaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
    defaultValue: '',
  );

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_checkUsername);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _usernameAvailable = false;
        _checkingUsername = false;
      });
      return;
    }
    setState(() {
      _checkingUsername = true;
    });
    try {
      final apiClient = context.read<PeoplesCoinApiClient>();
      final available = await apiClient.checkUsernameAvailability(username);
      if (mounted) {
        setState(() {
          _usernameAvailable = available;
          _checkingUsername = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Username check error: $e');
      if (mounted) {
        setState(() {
          _usernameAvailable = false;
          _checkingUsername = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _onRecaptchaCompleted(String token) async {
    if (kDebugMode) print('reCAPTCHA token: $token');
    _recaptchaToken = token;
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_usernameAvailable) {
      _showError('Username is not available.');
      return;
    }

    // Run reCAPTCHA v3 verification first
    final token = await executeRecaptcha(recaptchaSiteKey, 'signup');

    if (recaptchaSiteKey.isEmpty) {
      _showError('reCAPTCHA site key not configured.');
      return;
    }
    
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
    // Get the reCAPTCHA token with your new async wrapper function
    final token = await executeRecaptcha(recaptchaSiteKey, 'signup');

      if (token.isEmpty) {
        throw Exception('Failed to get reCAPTCHA token.');
      }

      // Create Firebase user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        final apiClient = context.read<PeoplesCoinApiClient>();

        // Pass the recaptchaToken to your backend for validation
        await apiClient.createUserAccount(
          firebaseUid: user.uid,
          email: user.email ?? '',
          username: _usernameController.text.trim(),
        );
      }

      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError('This email is already registered.');
      } else if (e.code == 'weak-password') {
        _showError('The password is too weak.');
      } else if (e.code == 'invalid-email') {
        _showError('Invalid email format.');
      } else {
        _showError('Sign-up error: ${e.message}');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _showError("Google sign-in aborted.");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final apiClient = context.read<PeoplesCoinApiClient>();

        // Create account if needed, username empty for now
        await apiClient.createUserAccount(
          firebaseUid: user.uid,
          email: user.email ?? '',
          username: '',
          // You can also pass a recaptchaToken if you want to verify here too
        );
      }

      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return GestureDetector(
      onTap: _signInWithGoogle,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
              height: 20,
              width: 20,
            ),
            const SizedBox(width: 10),
            const Text(
              'Sign up with Google',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.grey.shade400, thickness: 1),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'OR',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.grey.shade400, thickness: 1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Card(
          color: Colors.white.withOpacity(0.95),
          elevation: 6,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sign Up', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: _buildInputDecoration('Email', Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                          val != null && val.contains('@') ? null : 'Please enter a valid email',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _buildInputDecoration('Password', Icons.lock_outline),
                      validator: (val) =>
                          val != null && val.length >= 6 ? null : 'Password must be at least 6 characters',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      decoration: _buildInputDecoration('Username', Icons.person_outline),
                      validator: (val) =>
                          val != null && val.trim().isNotEmpty ? null : 'Please enter a username',
                    ),
                    const SizedBox(height: 4),
                    if (_checkingUsername)
                      const LinearProgressIndicator(minHeight: 4)
                    else if (_usernameController.text.trim().isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            _usernameAvailable ? Icons.check_circle : Icons.error,
                            color: _usernameAvailable ? Colors.green : Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _usernameAvailable ? 'Username available' : 'Username not available',
                            style: TextStyle(
                              color: _usernameAvailable ? Colors.green : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            children: [
                              ElevatedButton(
                                onPressed: _signUpWithEmail,
                                child: const Text('Sign Up'),
                              ),
                              _buildOrDivider(),
                              _buildGoogleSignInButton(),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

