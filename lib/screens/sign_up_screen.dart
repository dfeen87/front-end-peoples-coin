// lib/screens/sign_up_screen.dart
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service/api_client.dart';
import '../state/auth_provider.dart';
import '../widgets/dynamic_nebula_background.dart';

enum UsernameStatus { idle, checking, available, unavailable, tooShort }

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordObscured = true;
  UsernameStatus _usernameStatus = UsernameStatus.idle;

  Timer? _debounce;
  static const int _minUsernameLength = 3;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(_debounceDuration, _checkUsernameAvailability);
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username.length < _minUsernameLength) {
      if (mounted) setState(() => _usernameStatus = UsernameStatus.tooShort);
      return;
    }

    if (mounted) setState(() => _usernameStatus = UsernameStatus.checking);

    try {
      final apiClient = ref.read(apiClientProvider);
      final isAvailable = await apiClient.checkUsernameAvailability(username);
      if (mounted) {
        setState(() => _usernameStatus =
            isAvailable ? UsernameStatus.available : UsernameStatus.unavailable);
      }
    } catch (e) {
      if (mounted) setState(() => _usernameStatus = UsernameStatus.unavailable);
      _showError("Couldn't verify username. Please try again.");
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_usernameStatus != UsernameStatus.available) {
      _showError('Please choose an available username.');
      return;
    }
    
    // Unfocus all text fields
    FocusScope.of(context).unfocus();

    // Use the correct provider for the auth service
    final authService = ref.read(authServiceProvider.notifier);

    try {
      // Call the signUp method on the AuthServiceNotifier.
      // This single call now handles Firebase authentication and backend profile creation.
      await authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        // Note: The Recaptcha logic should be part of the `AuthServiceNotifier`
        // or a dedicated service, not the UI layer. For now, this is a placeholder.
        recaptchaToken: 'placeholder_token',
      );

      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }
  
  InputDecoration _buildInputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.blueGrey[200]),
      prefixIcon: Icon(icon, color: Colors.blueGrey[300], size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueGrey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Widget? _buildUsernameSuffixIcon() {
    switch (_usernameStatus) {
      case UsernameStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(10.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
          ),
        );
      case UsernameStatus.available:
        return const Icon(Icons.check_circle, color: Colors.greenAccent);
      case UsernameStatus.unavailable:
      case UsernameStatus.tooShort:
        return const Icon(Icons.error, color: Colors.redAccent);
      case UsernameStatus.idle:
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auth status to handle the loading state
    final authStatus = ref.watch(authStatusProvider);
    final isLoading = authStatus == AuthStatus.loading;

    final passwordToggle = IconButton(
      icon: Icon(
        _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
        color: Colors.blueGrey[300],
      ),
      onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  color: Colors.blueGrey[900]?.withOpacity(0.6),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.blueGrey[800]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Create Account',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'monospace')),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Email', Icons.alternate_email),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) =>
                                (val?.contains('@') ?? false) ? null : 'Enter a valid email',
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration(
                              'Username',
                              Icons.person_outline,
                              suffixIcon: _buildUsernameSuffixIcon(),
                            ),
                            validator: (val) {
                              switch (_usernameStatus) {
                                case UsernameStatus.tooShort:
                                  return 'Username must be at least $_minUsernameLength chars';
                                case UsernameStatus.unavailable:
                                  return 'This username is taken';
                                case UsernameStatus.checking:
                                case UsernameStatus.idle:
                                  if (val == null || val.trim().isEmpty) return 'Enter a username';
                                  return null;
                                case UsernameStatus.available:
                                default:
                                  return null;
                              }
                            },
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isPasswordObscured,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Password', Icons.lock_outline,
                                suffixIcon: passwordToggle),
                            validator: (val) => (val?.length ?? 0) >= 6 ? null : 'Password must be at least 6 chars',
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _isPasswordObscured,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Confirm Password', Icons.lock_person_outlined),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Confirm your password';
                              if (val != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.amber[800],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isLoading ? null : _signUpWithEmail,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Sign Up', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(color: Colors.blueGrey[200]),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Sign In',
                                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                                  recognizer: TapGestureRecognizer()..onTap = () => context.go('/signin'),
                                ),
                              ],
                            ),
                          )
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
