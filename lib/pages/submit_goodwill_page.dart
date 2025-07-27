import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:ui';

import '../state/goodwill_processing_provider.dart';
import '../state/user_provider.dart';

// --- NEW: A map of predefined act types with icons for a better UI ---
const Map<String, IconData> _actTypes = {
  'Mentorship': Icons.school_outlined,
  'Volunteering': Icons.volunteer_activism_outlined,
  'Donation': Icons.monetization_on_outlined,
  'Support': Icons.support_agent_outlined,
  'Kindness': Icons.favorite_border,
  'Community': Icons.groups_outlined,
  'Environment': Icons.eco_outlined,
  'Other': Icons.more_horiz,
};

class SubmitGoodwillPage extends StatefulWidget {
  const SubmitGoodwillPage({super.key});

  @override
  State<SubmitGoodwillPage> createState() => _SubmitGoodwillPageState();
}

class _SubmitGoodwillPageState extends State<SubmitGoodwillPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // State variables for the stepper
  int _currentStep = 0;
  String _actionType = '';
  String _description = '';
  int _lovesValue = 25;

  // --- NEW: Animation controller for the success confetti ---
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- NEW: Function to show the success overlay ---
  void _showSuccessOverlay() {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay == null) return;

    final confetti = ConfettiOverlay(controller: _confettiController);
    final overlayEntry = OverlayEntry(builder: (context) => confetti);

    Overlay.of(context).insert(overlayEntry);
    _confettiController.forward(from: 0.0);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      appBar: AppBar(
        title: const Text('Record a Bright Act'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(), // Remove back button
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Consumer<GoodwillProcessingProvider>(
        builder: (context, provider, child) {
          final currentUser = context.watch<UserProvider>().currentUser;
          if (currentUser == null) {
            return const Center(child: Text("User not logged in or data not loaded."));
          }

          // --- NEW: The Stepper UI ---
          return Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep += 1);
              } else {
                // This is the final submit action
                _submitForm(provider, currentUser.id);
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            // --- NEW: Custom Stepper styling ---
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    if (_currentStep > 0)
                      TextButton.icon(
                        onPressed: details.onStepCancel,
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        label: const Text('Back', style: TextStyle(color: Colors.white70)),
                      ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: details.onStepContinue,
                      icon: Icon(_currentStep == 2 ? Icons.check_circle_outline : Icons.arrow_forward),
                      label: Text(_currentStep == 2 ? 'Submit' : 'Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[800],
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            },
            steps: _buildSteps(),
          );
        },
      ),
    );
  }

  // --- NEW: Helper to build the list of steps ---
  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Choose', style: TextStyle(color: Colors.white)),
        content: _buildStep1ChooseAct(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Describe', style: TextStyle(color: Colors.white)),
        content: _buildStep2Describe(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Value', style: TextStyle(color: Colors.white)),
        content: _buildStep3SetValue(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  // --- NEW: Content for Step 1 ---
  Widget _buildStep1ChooseAct() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What kind of Bright Act did you perform?",
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _actTypes.entries.map((entry) {
            return ChoiceChip(
              label: Text(entry.key),
              avatar: Icon(entry.value, color: _actionType == entry.key ? Colors.black : Colors.white70),
              selected: _actionType == entry.key,
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() => _actionType = entry.key);
                }
              },
              selectedColor: Colors.amber[700],
              backgroundColor: Colors.white.withOpacity(0.1),
              labelStyle: TextStyle(color: _actionType == entry.key ? Colors.black : Colors.white),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- NEW: Content for Step 2 ---
  Widget _buildStep2Describe() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tell us the story.",
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _description,
            decoration: const InputDecoration(
              hintText: 'Describe the act of goodwill...',
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
            ),
            style: const TextStyle(color: Colors.white),
            maxLines: 5,
            validator: (value) => value == null || value.isEmpty ? 'Please describe the act.' : null,
            onSaved: (value) => _description = value!,
          ),
        ],
      ),
    );
  }

  // --- NEW: Content for Step 3 ---
  Widget _buildStep3SetValue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "How much love did this generate?",
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.redAccent.withOpacity(0.5 + (_lovesValue / 100)), size: 24 + (_lovesValue / 2)),
            const SizedBox(width: 16),
            Text('$_lovesValue Loves', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _lovesValue.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          label: _lovesValue.round().toString(),
          onChanged: (double newValue) => setState(() => _lovesValue = newValue.round()),
          activeColor: Colors.redAccent,
          inactiveColor: Colors.redAccent.withOpacity(0.3),
        ),
      ],
    );
  }

  // --- NEW: The final submit logic ---
  Future<void> _submitForm(GoodwillProcessingProvider provider, String userId) async {
    // Manually trigger save on the form
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
    } else {
      // If validation fails on step 2, jump back to it.
      setState(() => _currentStep = 1);
      return;
    }
    
    if (_actionType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a type of act.'), backgroundColor: Colors.redAccent),
      );
      setState(() => _currentStep = 0);
      return;
    }

    final success = await provider.submitGoodwill(
      performerUserId: userId,
      actionType: _actionType,
      description: _description,
      lovesValue: _lovesValue,
    );
    if (success && mounted) {
      _showSuccessOverlay(); // Show confetti and then pop
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit act: ${provider.error}')),
      );
    }
  }
}

// --- NEW: Confetti Overlay Widget for Success Animation ---
class ConfettiOverlay extends StatefulWidget {
  final AnimationController controller;
  const ConfettiOverlay({required this.controller, super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(100, (index) => _ConfettiParticle());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return IgnorePointer(
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.8 * widget.controller.value),
            body: Stack(
              children: [
                ..._particles.map((p) => p.build(context, widget.controller.value)),
                Center(
                  child: ScaleTransition(
                    scale: CurvedAnimation(parent: widget.controller, curve: Curves.elasticOut),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 100),
                        const SizedBox(height: 16),
                        const Text(
                          "Act Recorded!",
                          style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double startX, startY, endY, rotation, scale;
  final Duration delay;

  _ConfettiParticle()
      : color = Colors.primaries[Random().nextInt(Colors.primaries.length)].withOpacity(0.8),
        startX = Random().nextDouble() * 2 - 1,
        startY = -1.1 - (Random().nextDouble() * 0.5),
        endY = 1.1,
        rotation = Random().nextDouble() * 360,
        scale = Random().nextDouble() * 0.5 + 0.5,
        delay = Duration(milliseconds: Random().nextInt(500));

  Widget build(BuildContext context, double progress) {
    final t = (progress - (delay.inMilliseconds / 1000)).clamp(0.0, 1.0);
    final y = lerpDouble(startY, endY, t)!;
    
    return Positioned.fill(
      child: Align(
        alignment: Alignment(startX, y),
        child: Transform.rotate(
          angle: rotation * t,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 10,
              height: 10,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

