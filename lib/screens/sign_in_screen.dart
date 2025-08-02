import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../widgets/dynamic_nebula_background.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;
import '../state/user_provider.dart';
import '../service/api_client.dart';
import '../service/recaptcha_service.dart';

// This is the main widget class that was missing
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() => _error = null));
    _passwordController.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      print("[SIGN-IN DEBUG] $message");
    }
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = context.read<PeoplesCoinApiClient>();

      _logDebug("Requesting PoW challenge...");
      final challengeData = await apiClient.getPowChallenge();
      final challenge = challengeData['challenge'] as String;

      _logDebug("Solving PoW challenge...");
      String nonce = '';
      for (int i = 0;; i++) {
        final attempt = '$challenge$i';
        final hash = sha256.convert(utf8.encode(attempt)).toString();
        if (hash.startsWith('0000')) {
          nonce = i.toString();
          break;
        }
      }

      _logDebug("Verifying PoW with backend...");
      await apiClient.verifyPow(challenge: challenge, nonce: nonce);

      _logDebug("Executing reCAPTCHA...");
      final recaptchaToken = await executeRecaptcha(dotenv.env['RECAPTCHA_SITE_KEY_PROD']!, 'signin');
      if (recaptchaToken.isEmpty && kReleaseMode) throw Exception('Failed to get reCAPTCHA token.');

      _logDebug("Validating reCAPTCHA token...");
      await apiClient.verifyRecaptchaToken(recaptchaToken);

      _logDebug("Signing in with Firebase...");
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final authProvider = context.read<MyAppAuthProvider.AuthProvider>();
      await authProvider.checkCurrentUser();

      if (authProvider.user != null) {
        final userId = authProvider.user!.uid;
        _logDebug("Fetching user profile for UID: $userId");
        await context.read<UserProvider>().fetchUser(userId);
        if (mounted) context.go('/home');
      } else {
        throw Exception("Sign-in succeeded but user data is missing.");
      }
    } on ApiException catch (e) {
      _logDebug("ApiException: $e");
      setState(() => _error = e.message);
    } on NetworkException catch (e) {
      _logDebug("NetworkException: $e");
      setState(() => _error = e.message);
    } on FirebaseAuthException catch (e) {
      _logDebug("FirebaseAuthException: ${e.code}");
      setState(() {
        _error = switch (e.code) {
          'user-not-found' || 'invalid-credential' => 'No account found or incorrect password.',
          'wrong-password' => 'Incorrect password.',
          'invalid-email' => 'The email address is badly formatted.',
          _ => 'Sign-in error. Please try again.'
        };
      });
    } catch (e) {
      _logDebug("General exception: $e");
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address first.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset link: $e')),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.blueGrey[200]),
      prefixIcon: Icon(icon, color: Colors.blueGrey[300], size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueGrey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordVisibilityToggle = IconButton(
      icon: Icon(
        _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
        color: Colors.blueGrey[300],
      ),
      onPressed: () {
        setState(() {
          _isPasswordObscured = !_isPasswordObscured;
        });
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  color: Colors.blueGrey[900]?.withOpacity(0.6),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.blueGrey[800]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                              ),
                            ),
                          TextFormField(
                            controller: _emailController,
                            decoration: _buildInputDecoration('Email', Icons.alternate_email),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) =>
                                (val?.contains('@') ?? false) ? null : 'Please enter a valid email',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isPasswordObscured,
                            decoration: _buildInputDecoration(
                              'Password',
                              Icons.lock_outline,
                              suffixIcon: passwordVisibilityToggle,
                            ),
                            validator: (val) =>
                                (val?.isNotEmpty ?? false) ? null : 'Please enter your password',
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(color: Colors.amber[600]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.amber[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _signIn,
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
