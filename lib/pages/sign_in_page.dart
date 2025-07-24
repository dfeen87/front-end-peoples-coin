import 'package:flutter/material.dart';
// TODO: Make sure this path points to your REAL sign-in page.
import '../screens/sign_in_screen.dart';
import '../widgets/dynamic_nebula_background.dart';

// The class is renamed to avoid confusion with the real sign-in page.
class DevGatePage extends StatefulWidget {
  const DevGatePage({super.key});

  @override
  State<DevGatePage> createState() => _DevGatePageState();
}

class _DevGatePageState extends State<DevGatePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- 🤫 Hardcoded Developer Credentials ---
  final String _correctUsername = "dev";
  final String _correctPassword = "password123";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Updated Sign-In Logic ---
  void _devLogin() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final enteredUsername = _emailController.text;
      final enteredPassword = _passwordController.text;

      // Check if the entered credentials match the hardcoded ones
      if (enteredUsername == _correctUsername && enteredPassword == _correctPassword) {
        // ✅ Success: Navigate to the real sign-in screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SignInScreen()), // Navigates to the real page
        );
      } else {
        // ❌ Failure: Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid developer credentials."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BrightActs Dev Access', // Title changed
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    // Email/Username field
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Dev Username', // Label changed
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        prefixIcon: Icon(Icons.person, color: Colors.white70),
                      ),
                      keyboardType: TextInputType.text, // Changed from email
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the dev username.';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Dev Password', // Label changed
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        prefixIcon: Icon(Icons.lock, color: Colors.white70),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the dev password.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _devLogin(),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    // --- Simplified Sign-In Button ---
                    ElevatedButton(
                      onPressed: _devLogin, // Calls the new dev login method
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      child: const Text('Enter Testing', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
