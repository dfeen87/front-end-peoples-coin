import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late Timer _timer;
  bool _isVerified = false;
  bool _isLoading = false;
  String? _error;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkVerification();

    // Poll every 3 seconds to check email verification status
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkVerification();
    });
  }

  Future<void> _checkVerification() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user != null && user.emailVerified) {
        if (!mounted) return;
        setState(() {
          _isVerified = true;
        });
        _timer.cancel();
        if (!mounted) return;
        // Navigate to home after verified
        context.go('/home');
      }
    } catch (e) {
      // Log the error but don't show it to the user - it's a background check
      debugPrint('Error checking email verification: $e');
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      setState(() {
        _error = 'Failed to resend verification email: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: Colors.amber[800],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'A verification email has been sent to your email address.\n\nPlease check your inbox and click the verification link.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _resendVerificationEmail,
                  child: const Text('Resend Verification Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Once you have verified your email, this screen will automatically redirect you to the home page.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

