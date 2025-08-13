import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service/api_client.dart';
import '../service/recaptcha_service.dart';
import '../service/wallet_manager.dart';
import '../widgets/dynamic_nebula_background.dart';
import '../state/auth_provider.dart';

enum UsernameStatus { idle, checking, available, unavailable, tooShort }

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
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
      if (kDebugMode) print("Username check error: $e");
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_usernameStatus != UsernameStatus.available) {
      _showError('Please choose an available username.');
      return;
    }

    final recaptchaSiteKey =
        dotenv.env['RECAPTCHA_SITE_KEY_PROD'] ?? '6LeE0pQrAAAAAML8x8JqtfryKhZ9bpvLRacQzH1F';
    final apiBaseUrl =
        dotenv.env['API_BASE_URL'] ?? 'https://peoples-coin-service-105378934751.us-central1.run.app';

    setState(() => _isLoading = true);

    try {
      final recaptchaService = RecaptchaService(
        context,
        siteKey: recaptchaSiteKey,
        verifyUrl: '$apiBaseUrl/verify-recaptcha',
      );

      final token = await recaptchaService.execute();
      if (token.isEmpty) throw Exception('reCAPTCHA verification failed.');

      // Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user;
      if (user == null) throw Exception('Firebase user creation failed.');

      final idToken = await user.getIdToken();
      if (idToken.isEmpty) throw Exception('Failed to retrieve Firebase ID token.');

      final apiClient = ref.read(apiClientProvider);

      // Backend call to create user and wallet
      await apiClient.createUserAndWallet(
        username: _usernameController.text.trim(),
        recaptchaToken: token,
        idToken: idToken,
      );

      // Local wallet creation/unlock
      final walletManager = ref.read(walletManagerProvider.notifier);
      await walletManager.unlockOrCreateWallet(_usernameController.text.trim());

      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      final friendlyMessage = switch (e.code) {
        'email-already-in-use' => 'This email is already registered.',
        'weak-password' => 'The password is too weak.',
        'invalid-email' => 'Invalid email format.',
        _ => 'Sign-up error: ${e.message}',
      };
      _showError(friendlyMessage);
    } catch (e, stack) {
      if (kDebugMode) print("Sign-up error: $e\n$stack");
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('username_taken')) {
        _showError('This username was just taken. Please choose another.');
        if (mounted) setState(() => _usernameStatus = UsernameStatus.unavailable);
      } else {
        _showError('Unexpected error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                                  return 'Checking username...';
                                case UsernameStatus.idle:
                                  if (val == null || val.trim().isEmpty) return 'Enter a username';
                                  return null;
                                case UsernameStatus.available:
                                default:
                                  return null;
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isPasswordObscured,
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Password', Icons.lock_outline,
                                suffixIcon: passwordToggle),
                            validator: (val) => (val?.length ?? 0) >= 6 ? null : 'Password must be at least 6 chars',
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
                          ),
                          const SizedBox(height: 24),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
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
                                onPressed: _signUpWithEmail,
                                child: const Text('Sign Up', style: TextStyle(fontSize: 16, color: Colors.white)),
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

