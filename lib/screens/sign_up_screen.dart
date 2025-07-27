import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui'; // Needed for BackdropFilter
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pointy;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:web3dart/crypto.dart';

import '../service/api_client.dart';
import '../widgets/dynamic_nebula_background.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _apiClient = PeoplesCoinApiClient();

  bool _isLoading = false;
  String? _error;

  // --- Crypto and Helper Logic (Restored) ---

  Future<bool> checkUsernameAvailability(String username) async {
    final uri = Uri.parse('${_apiClient.baseUrl}/api/v1/users/username-check/$username');
    final res = await http.get(uri);
    return res.statusCode == 200 && jsonDecode(res.body)['available'] == true;
  }

  String generateRandomPrivateKey() {
    final rand = Random.secure();
    final values = List<int>.generate(32, (_) => rand.nextInt(256));
    return _hexEncode(values);
  }

  String _hexEncode(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  String deriveWalletAddress(String privateKeyHex) {
    final domainParams = pointy.ECDomainParameters('secp256k1');
    final privKey = pointy.ECPrivateKey(BigInt.parse(privateKeyHex, radix: 16), domainParams);
    final pubKey = domainParams.G * privKey.d!;
    final pubBytes = pubKey!.getEncoded(false).sublist(1);
    final hashed = _keccak256(pubBytes);
    return '0x${_hexEncode(hashed.sublist(12))}';
  }

  Uint8List _keccak256(List<int> input) {
    return keccak256(Uint8List.fromList(input));
  }

  String encryptPrivateKey(String privateKey, String password) {
    final key = sha256.convert(utf8.encode(password)).bytes;
    final iv = Uint8List(16); // Using a zero IV, consider a random one for production
    final cipher = pointy.CBCBlockCipher(pointy.AESEngine())
      ..init(
        true,
        pointy.ParametersWithIV(pointy.KeyParameter(Uint8List.fromList(key)), iv),
      );
    final input = Uint8List.fromList(utf8.encode(privateKey));
    final padLength = 16 - (input.length % 16);
    final padded = Uint8List(input.length + padLength)..setRange(0, input.length, input);
    for (var i = input.length; i < padded.length; i++) {
      padded[i] = padLength;
    }
    final output = Uint8List(padded.length);
    for (int offset = 0; offset < padded.length; offset += 16) {
      cipher.processBlock(padded, offset, output, offset);
    }
    return base64.encode(output);
  }

  // --- Submit Logic (Corrected) ---

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      // Note: The phone number is collected but not sent to the API in this version.
      // You would need to modify your API to accept it.

      final usernameAvailable = await checkUsernameAvailability(username);
      if (!usernameAvailable) {
        throw Exception('Username already taken');
      }

      // Create user in Firebase Auth
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Generate keys and encrypt on the client-side (as per original logic)
      final privateKey = generateRandomPrivateKey();
      final walletAddress = deriveWalletAddress(privateKey);
      final encryptedPrivateKey = encryptPrivateKey(privateKey, password);
      
      // Call the API with the parameters it expects
      await _apiClient.createUserWallet(
        username: username,
        publicKey: walletAddress,
        encryptedPrivateKey: encryptedPrivateKey,
        // The recaptchaToken is no longer needed here, App Check handles it.
      );

      if (!mounted) return;
      context.go('/home');

    } catch (e) {
      if(mounted) setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                              'Create Your Bright Acts Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
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
                              controller: _usernameController,
                              decoration: _buildInputDecoration('Username', Icons.person_outline),
                              validator: (val) => val == null || val.isEmpty ? 'Enter a username' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: _buildInputDecoration('Email', Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) => val != null && val.contains('@') ? null : 'Invalid email',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: _buildInputDecoration('Phone Number (Optional)', Icons.phone_outlined),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: _buildInputDecoration('Password', Icons.lock_outline),
                              validator: (val) => val != null && val.length >= 6 ? null : 'Password must be at least 6 characters',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: _buildInputDecoration('Confirm Password', Icons.lock_reset_outlined),
                              validator: (val) {
                                if (val != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.amber[800],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Create Account', style: TextStyle(fontSize: 16)),
                                  ),
                            const SizedBox(height: 20),
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already a member? ',
                                  style: const TextStyle(color: Colors.white70),
                                  children: [
                                    TextSpan(
                                      text: 'Sign in here.',
                                      style: TextStyle(
                                        color: Colors.amber[600],
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          context.go('/sign_in');
                                        },
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
            ),
          ),
        ],
      ),
    );
  }
}

