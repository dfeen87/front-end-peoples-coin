import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dart:js_util' as js_util;

import '../service/api_client.dart';
import '../widgets/dynamic_nebula_background.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiClient = PeoplesCoinApiClient();

  bool _isLoading = false;
  String? _error;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if grecaptcha is loaded
      final hasRecaptcha = js_util.hasProperty(js_util.globalThis, 'grecaptcha');
      if (!hasRecaptcha) {
        throw Exception('reCAPTCHA not loaded on the page.');
      }

      // Call grecaptcha.execute (not enterprise.execute)
      final recaptchaToken = await js_util.promiseToFuture<String>(
        js_util.callMethod(js_util.getProperty(js_util.globalThis, 'grecaptcha'), 'execute', [
          'YOUR_RECAPTCHA_SITE_KEY_HERE', // Replace with your actual site key
          {'action': 'login'},
        ]),
      );

      // Optionally: send recaptchaToken to your backend for verification
      // await _apiClient.verifyRecaptchaToken(recaptchaToken);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _error = 'Incorrect email or password.';
      } else {
        _error = 'An error occurred. Please try again.';
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'An unexpected error occurred: ${e.toString()}');
      }
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
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset link sent to your email.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset link: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      ),
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              decoration: _buildInputDecoration('Email', Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) => val != null && val.contains('@') ? null : 'Please enter a valid email',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
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

