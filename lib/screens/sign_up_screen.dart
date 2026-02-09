// lib/screens/sign_up_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../service/api_client.dart';
import '../state/auth_provider.dart';
import '../widgets/dynamic_nebula_background.dart';

enum UsernameStatus { idle, checking, available, unavailable, tooShort, invalid }
enum PasswordStrength { veryWeak, weak, fair, good, strong }

// reCAPTCHA Enterprise configuration
class RecaptchaConfig {
  static const String siteKey = 'YOUR_RECAPTCHA_SITE_KEY'; // Replace with your actual site key
  static const String projectId = 'YOUR_PROJECT_ID'; // Replace with your GCP project ID
  static const String apiKey = 'YOUR_API_KEY'; // Replace with your API key
  static const String action = 'signup';
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Focus nodes for better UX
  final _emailFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _acceptedTerms = false;
  bool _recaptchaLoaded = false;
  bool _isRecaptchaVerifying = false;
  UsernameStatus _usernameStatus = UsernameStatus.idle;
  PasswordStrength _passwordStrength = PasswordStrength.veryWeak;

  Timer? _debounce;
  Timer? _passwordDebounce;
  late AnimationController _strengthAnimationController;
  late Animation<double> _strengthAnimation;

  static const int _minUsernameLength = 3;
  static const int _maxUsernameLength = 20;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
    _passwordController.addListener(_onPasswordChanged);
    
    _strengthAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _strengthAnimation = CurvedAnimation(
      parent: _strengthAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Initialize reCAPTCHA
    _initializeRecaptcha();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _passwordDebounce?.cancel();
    _strengthAnimationController.dispose();
    
    _usernameController.removeListener(_onUsernameChanged);
    _passwordController.removeListener(_onPasswordChanged);
    
    _emailFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _onUsernameChanged() {
    if (_debounce?.isActive == true) _debounce!.cancel();
    _debounce = Timer(_debounceDuration, _checkUsernameAvailability);
  }

  void _onPasswordChanged() {
    if (_passwordDebounce?.isActive == true) _passwordDebounce!.cancel();
    _passwordDebounce = Timer(const Duration(milliseconds: 200), () {
      final newStrength = _calculatePasswordStrength(_passwordController.text);
      if (newStrength != _passwordStrength) {
        setState(() => _passwordStrength = newStrength);
        _strengthAnimationController.reset();
        _strengthAnimationController.forward();
      }
    });
  }

  void _initializeRecaptcha() {
    // Inject reCAPTCHA Enterprise script
    final script = html.ScriptElement()
      ..src = 'https://www.google.com/recaptcha/enterprise.js?render=${RecaptchaConfig.siteKey}'
      ..async = true
      ..defer = true;
    
    script.onLoad.listen((_) {
      if (mounted) {
        setState(() => _recaptchaLoaded = true);
      }
    });
    
    script.onError.listen((_) {
      if (mounted) {
        _showError('Failed to load reCAPTCHA. Please refresh and try again.');
      }
    });
    
    html.document.head?.append(script);
  }

  Future<String?> _executeRecaptcha() async {
    if (!_recaptchaLoaded) {
      _showError('reCAPTCHA not loaded. Please try again.');
      return null;
    }

    setState(() => _isRecaptchaVerifying = true);

    try {
      // Execute reCAPTCHA v3 with Enterprise API
      final token = await _getRecaptchaToken();
      
      if (token == null) {
        _showError('reCAPTCHA verification failed. Please try again.');
        return null;
      }

      // Verify token with Google reCAPTCHA Enterprise API
      final isValid = await _verifyRecaptchaToken(token);
      
      if (!isValid) {
        _showError('reCAPTCHA verification failed. Please try again.');
        return null;
      }

      return token;
    } catch (e) {
      _showError('reCAPTCHA verification error. Please try again.');
      return null;
    } finally {
      setState(() => _isRecaptchaVerifying = false);
    }
  }

  Future<String?> _getRecaptchaToken() async {
    final completer = Completer<String?>();
    
    // Call grecaptcha.enterprise.execute
    js_util.callMethod(html.window, 'eval', ['''
      if (typeof grecaptcha !== 'undefined' && grecaptcha.enterprise) {
        grecaptcha.enterprise.execute('${RecaptchaConfig.siteKey}', {
          action: '${RecaptchaConfig.action}'
        }).then(function(token) {
          window.recaptchaCallback(token);
        }).catch(function(error) {
          console.error('reCAPTCHA error:', error);
          window.recaptchaCallback(null);
        });
      } else {
        console.error('reCAPTCHA Enterprise not loaded');
        window.recaptchaCallback(null);
      }
    ''']);

    // Set up callback
    js_util.setProperty(html.window, 'recaptchaCallback', (String? token) {
      if (!completer.isCompleted) {
        completer.complete(token);
      }
    });

    // Timeout after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  Future<bool> _verifyRecaptchaToken(String token) async {
    try {
      final url = 'https://recaptchaenterprise.googleapis.com/v1/projects/${RecaptchaConfig.projectId}/assessments?key=${RecaptchaConfig.apiKey}';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'event': {
            'token': token,
            'siteKey': RecaptchaConfig.siteKey,
            'expectedAction': RecaptchaConfig.action,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final riskAnalysis = data['riskAnalysis'];
        final tokenProperties = data['tokenProperties'];
        
        // Check if token is valid and score is acceptable
        final isValid = tokenProperties['valid'] == true;
        final score = riskAnalysis['score'] ?? 0.0;
        final expectedAction = tokenProperties['action'] == RecaptchaConfig.action;
        
        // You can adjust the score threshold based on your security needs
        // Score ranges from 0.0 (likely bot) to 1.0 (likely human)
        const scoreThreshold = 0.5;
        
        return isValid && expectedAction && score >= scoreThreshold;
      }
      
      return false;
    } catch (e) {
      print('reCAPTCHA verification error: $e');
      return false;
    }
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.veryWeak;
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    // Bonus for no repeated characters
    if (!RegExp(r'(.)\1{2,}').hasMatch(password)) score++;
    
    switch (score) {
      case 0:
      case 1:
        return PasswordStrength.veryWeak;
      case 2:
      case 3:
        return PasswordStrength.weak;
      case 4:
        return PasswordStrength.fair;
      case 5:
        return PasswordStrength.good;
      default:
        return PasswordStrength.strong;
    }
  }

  String _getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return Colors.red;
      case PasswordStrength.weak:
        return Colors.deepOrange;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.lightGreen;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  double _getStrengthProgress(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 0.2;
      case PasswordStrength.weak:
        return 0.4;
      case PasswordStrength.fair:
        return 0.6;
      case PasswordStrength.good:
        return 0.8;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    
    if (username.isEmpty) {
      if (mounted) setState(() => _usernameStatus = UsernameStatus.idle);
      return;
    }
    
    if (username.length < _minUsernameLength) {
      if (mounted) setState(() => _usernameStatus = UsernameStatus.tooShort);
      return;
    }
    
    if (username.length > _maxUsernameLength) {
      if (mounted) setState(() => _usernameStatus = UsernameStatus.invalid);
      return;
    }
    
    // Validate username format
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      if (mounted) setState(() => _usernameStatus = UsernameStatus.invalid);
      return;
    }

    if (mounted) setState(() => _usernameStatus = UsernameStatus.checking);

    try {
      final apiClient = ref.read(apiClientProvider);
      final isAvailable = await apiClient
          .checkUsernameAvailability(username)
          .timeout(const Duration(seconds: 10));
          
      // Only update if the username hasn't changed while we were checking
      if (mounted && _usernameController.text.trim() == username) {
        setState(() => _usernameStatus =
            isAvailable ? UsernameStatus.available : UsernameStatus.unavailable);
      }
    } catch (e) {
      if (mounted && _usernameController.text.trim() == username) {
        setState(() => _usernameStatus = UsernameStatus.unavailable);
        _showError("Couldn't verify username. Please try again.");
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';
    
    final trimmed = value.trim();
    
    if (trimmed.length < _minUsernameLength) {
      return 'Username must be at least $_minUsernameLength characters';
    }
    
    if (trimmed.length > _maxUsernameLength) {
      return 'Username must be less than $_maxUsernameLength characters';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    // Fixed: Don't allow form submission if still checking or unavailable
    switch (_usernameStatus) {
      case UsernameStatus.unavailable:
        return 'This username is taken';
      case UsernameStatus.checking:
        return 'Checking username availability...';
      case UsernameStatus.tooShort:
        return 'Username is too short';
      case UsernameStatus.invalid:
        return 'Invalid username format';
      case UsernameStatus.available:
      case UsernameStatus.idle:
        return null;
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    
    if (_passwordStrength == PasswordStrength.veryWeak) {
      return 'Password is too weak';
    }
    
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _signUpWithEmail() async {
    // Validate form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    
    // Check terms acceptance
    if (!_acceptedTerms) {
      _showError('Please accept the terms and conditions to continue.');
      return;
    }
    
    // Ensure username is available (removed the checking status bypass)
    if (_usernameStatus != UsernameStatus.available) {
      _showError('Please ensure username is available before proceeding.');
      return;
    }
    
    // Execute reCAPTCHA verification
    final recaptchaToken = await _executeRecaptcha();
    if (recaptchaToken == null) {
      return; // Error already shown in _executeRecaptcha
    }
    
    // Unfocus all text fields
    FocusScope.of(context).unfocus();

    final authService = ref.read(authServiceProvider.notifier);

    try {
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        recaptchaToken: recaptchaToken,
      );

      if (mounted) {
        _showSuccess('Account created successfully! Welcome aboard!');
        
        // Small delay to show the success message
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered. Try signing in instead.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Please choose a stronger password.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection and try again.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled. Please contact support.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign up. Please try again.';
      }
      _showError(errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showError('An unexpected error occurred. Please try again.');
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'By creating an account, you agree to:\n\n'
            '• Use our service responsibly and lawfully\n'
            '• Provide accurate and truthful information\n'
            '• Respect other users and the community\n'
            '• Comply with all applicable laws and regulations\n'
            '• Not use the service for spam or malicious activities\n\n'
            'We reserve the right to terminate accounts that violate these terms.\n\n'
            'Your privacy is important to us. Please review our Privacy Policy for details on how we handle your data.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'We are committed to protecting your privacy:\n\n'
            '• We collect only necessary information to provide our service\n'
            '• Your personal data is encrypted and securely stored\n'
            '• We do not sell or share your data with third parties\n'
            '• You have the right to access, modify, or delete your data\n'
            '• We use cookies to improve your experience\n'
            '• Data is retained only as long as necessary\n\n'
            'For detailed information about our data practices, please contact our support team.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
  
  InputDecoration _buildInputDecoration(
    String label, 
    IconData icon, {
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperStyle: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
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
        borderSide: const BorderSide(color: Colors.amber, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueGrey[800]!),
      ),
    );
  }

  Widget? _buildUsernameSuffixIcon() {
    switch (_usernameStatus) {
      case UsernameStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2, 
              color: Colors.amber,
            ),
          ),
        );
      case UsernameStatus.available:
        return const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20);
      case UsernameStatus.unavailable:
        return const Icon(Icons.cancel, color: Colors.redAccent, size: 20);
      case UsernameStatus.tooShort:
      case UsernameStatus.invalid:
        return const Icon(Icons.error, color: Colors.redAccent, size: 20);
      case UsernameStatus.idle:
      default:
        return null;
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _strengthAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0, end: _getStrengthProgress(_passwordStrength)),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.blueGrey[800],
                        valueColor: AlwaysStoppedAnimation(_getStrengthColor(_passwordStrength)),
                        minHeight: 4,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getStrengthText(_passwordStrength),
                  style: TextStyle(
                    color: _getStrengthColor(_passwordStrength),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (_passwordStrength == PasswordStrength.veryWeak || _passwordStrength == PasswordStrength.weak) ...[
              const SizedBox(height: 4),
              Text(
                'Use 8+ characters with uppercase, lowercase, numbers & symbols',
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // Method to build submit button - handles dynamic state properly
  Widget _buildSubmitButton() {
    final authStatus = ref.watch(authStatusProvider);
    final isLoading = authStatus == AuthStatus.loading || _isRecaptchaVerifying;
    
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber[700],
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.blueGrey[700],
          disabledForegroundColor: Colors.blueGrey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Colors.amber.withOpacity(0.3),
        ),
        onPressed: (isLoading || !_acceptedTerms || !_recaptchaLoaded) ? null : _signUpWithEmail,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(
                _isRecaptchaVerifying ? 'Verifying...' : 'Create Account',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Method to build loading overlay - handles dynamic state properly  
  Widget? _buildLoadingOverlay() {
    final authStatus = ref.watch(authStatusProvider);
    final isLoading = authStatus == AuthStatus.loading || _isRecaptchaVerifying;
    
    if (!isLoading) return null;
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  _isRecaptchaVerifying 
                    ? 'Verifying security...' 
                    : 'Creating your account...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                color: Colors.blueGrey[900]?.withOpacity(0.7),
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.blueGrey[700]!, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.person_add,
                                color: Colors.amber,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join our community today',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueGrey[300],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(
                            'Email Address',
                            Icons.alternate_email,
                            helperText: 'We\'ll send you a verification email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          enabled: !_isRecaptchaVerifying,
                          onFieldSubmitted: (_) => _usernameFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 20),

                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(
                            'Username',
                            Icons.person_outline,
                            suffixIcon: _buildUsernameSuffixIcon(),
                            helperText: '$_minUsernameLength-$_maxUsernameLength characters, letters, numbers, and underscores only',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: _validateUsername,
                          enabled: !_isRecaptchaVerifying,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(_maxUsernameLength),
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                          ],
                          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _isPasswordObscured,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(
                            'Password',
                            Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                                color: Colors.blueGrey[300],
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: _validatePassword,
                          enabled: !_isRecaptchaVerifying,
                          onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                        ),
                        _buildPasswordStrengthIndicator(),
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          obscureText: _isConfirmPasswordObscured,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(
                            'Confirm Password',
                            Icons.lock_person_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility,
                                color: Colors.blueGrey[300],
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          validator: _validateConfirmPassword,
                          enabled: !_isRecaptchaVerifying,
                          onFieldSubmitted: (_) => _signUpWithEmail(),
                        ),
                        const SizedBox(height: 24),

                        // Terms and Conditions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueGrey[700]!),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: _isRecaptchaVerifying ? null : (value) => setState(() => _acceptedTerms = value ?? false),
                                  activeColor: Colors.amber,
                                  checkColor: Colors.black,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'I agree to the ',
                                    style: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = _showTermsDialog,
                                      ),
                                      TextSpan(
                                        text: ' and ',
                                        style: TextStyle(color: Colors.blueGrey[200]),
                                      ),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = _showPrivacyDialog,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // reCAPTCHA status indicator
                        if (!_recaptchaLoaded)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Loading security verification...',
                                  style: TextStyle(
                                    color: Colors.orange[300],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_recaptchaLoaded)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.security,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Protected by reCAPTCHA Enterprise',
                                  style: TextStyle(
                                    color: Colors.green[300],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 28),

                        // Sign Up Button - using the fixed method
                        _buildSubmitButton(),
                        const SizedBox(height: 24),

                        // Sign In Link
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(color: Colors.blueGrey[300], fontSize: 16),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Sign In',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => context.go('/signin'),
                                ),
                              ],
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
          
          // Loading Overlay - using the fixed method
          if (_buildLoadingOverlay() != null) _buildLoadingOverlay()!,
        ],
      ),
    );
  }
}
