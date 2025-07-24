// lib/pages/dev_gate_page.dart

import 'package:flutter/material.dart';
import '../screens/sign_in_screen.dart'; // This links to the real sign-in screen

class DevGatePage extends StatefulWidget {
  const DevGatePage({super.key});

  @override
  State<DevGatePage> createState() => _DevGatePageState();
}

class _DevGatePageState extends State<DevGatePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final String _correctUsername = "dev";
  final String _correctPassword = "password123";

  void _login() {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username == _correctUsername && password == _correctPassword) {
      // On success, navigate to the REAL sign-in screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    } else {
      // On failure, show an error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid developer credentials."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Developer Access")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Dev Username"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Dev Password"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              child: const Text("Enter Testing"),
            ),
          ],
        ),
      ),
    );
  }
}
