import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../service/api_client.dart';

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

  final _apiClient = PeoplesCoinApiClient();

  bool _isLoading = false;
  String? _error;

  Future<bool> checkUsernameAvailability(String username) async {
    // Update this URL to your actual endpoint for username availability
    final uri = Uri.parse('${_apiClient._baseUrl}/api/v1/users/username-check/$username');
    final res = await http.get(uri);
    return res.statusCode == 200 && jsonDecode(res.body)['available'] == true;
  }

  Future<String?> getRecaptchaToken() async {
    try {
      final token = await js_util.promiseToFuture<String>(
        js_util.callMethod(
          js_util.globalThis,
          'getRecaptchaToken',
          ['signup'], // action name matches your JS reCAPTCHA call
        ),
      );
      return token;
    } catch (e) {
      debugPrint('Failed to get reCAPTCHA token: $e');
      return null;
    }
  }

  String generateRandomPrivateKey() {
    final rand = Random.secure();
    final values = List<int>.generate(32, (_) => rand.nextInt(256));
    return _hexEncode(values);
  }

  String _hexEncode(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  String deriveWalletAddress(String privateKeyHex) {
    final domainParams = ECDomainParameters('secp256k1');
    final privKey = ECPrivateKey(BigInt.parse(privateKeyHex, radix: 16), domainParams);
    final pubKey = domainParams.G * privKey.d!;
    final pubBytes = pubKey!.getEncoded(false).sublist(1); // drop prefix byte 0x04
    final hashed = _keccak256(pubBytes);
    return '0x${_hexEncode(hashed.sublist(12))}';
  }

  List<int> _keccak256(List<int> input) {
    final digest = Digest('keccak/256');
    return digest.process(Uint8List.fromList(input));
  }

  String encryptPrivateKey(String privateKey, String password) {
    final key = sha256.convert(utf8.encode(password)).bytes;
    final iv = Uint8List(16); // zeros initialization vector
    final cipher = CBCBlockCipher(AESEngine())
      ..init(
        true,
        ParametersWithIV(KeyParameter(Uint8List.fromList(key)), iv),
      );

    final input = Uint8List.fromList(utf8.encode(privateKey));
    // PKCS7 padding
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      final usernameAvailable = await checkUsernameAvailability(username);
      if (!usernameAvailable) {
        setState(() {
          _error = 'Username already taken';
          _isLoading = false;
        });
        return;
      }

      // Get reCAPTCHA token
      final recaptchaToken = await getRecaptchaToken();
      if (recaptchaToken == null) {
        setState(() {
          _error = 'Failed to verify reCAPTCHA. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // Register user via Firebase Email & Password
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Generate wallet keys
      final privateKey = generateRandomPrivateKey();
      final walletAddress = deriveWalletAddress(privateKey);
      final encryptedPrivateKey = encryptPrivateKey(privateKey, password);

      // Call backend API to create user wallet including reCAPTCHA token
      await _apiClient.createUserWallet(
        username: username,
        publicKey: walletAddress,
        encryptedPrivateKey: encryptedPrivateKey,
        recaptchaToken: recaptchaToken,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (val) => val == null || val.isEmpty ? 'Enter a username' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val != null && val.contains('@') ? null : 'Invalid email',
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number (optional)'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (val) => val != null && val.length >= 6 ? null : 'Password too short',
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Create Account'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

