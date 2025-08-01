import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../widgets/dynamic_nebula_background.dart';
import '../service/api_client.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _error;

  Timer? _debounceTimer;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String username) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    // Clear status if username becomes too short
    if (username.length < 3) {
      setState(() => _isUsernameAvailable = null);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isCheckingUsername = true;
        _isUsernameAvailable = null;
      });
      
      try {
        final apiClient = context.read<PeoplesCoinApiClient>();
        final isAvailable = await apiClient.checkUsernameAvailability(username);
        if (!mounted) return;
        setState(() => _isUsernameAvailable = isAvailable);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isUsernameAvailable = false); // Treat error as unavailable
        if (kDebugMode) print('Username check error: $e');
      } finally {
        if (!mounted) return;
        setState(() => _isCheckingUsername = false);
      }
    });
  }

  Future<void> _signUp() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Prevent submission if username is known to be unavailable
    if (_isUsernameAvailable == false) {
      _formKey.currentState?.validate(); // Re-run validation to show error
      return;
    }

    // Validate the form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await userCredential.user?.updateDisplayName(_usernameController.text.trim());
      
      // TODO: Here you would also call your backend to create a user profile in your database
      // with the UID and selected username.

      if (mounted) context.go('/home');

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      setState(() => _error = message);
      if (kDebugMode) print('Firebase Auth Error: ${e.message}');
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
      if (kDebugMode) print('Generic Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 24),
                            _buildErrorWidget(),
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                'Username',
                                Icons.person_outline,
                                suffixIcon: _isCheckingUsername
                                  ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                  : _isUsernameAvailable == false
                                    ? const Icon(Icons.error, color: Colors.red)
                                    : _isUsernameAvailable == true
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : null,
                              ),
                              onChanged: _onUsernameChanged,
                              validator: (val) {
                                if (val == null || val.trim().length < 3) {
                                  return 'Username must be at least 3 characters.';
                                }
                                if (_isUsernameAvailable == false) {
                                  return 'Username is already taken.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Email', Icons.email_outlined),
                              validator: (val) {
                                final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                                if (val == null || !emailRegex.hasMatch(val)) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                'Password',
                                Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                'Confirm Password',
                                Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please confirm your password.';
                                }
                                if (val != _passwordController.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _signUp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber[800],
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                            const SizedBox(height: 20),
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: const TextStyle(color: Colors.white70),
                                  children: [
                                    TextSpan(
                                      text: 'Sign In',
                                      style: TextStyle(color: Colors.amber[400], fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          if (!_isLoading) context.go('/sign_in');
                                        },
                                    ),
                                  ],
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
          ),
        ],
      ),
    );
  }
}
