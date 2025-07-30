import 'dart:async';
import 'dart:convert'; // For jsonEncode
import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http; // For making API calls

// Import your project-specific files
import '../recaptcha_helper.dart'; // Import the updated v3 helper
import '../widgets/dynamic_nebula_background.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _error;

  // Define your reCAPTCHA v3 site key here for consistency
  // Make sure this matches the key in web/index.html and your build command
  static const String recaptchaV3SiteKey = '6LeE0pQrAAAAAML8x8JqtfryKhZ9bpvLRacQzH1F'; // <--- Your chosen V3 Public Site Key

  @override
  void initState() {
    super.initState();
    // Initialize reCAPTCHA v3 when the screen loads
    initializeRecaptchaV3(); // Call the initialization function

    _usernameController.addListener(_clearError);
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _confirmPasswordController.addListener(_clearError);
  }

  void _clearError() {
    if (_error != null) {
      setState(() {
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // UPDATED _signUp function for reCAPTCHA v3
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Step 1: Get the reCAPTCHA v3 token.
      // The 'signup' action helps Google analyze user behavior specifically for signup.
      final String recaptchaToken = await getRecaptchaToken(recaptchaV3SiteKey, 'signup');
      print('reCAPTCHA v3 token: $recaptchaToken');


      // Step 2: Send user details and token to your backend.
      // The backend will verify reCAPTCHA and then create the user.
      final response = await http.post(
        Uri.parse('https://peoples-coin-service-105378934751.us-central1.run.app/api/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'token': recaptchaToken, // Send the v3 token
        }),
      );

      if (response.statusCode == 200) {
        // Backend confirmed success. The user is created.
        // Now, sign in the user on the client to update the app state.
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (mounted) {
          context.go('/home');
        }
      } else {
        // Handle error from the backend
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody['error'] ?? 'An unknown error occurred during sign-up.');
      }

    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
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
    if (_error == null || _error!.isEmpty) return const SizedBox.shrink();

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
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildErrorWidget(),
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Username', Icons.person_outline),
                              validator: (val) => val != null && val.trim().length >= 3 ? null : 'Username must be at least 3 characters.',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Email', Icons.email_outlined),
                              validator: (val) => val != null && val.contains('@') ? null : 'Enter a valid email address.',
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
                              validator: (val) => val != null && val.length >= 6 ? null : 'Password must be at least 6 characters.',
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
                              validator: (val) => val == _passwordController.text ? null : 'Passwords do not match.',
                            ),
                            const SizedBox(height: 24),
                            // Removed RecaptchaV2Widget
                            const SizedBox(height: 24), // Keep spacing consistent
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
                                          if (!_isLoading) {
                                            context.go('/sign_in');
                                          }
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
