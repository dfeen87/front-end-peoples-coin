import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/goodwill_processing_provider.dart';
import '../widgets/dynamic_nebula_background.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;
import '../utils/app_constants.dart';

class SubmitGoodwillPage extends StatefulWidget {
  const SubmitGoodwillPage({super.key});

  @override
  State<SubmitGoodwillPage> createState() => _SubmitGoodwillPageState();
}

class _SubmitGoodwillPageState extends State<SubmitGoodwillPage> {
  final _actionTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // NEW: State variable for our slider. Initialize it to a default value.
  double _lovesValue = 50.0;

  @override
  void dispose() {
    _actionTypeController.dispose();
    _descriptionController.dispose();
    // REMOVED: No longer need the text controller for loves value.
    super.dispose();
  }

  // UPDATED: This method is now more robust.
  Future<void> _submitGoodwill() async {
    // First, dismiss the keyboard.
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // UPDATED: Get the real user ID from our AuthProvider.
      final authProvider = context.read<MyAppAuthProvider.AuthProvider>();
      final userId = authProvider.user?.uid;

      // Add a check to ensure we have a user ID before proceeding.
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: You are not logged in.')),
        );
        return;
      }

      final goodwillProcessor = context.read<GoodwillProcessingProvider>();

      try {
        final result = await goodwillProcessor.submitGoodwillAction(
          userId: userId,
          actionType: _actionTypeController.text,
          description: _descriptionController.text,
          // UPDATED: Use the value from our slider.
          lovesValue: _lovesValue.round(),
          contextualData: {
            "source_app": "BrightActs Flutter App",
            "device_timestamp": DateTime.now().toIso8601String(),
          },
        );

        if (mounted) { // Check if the widget is still in the tree
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Bright Act submitted successfully!')),
            );
            // Close the form overlay after successful submission
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Submission failed: ${result['error']}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This responsive logic is good, no changes needed here.
    final screenWidth = MediaQuery.of(context).size.width;
    double contentWidth;
    EdgeInsetsGeometry padding;

    if (screenWidth >= AppBreakpoints.desktop) {
      contentWidth = 600.0;
      padding = const EdgeInsets.all(24.0);
    } else if (screenWidth >= AppBreakpoints.tablet) {
      contentWidth = screenWidth * 0.8;
      padding = const EdgeInsets.all(20.0);
    } else {
      contentWidth = screenWidth * 0.9;
      padding = const EdgeInsets.all(16.0);
    }

    return Scaffold(
      // The AppBar is good as is, but let's give it a more descriptive title.
      appBar: AppBar(
        title: const Text('Record a Bright Act'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Optional: remove back button if in overlay
        actions: [ // Add a close button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center(
            child: Container(
              width: contentWidth,
              padding: padding,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // This TextFormField is good.
                    TextFormField(
                      controller: _actionTypeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Type of Act (e.g., Mentorship)',
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
                    const SizedBox(height: 24),
                    // This TextFormField is also good. Let's make it a bit bigger.
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Describe the Act',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      maxLines: 5, // Increased from 3 for more space
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // NEW: Interactive slider for 'Loves Value'
                    Text(
                      'Suggest a "Loves" Value: ${_lovesValue.round()}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Slider(
                      value: _lovesValue,
                      min: 1,
                      max: 100,
                      divisions: 99, // Snaps to whole numbers
                      label: _lovesValue.round().toString(),
                      activeColor: Colors.amber[700],
                      inactiveColor: Colors.white30,
                      onChanged: (double value) {
                        setState(() {
                          _lovesValue = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    // This button logic is good.
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
