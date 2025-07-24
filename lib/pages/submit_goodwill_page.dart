// lib/pages/submit_goodwill_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/goodwill_processing_provider.dart';
import '../state/user_provider.dart'; // To get current user ID

class SubmitGoodwillPage extends StatefulWidget {
  const SubmitGoodwillPage({super.key});

  @override
  State<SubmitGoodwillPage> createState() => _SubmitGoodwillPageState();
}

class _SubmitGoodwillPageState extends State<SubmitGoodwillPage> {
  final _formKey = GlobalKey<FormState>();
  String _actionType = '';
  String _description = '';
  int _lovesValue = 25; // MODIFIED: Default loves value set to 25

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Ensure this is transparent
      appBar: AppBar(
        title: const Text('Record a Bright Act'),
        backgroundColor: Colors.transparent, // Ensure app bar is also transparent
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Consumer<GoodwillProcessingProvider>(
        builder: (context, provider, child) {
          final currentUser = context.watch<UserProvider>().userAccount;
          if (currentUser == null) {
            return const Center(child: Text("User not logged in or data not loaded."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Type of Act (e.g., Mentorship)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the type of act.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _actionType = value!;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Describe the Act',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe the act of goodwill.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _description = value!;
                    },
                  ),
                  const SizedBox(height: 24.0),
                  Text('Suggest a "Loves" Value: $_lovesValue',
                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  Slider(
                    value: _lovesValue.toDouble(),
                    min: 1,
                    max: 50, // MODIFIED: Max loves value set to 50
                    divisions: 49, // MODIFIED: Divisions set to 49 (50 - 1)
                    label: _lovesValue.round().toString(),
                    onChanged: (double newValue) {
                      setState(() {
                        _lovesValue = newValue.round();
                      });
                    },
                    activeColor: Colors.amber,
                    inactiveColor: Colors.amber.withOpacity(0.3),
                  ),
                  const SizedBox(height: 32.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: provider.isProcessingGoodwill
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                final success = await provider.submitGoodwill(
                                  performerUserId: currentUser.id,
                                  actionType: _actionType,
                                  description: _description,
                                  lovesValue: _lovesValue,
                                );
                                if (success && mounted) {
                                  Navigator.of(context).pop(); // Close form on success
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Goodwill act submitted!')),
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to submit act: ${provider.error}')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: provider.isProcessingGoodwill
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Bright Act'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
