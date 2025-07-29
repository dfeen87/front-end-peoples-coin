// lib/screens/verify_phone_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyPhoneScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String username;
  final String email;
  final String phoneNumber;

  const VerifyPhoneScreen({
    super.key,
    required this.verificationId,
    required this.username,
    required this.email,
    required this.phoneNumber,
  });

  @override
  ConsumerState<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends ConsumerState<VerifyPhoneScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  bool get _isOtpValid => _otpController.text.trim().length == 6;

  Future<void> _verifyOtpAndFinishSignUp() async {
    if (!_isOtpValid) {
      setState(() => _error = 'Please enter a 6-digit code.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user is signed in to link phone.");

      await user.linkWithCredential(credential);

      // TODO: Call your backend API here if you want to finalize user creation

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created and phone verified!')),
        );
      }

      // Your app's navigation or AuthGate will handle routing after this

    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = 'Verification Failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _error = 'Verification Failed: $e';
      });
    } finally {
      if (mounted) setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'OTP Code',
                errorText: _error,
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _isOtpValid ? _verifyOtpAndFinishSignUp : null,
                    child: const Text('Verify & Finish'),
                  ),
          ],
        ),
      ),
    );
  }
}

