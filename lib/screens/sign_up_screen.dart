import 'dart:async'; // For Timer and debounce

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../service/api_client.dart';
import '../service/recaptcha_service.dart';
import '../widgets/dynamic_nebula_background.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _usernameAvailable = false;
  bool _checkingUsername = false;
  bool _isPasswordObscured = true;

  Timer? _debounceTimer; // For debounce

  static const String recaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
    defaultValue: '',
  );

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged() {
    // Cancel previous timer if still active
    _debounceTimer?.cancel();

    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUsername();
    });
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      if (mounted) {
        setState(() {
          _usernameAvailable = false;
          _checkingUsername = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _checkingUsername = true);

    try {
      final apiClient = context.read<PeoplesCoinApiClient>();
      final available = await apiClient.checkUsernameAvailability(username);
      if (mounted) {
        setState(() {
          _usernameAvailable = available;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Username check error: $e');
      if (mounted) {
        setState(() {
          _usernameAvailable = false;
        });
      }
    } finally {
      if (mounted) setState(() => _checkingUsername = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _signUpWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_usernameAvailable) {
      _showError('Username is not available.');
      return;
    }

    if (recaptchaSiteKey.isEmpty && kReleaseMode) {
      _showError('reCAPTCHA site key not configured.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await executeRecaptcha(recaptchaSiteKey, 'signup');

      if (token.isEmpty && kReleaseMode) {
        throw Exception('Failed to get reCAPTCHA token.');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        final apiClient = context.read<PeoplesCoinApiClient>();
        await apiClient.createUserAccount(
          firebaseUid: user.uid,
          email: user.email ?? '',
          username: _usernameController.text.trim(),
        );
      }

      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      final friendlyMessage = switch (e.code) {
        'email-already-in-use' => 'This email is already registered.',
        'weak-password' => 'The password is too weak.',
        'invalid-email' => 'Invalid email format.',
        _ => 'Sign-up error: ${e.message}'
      };
      _showError(friendlyMessage);
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            decoration: _buildInputDecoration(
                                'Email', Icons.alternate_email),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) => (val?.contains('@') ?? false)
                                ? null
                                : 'Please enter a valid email',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            decoration: _buildInputDecoration(
                                'Username', Icons.person_outline),
                            validator: (val) =>
                                (val?.trim().isNotEmpty ?? false)
                                    ? null
                                    : 'Please enter a username',
                          ),
                          const SizedBox(height: 8),
                          _buildUsernameAvailabilityIndicator(),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isPasswordObscured,
                            decoration: _buildInputDecoration(
                              'Password',
                              Icons.lock_outline,
                              suffixIcon: passwordVisibilityToggle,
                            ),
                            validator: (val) => (val?.length ?? 0) >= 6
                                ? null
                                : 'Password must be at least 6 characters',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _isPasswordObscured,
                            decoration: _buildInputDecoration(
                              'Confirm Password',
                              Icons.lock_person_outlined,
                              suffixIcon: passwordVisibilityToggle,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (val != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  backgroundColor: Colors.amber[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _signUpWithEmail,
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
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

  Widget _buildUsernameAvailabilityIndicator() {
    if (_checkingUsername) {
      return const LinearProgressIndicator(minHeight: 2, color: Colors.amber);
    }
    if (_usernameController.text.trim().isEmpty) {
      return const SizedBox(height: 18); // Maintain consistent space
    }
    return SizedBox(
      height: 18, // Fixed height to prevent layout jumps
      child: Row(
        children: [
          Icon(
            _usernameAvailable ? Icons.check_circle : Icons.error,
            color: _usernameAvailable ? Colors.greenAccent : Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _usernameAvailable ? 'Username available' : 'Username not available',
            style: TextStyle(
              color:
                  _usernameAvailable ? Colors.greenAccent : Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

