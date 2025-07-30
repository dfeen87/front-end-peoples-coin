import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/dynamic_nebula_background.dart';

/// A screen for developers to enter an access code.
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

  /// Validates the entered access code without reCAPTCHA.
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

    // Simulate a short delay to feel like a real check
    await Future.delayed(const Duration(milliseconds: 500));

    // Proceed only if code matches
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
      backgroundColor: Colors.transparent, // transparent for nebula background
      body: Stack(
        children: [
          const DynamicNebulaBackground(), // Background visual
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                color: Colors.black.withOpacity(0.7), // Semi-transparent card background
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
                          color: Colors.amber, // Highlight color
                          fontFamily: 'monospace', // Techy font
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _codeController,
                        obscureText: true, // Hide input for security
                        textInputAction: TextInputAction.done, // 'Done' button on keyboard
                        onSubmitted: (_) => _validateAccess(), // Validate on submit
                        style: const TextStyle(color: Colors.white), // Input text color
                        decoration: InputDecoration(
                          labelText: 'Enter Access Code',
                          labelStyle: const TextStyle(color: Colors.white70),
                          errorText: _errorText, // Display error message
                          filled: true,
                          fillColor: Colors.white10, // Light fill for text field
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.amber), // Highlight on focus
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: const Icon(Icons.lock, color: Colors.amber), // Lock icon
                        ),
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              onPressed: _validateAccess, // Call validation function
                              icon: const Icon(Icons.lock_open),
                              label: const Text('Enter'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48), // Full width button
                                backgroundColor: Colors.amber[800], // Button color
                                foregroundColor: Colors.black, // Text color on button
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
