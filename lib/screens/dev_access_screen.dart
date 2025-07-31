import 'dart:async';
import 'dart:js' as js;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/dynamic_nebula_background.dart';

/// A screen for developers to enter an access code with reCAPTCHA v3 validation.
class DevAccessScreen extends StatefulWidget {
  const DevAccessScreen({Key? key}) : super(key: key);

  @override
  State<DevAccessScreen> createState() => _DevAccessScreenState();
}

class _DevAccessScreenState extends State<DevAccessScreen> {
  final TextEditingController _codeController = TextEditingController();
  final String _devAccessCode = 'letmein123';

  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      if (_errorText != null) {
        setState(() {
          _errorText = null;
        });
      }
    });
  }

  /// Executes reCAPTCHA v3 and returns the token.
  Future<String?> _executeRecaptcha() async {
    final grecaptcha = js.context['grecaptcha'];
    if (grecaptcha == null) {
      print('grecaptcha not loaded');
      return null;
    }

    final siteKey = '6LeE0pQrAAAAAML8x8JqtfryKhZ9bpvLRacQzH1F';

    final completer = Completer<String?>();

    try {
      grecaptcha.callMethod('execute', [
        siteKey,
        js.JsObject.jsify({'action': 'access'})
      ]).callMethod('then', [
        (token) {
          completer.complete(token as String);
        },
        (error) {
          print('Recaptcha execute error: $error');
          completer.complete(null);
        }
      ]);
    } catch (e) {
      print('Exception running recaptcha execute: $e');
      completer.complete(null);
    }

    return completer.future;
  }

  /// Validates the entered access code with reCAPTCHA token check.
  Future<void> _validateAccess() async {
    final input = _codeController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorText = 'Please enter the access code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final token = await _executeRecaptcha();

    if (token == null || token.isEmpty) {
      setState(() {
        _errorText = 'reCAPTCHA verification failed. Please try again.';
        _isLoading = false;
      });
      return;
    }

    print('Recaptcha token: $token');

    // TODO: Optionally send token to your backend to verify.

    // Simulate a short delay like real check
    await Future.delayed(const Duration(milliseconds: 500));

    if (input == _devAccessCode) {
      if (mounted) context.go('/welcome');
    } else {
      setState(() {
        _errorText = 'Invalid access code. Please try again.';
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Developer Access',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _codeController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _validateAccess(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Enter Access Code',
                          labelStyle: const TextStyle(color: Colors.white70),
                          errorText: _errorText,
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.amber),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: const Icon(Icons.lock, color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              onPressed: _validateAccess,
                              icon: const Icon(Icons.lock_open),
                              label: const Text('Enter'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                backgroundColor: Colors.amber[800],
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    ],
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

