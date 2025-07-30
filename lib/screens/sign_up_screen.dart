import 'dart:async';
import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Essential for Firebase Authentication
import 'package:go_router/go_router.dart'; // For navigation
import 'package:provider/provider.dart'; // For accessing API client

// Removed google_sign_in import as it's no longer used
// Removed flutter/foundation.dart kIsWeb import as it's not needed without Google Sign-In specific web logic here

// Import your project-specific files
import '../widgets/dynamic_nebula_background.dart';
import '../service/api_client.dart'; // Ensure this path is correct

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
  String? _error; // To display error messages to the user

  // Removed GoogleSignIn instance as it's no longer used
  // final GoogleSignIn _googleSignIn = ...;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // First, validate all form fields. If validation fails, stop.
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _error = 'Please correct the errors in the form.';
      });
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
      _error = null;      // Clear previous errors
    });

    try {
      // Attempt to create a user with email and password using Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;

      if (user != null) {
        // Update Firebase user's display name with the provided username
        await user.updateDisplayName(_usernameController.text.trim());

        // Create user account in your backend API
        // Ensure the context is still valid before using it after an await
        if (mounted) {
          await context.read<PeoplesCoinApiClient>().createUserAccount(
                firebaseUid: user.uid,
                email: user.email!,
                username: _usernameController.text.trim(), // Pass the username to your API
              );
        }

        // Navigate to the home screen on successful signup
        if (!mounted) return; // Check mounted again before navigation
        context.go('/home'); 

      }
    } on FirebaseAuthException catch (e) {
      // Catch specific Firebase Authentication errors
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = e.message ?? 'An unknown Firebase error occurred. Please try again.';
      }
      setState(() {
        _error = errorMessage;
      });
    } catch (e) {
      // Catch any other unexpected errors
      setState(() {
        _error = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      // Always stop loading, regardless of success or failure
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper method to build consistent input field decorations
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

  // Helper method to display error messages
  Widget _buildErrorWidget() {
    if (_error == null || _error!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Add some spacing below the error
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

  // Removed _buildSocialButton as Google Sign-In is removed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background is handled by DynamicNebulaBackground
      body: Stack(
        children: [
          // Dynamic Nebula Background (assuming it's positioned to fill the screen)
          const DynamicNebulaBackground(), 
          
          // Centered content for the signup form
          Center(
            child: SingleChildScrollView( // Allows scrolling if keyboard overlaps fields
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400), // Max width for desktop/web
                child: ClipRRect( // Clip to apply border radius before blur
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter( // Apply blur effect to content behind
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4), // Semi-transparent background
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)), // Subtle white border
                      ),
                      child: Form(
                        key: _formKey, // Associate form key for validation
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
                            const SizedBox(height: 8),
                            const Text(
                              'Join the Bright Acts community.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildErrorWidget(), // Display error messages here
                            
                            // Username Input Field
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.text,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Username', Icons.person_outline),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Username cannot be empty.';
                                }
                                if (val.trim().length < 3) {
                                  return 'Username must be at least 3 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Email Input Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Email', Icons.email_outlined),
                              validator: (val) {
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (val == null || !emailRegex.hasMatch(val)) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Input Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                'Password',
                                Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (val) =>
                                  val != null && val.length >= 6 ? null : 'Password must be at least 6 characters.',
                            ),
                            const SizedBox(height: 16),
                            
                            // Confirm Password Input Field
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                'Confirm Password',
                                Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white70,
                                  ),
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
                            
                            // Sign Up Button (shows loading indicator when active)
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _signUp, // Calls the signup logic
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber[800],
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text(
                                      'Create Account',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                            
                            // Removed the "OR" divider and social login buttons
                            // as Google Sign-In is no longer used.

                            const SizedBox(height: 20),
                            
                            // Link to Sign In page
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: const TextStyle(color: Colors.white70),
                                  children: [
                                    TextSpan(
                                      text: 'Sign In',
                                      style: TextStyle(
                                        color: Colors.amber[400],
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          if (!_isLoading) { // Prevent navigation while loading
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
