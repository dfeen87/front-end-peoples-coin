import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/goodwill_processing_provider.dart';
import '../widgets/dynamic_nebula_background.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider; // Need alias here for AuthProvider check (if needed)
import '../utils/app_constants.dart'; // New import for responsive constants


class SubmitGoodwillPage extends StatefulWidget {
  const SubmitGoodwillPage({super.key});

  @override
  State<SubmitGoodwillPage> createState() => _SubmitGoodwillPageState();
}

class _SubmitGoodwillPageState extends State<SubmitGoodwillPage> {
  final _actionTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lovesValueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _actionTypeController.dispose();
    _descriptionController.dispose();
    _lovesValueController.dispose();
    super.dispose();
  }

  Future<void> _submitGoodwill() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final goodwillProcessor = Provider.of<GoodwillProcessingProvider>(context, listen: false);

      // In a real app, get current user ID from AuthProvider
      // final currentUserId = Provider.of<MyAppAuthProvider.AuthProvider>(context, listen: false).user?.uid ?? "mock_user_flutter_id_456";
      const String currentUserId = "mock_user_flutter_id_456";

      try {
        final result = await goodwillProcessor.submitGoodwillAction(
          userId: currentUserId,
          actionType: _actionTypeController.text,
          description: _descriptionController.text,
          lovesValue: int.parse(_lovesValueController.text),
          contextualData: {
            "source_app": "BrightActs Flutter App",
            "device_timestamp": DateTime.now().toIso8601String(),
          },
        );

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Goodwill action submitted: ${result['message']}')),
          );
          _actionTypeController.clear();
          _descriptionController.clear();
          _lovesValueController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission failed: ${result['error']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Define content width based on screen size
    double contentWidth;
    EdgeInsetsGeometry padding;

    if (screenWidth >= AppBreakpoints.desktop) {
      contentWidth = 600.0; // Fixed width for desktop
      padding = const EdgeInsets.all(24.0);
    } else if (screenWidth >= AppBreakpoints.tablet) {
      contentWidth = screenWidth * 0.8; // 80% width for tablets
      padding = const EdgeInsets.all(20.0);
    } else { // Mobile
      contentWidth = screenWidth * 0.9; // 90% width for mobile
      padding = const EdgeInsets.all(16.0);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit a Bright Act'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center( // Center the content column horizontally
            child: Container( // Use a Container to control the width
              width: contentWidth,
              padding: padding,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _actionTypeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Type of Act (e.g., Mentorship, Caregiving)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an action type.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Describe the Act (e.g., "Helped a neighbor move")',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lovesValueController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Goodwill Value (1-100)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a goodwill value.';
                        }
                        final int? loves = int.tryParse(value);
                        if (loves == null || loves < 1 || loves > 100) {
                          return 'Value must be between 1 and 100.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Consumer<GoodwillProcessingProvider>(
                      builder: (context, goodwillProcessor, child) {
                        return ElevatedButton(
                          onPressed: goodwillProcessor.isProcessing ? null : _submitGoodwill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          child: goodwillProcessor.isProcessing
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Submit Bright Act', style: TextStyle(color: Colors.white)),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Display submission status messages
                    Consumer<GoodwillProcessingProvider>(
                      builder: (context, goodwillProcessor, child) {
                        if (goodwillProcessor.processingError != null) {
                          return Text(
                            'Error: ${goodwillProcessor.processingError}',
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                          );
                        } else if (goodwillProcessor.lastSubmittedAction != null) {
                          return Text(
                            'Act submitted successfully! ID: ${goodwillProcessor.lastSubmittedAction!.id}',
                            style: const TextStyle(color: Colors.green, fontSize: 16),
                          );
                        }
                        return const SizedBox.shrink();
                      },
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
