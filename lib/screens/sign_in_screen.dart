// lib/screens/sign_in_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

import '../widgets/dynamic_nebula_background.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;
import '../state/user_provider.dart';
import '../service/api_client.dart';

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

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      print("[DEBUG] $message");
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final apiClient = context.read<PeoplesCoinApiClient>();

    try {
      // Step 1: Proof-of-Work Challenge
      _logDebug("Requesting PoW challenge...");
      final challengeData = await apiClient.getPowChallenge();
      final challenge = challengeData['challenge'] as String;

      // Simple PoW simulation
      _logDebug("Solving PoW challenge...");
      String nonce = '';
      String hash = '';
      for (int i = 0;; i++) {
        final attempt = '$challenge$i';
        hash = sha256.convert(utf8.encode(attempt)).toString();
        if (hash.startsWith('0000')) {
          nonce = i.toString();
          break;
        }
      }

      // Step 2: Verify PoW with backend
      _logDebug("Verifying PoW with backend...");
      await apiClient.verifyPow(challenge: challenge, nonce: nonce);

      // Step 3: Firebase Auth Sign-in
      _logDebug("Signing in with Firebase...");
      final userCredential =
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
        _logDebug("User profile fetch successful.");

        if (mounted) context.go('/home');
      } else {
        throw Exception(
            "Sign-in succeeded but user data is missing in AuthProvider.");
      }
    } on ApiException catch (e) {
      _logDebug("ApiException: $e");
      setState(() => _error = e.message);
    } on NetworkException catch (e) {
      _logDebug("NetworkException: $e");
      setState(() => _error = e.message);
    } on FirebaseAuthException catch (e) {
      _logDebug("FirebaseAuthException caught: ${e.code} - ${e.message}");
      if (e.code == 'user-not-found') {
        _error = 'No account found for this email.';
      } else if (e.code == 'wrong-password') {
        _error = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        _error = 'The email address is badly formatted.';
      } else {
        _error = 'Sign-in error: ${e.message}';
      }
    } catch (e) {
      _logDebug("General exception during sign-in: $e");
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address first.'),
          backgroundColor: Colors.redAccent,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                  'Email', Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) => val != null && val.contains('@')
                                  ? null
                                  : 'Please enter a valid email',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                  'Password', Icons.lock_outline),
                              obscureText: true,
                              validator: (val) =>
                                  val != null && val.isNotEmpty
                                      ? null
                                      : 'Please enter your password',
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
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _signIn,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      backgroundColor: Colors.amber[800],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Sign In',
                                        style: TextStyle(fontSize: 16)),
                                  ),
                          ],
                        ),
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

