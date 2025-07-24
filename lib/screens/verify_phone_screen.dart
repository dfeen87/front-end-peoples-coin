// lib/screens/verify_phone_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../state/auth_provider.dart'; // Using the correct path to your provider in 'state'

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

  Future<void> _verifyOtpAndFinishSignUp() async {
    if (_otpController.text.isEmpty) return;
    setState(() { _isLoading = true; });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user is signed in to link phone.");
      
      await user.linkWithCredential(credential);

      // This should call your backend API to create the user in your database
      // You'll need to implement this logic in your AuthProvider or ApiService
      // final authProvider = ref.read(authProvider);
      // await authProvider.createUserInDatabase( ... );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created and verified!')),
      );

      // The AuthGate will handle navigation automatically

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
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
            Text('Enter the 6-digit code sent to ${widget.phoneNumber}', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'OTP Code'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _verifyOtpAndFinishSignUp,
                    child: const Text('Verify & Finish'),
                  ),
          ],
        ),
      ),
    );
  }
}
