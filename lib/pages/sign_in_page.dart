import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Import dotenv
import 'dart:ui'; // For BackdropFilter

import '../widgets/dynamic_nebula_background.dart';

class DevAccessScreen extends StatefulWidget {
  const DevAccessScreen({Key? key}) : super(key: key);

  @override
  State<DevAccessScreen> createState() => _DevAccessScreenState();
}

class _DevAccessScreenState extends State<DevAccessScreen> {
  final TextEditingController _codeController = TextEditingController();
  
  // Load credentials securely from the .env file; no hardcoded fallback
  final String? _devAccessCode = dotenv.env['DEV_ACCESS_CODE'];

  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_devAccessCode == null || _devAccessCode!.isEmpty) {
      _errorText = 'Dev access not configured. Set DEV_ACCESS_CODE in your environment.';
    }
    _codeController.addListener(() {
      // Only clear validation errors (invalid code), not configuration errors
      if (_errorText != null && (_devAccessCode?.isNotEmpty ?? false)) {
        setState(() => _errorText = null);
      }
    });
  }

  void _validateAccess() {
    if (_devAccessCode == null || _devAccessCode!.isEmpty) {
      setState(() {
        _errorText = 'Dev access not configured. Set DEV_ACCESS_CODE in your environment.';
      });
      return;
    }

    setState(() => _isLoading = true);
    
    // Add a small delay to simulate a network call and improve UX
    Future.delayed(const Duration(milliseconds: 500), () {
      final input = _codeController.text.trim();
      if (input == _devAccessCode) {
        // Use go_router for navigation
        context.go('/sign_in');
      } else {
        setState(() {
          _errorText = 'Invalid access code. Please try again.';
          _isLoading = false;
        });
      }
    });
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Developer Access',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This area is restricted. Please enter the access code to proceed.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          if (_errorText != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                _errorText!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          TextField(
                            controller: _codeController,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 3),
                            decoration: InputDecoration(
                              labelText: 'Access Code',
                              labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 1),
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.amber),
                              ),
                            ),
                            onSubmitted: (_) => _validateAccess(),
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                              : ElevatedButton.icon(
                                  onPressed: _validateAccess,
                                  icon: const Icon(Icons.lock_open_rounded),
                                  label: const Text('ENTER'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: Colors.amber[800],
                                    foregroundColor: Colors.black,
                                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            ),
          ),
        ],
      ),
    );
  }
}

