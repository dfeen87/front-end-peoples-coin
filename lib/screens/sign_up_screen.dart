import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../widgets/dynamic_nebula_background.dart';
import '../service/api_client.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  Timer? _debounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged() {
    // You can implement debounce logic here if you want username availability check
    // For now leaving it empty or implement your logic
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid form
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;

      if (user != null && mounted) {
        // Call your backend API client to create the user account record
        await context.read<PeoplesCoinApiClient>().createUserAccount(
              firebaseUid: user.uid,
              email: user.email!,
              username: _usernameController.text.trim(),
            );

        // Navigate to home screen after success
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to create account.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      }

      if (mounted) {
        setState(() {
          _error = errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Google Sign-In for Flutter Web
  Future<void> _signInWithGoogle() async {
    print("Google Sign-In button pressed");
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      final User? user = userCredential.user;

      if (user != null && mounted) {
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await context.read<PeoplesCoinApiClient>().createUserAccount(
                firebaseUid: user.uid,
                email: user.email!,
                username: user.displayName ?? user.email!.split('@')[0],
              );
        }
        context.go('/home');
      }
    } catch (e) {
      print("Google Sign-In error: $e");
      if (mounted) {
        setState(() {
          _error = 'Google Sign-In failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amber)),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
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
    );
  }

  Widget? _buildUsernameSuffixIcon() {
    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child:
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_isUsernameAvailable != null) {
      return Icon(
        _isUsernameAvailable! ? Icons.check_circle_outline : Icons.error_outline,
        color: _isUsernameAvailable! ? Colors.greenAccent : Colors.redAccent,
      );
    }
    return null;
  }

  Widget _buildSocialButton({VoidCallback? onPressed, required String asset}) {
    return Material(
      color: Colors.white.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Image.asset(asset, height: 32),
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
                            const Text('Create Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 8),
                            const Text('Join the Bright Acts community.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70, fontSize: 16)),
                            const SizedBox(height: 24),
                            if (_error != null) ...[
                              _buildErrorWidget(),
                              const SizedBox(height: 16)
                            ],
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.text,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Username',
                                  Icons.person_outline,
                                  suffixIcon: _buildUsernameSuffixIcon()),
                              validator: (val) {
                                if (val == null || val.trim().length < 3) {
                                  return 'Username must be at least 3 characters.';
                                }
                                if (_isUsernameAvailable == false) {
                                  return 'This username is already taken.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration:
                                  _buildInputDecoration('Email', Icons.email_outlined),
                              validator: (val) {
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (val == null || !emailRegex.hasMatch(val)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Password',
                                  Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70),
                                    onPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                  )),
                              validator: (val) =>
                                  val != null && val.length >= 6
                                      ? null
                                      : 'Password must be at least 6 characters',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Confirm Password',
                                  Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70),
                                    onPressed: () => setState(
                                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  )),
                              validator: (val) => val != _passwordController.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _signUp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber[800],
                                      foregroundColor: Colors.black,
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Create Account',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.3))),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('OR',
                                      style: TextStyle(color: Colors.white70)),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.3))),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: _buildSocialButton(
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                asset: 'assets/google_logo.png',
                              ),
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
                                      style: TextStyle(
                                          color: Colors.amber[400],
                                          fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => context.go('/sign_in'),
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

