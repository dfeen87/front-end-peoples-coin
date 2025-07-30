import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../recaptcha_helper.dart'; // For v3 helper
import '../widgets/dynamic_nebula_background.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;
import '../state/user_provider.dart';

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

  // Define your reCAPTCHA v3 site key here for consistency
  // Make sure this matches the key in web/index.html and your build command
  static const String recaptchaV3SiteKey = '6LeE0pQrAAAAAML8x8JqtfryKhZ9bpvLRacQzH1F'; // <--- Your chosen V3 Public Site Key

  @override
  void initState() {
    super.initState();
    // Initialize reCAPTCHA v3 when the screen loads
    initializeRecaptchaV3(); 

    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_error != null) {
      setState(() {
        _error = null;
      });
    }
  }

  // This is the ONLY dispose method that should be in this class
  @override
  void dispose() { 
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Step 1: Get the invisible v3 token.
      final recaptchaToken = await getRecaptchaToken(recaptchaV3SiteKey, 'login'); 

      // Step 2: Send token to your backend. Your backend MUST check the score.
      final response = await http.post(
        Uri.parse('https://peoples-coin-service-105378934751.us-central1.run.app/api/verify_login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': recaptchaToken}),
      );

      if (response.statusCode == 200) { 
        // Step 3: Proceed with Firebase sign-in.
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        final authProvider = context.read<MyAppAuthProvider.AuthProvider>();
        await authProvider.checkCurrentUser();

        if (authProvider.user != null) {
          await context.read<UserProvider>().fetchUser(authProvider.user!.uid);
          context.go('/home');
        } else {
          throw Exception("Failed to update auth state after sign-in.");
        }
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody['error'] ?? 'reCAPTCHA verification failed or an unknown backend error occurred.');
      }
    } on FirebaseAuthException catch (e) {
      _error = 'Incorrect email or password.';
      if (mounted) setState(() {});
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        SnackBar(content: Text('Failed to send reset link: ${e.toString()}')),
      );
    }
  }

  // --- ADDED THIS MISSING METHOD ---
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
  // --- END OF ADDED METHOD ---

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
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Email', Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) =>
                                  val != null && val.contains('@') ? null : 'Please enter a valid email',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('Password', Icons.lock_outline),
                              obscureText: true,
                              validator: (val) => val != null && val.isNotEmpty ? null : 'Please enter your password',
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
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _signIn,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.amber[800],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Sign In', style: TextStyle(fontSize: 16)),
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
