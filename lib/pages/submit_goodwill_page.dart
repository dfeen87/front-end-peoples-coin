// lib/pages/submit_goodwill_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';

import '../state/goodwill_processing_provider.dart';
import '../state/user_provider.dart';
import '../models/goodwill_action_to_send.dart';

// --- Predefined act types with icons for UI clarity ---
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

  int _currentStep = 0;

  String _actionType = '';
  String _description = '';
  String _impactLevel = 'Medium';

  int _lovesValue = 25;
  int _durationMinutes = 0;

  late final AnimationController _confettiController;

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

  void _updateLovesScore() {
    int baseFromDescription = (_description.trim().length / 2).clamp(10, 50).toInt();
    int durationScore = ((_durationMinutes.clamp(0, 120) / 120) * 50).toInt();

    final impactMultipliers = {
      'Low': 0.8,
      'Medium': 1.0,
      'High': 1.2,
    };
    double impactMultiplier = impactMultipliers[_impactLevel] ?? 1.0;

    final calculatedLoves = ((baseFromDescription + durationScore) * impactMultiplier).clamp(1, 100).toInt();

    setState(() {
      _lovesValue = calculatedLoves;
    });
  }

  void _showSuccessOverlay() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(builder: (context) => ConfettiOverlay(controller: _confettiController));
    overlay.insert(overlayEntry);
    _confettiController.forward(from: 0.0);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
      if (mounted) Navigator.of(context).pop();
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
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
      body: Consumer<GoodwillProcessingProvider>(
        builder: (context, provider, _) {
          final currentUser = context.watch<UserProvider>().currentUser;
          if (currentUser == null) {
            return const Center(child: Text("User not logged in or data not loaded.", style: TextStyle(color: Colors.white70)));
          }

          return Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.black.withOpacity(0.3),
              colorScheme: ColorScheme.dark(
                primary: Colors.amber[700]!,
                onPrimary: Colors.black,
              ),
            ),
            child: Stepper(
              type: StepperType.horizontal,
              physics: const ClampingScrollPhysics(),
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: _handleStepContinue(provider, currentUser.id),
              onStepCancel: () {
                if (_currentStep > 0) setState(() => _currentStep -= 1);
              },
              controlsBuilder: _buildControls,
              steps: _buildSteps(),
            ),
          );
        },
      ),
    );
  }

  bool _validateAndSaveStep(int step) {
    switch (step) {
      case 0:
        if (_actionType.isEmpty) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please choose a type of act.'), backgroundColor: Colors.redAccent),
          );
          return false;
        }
        return true;
      case 1:
        if (!(_formKey.currentState?.validate() ?? false)) return false;
        _formKey.currentState!.save();
        _updateLovesScore();
        return true;
      case 3:
        if (_durationMinutes <= 0) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid duration (minutes).'), backgroundColor: Colors.redAccent),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  VoidCallback _handleStepContinue(GoodwillProcessingProvider provider, String userId) {
    return () {
      final isStepValid = _validateAndSaveStep(_currentStep);
      if (!isStepValid) return;

      if (_currentStep < 4) {
        setState(() => _currentStep += 1);
      } else {
        _submitForm(provider, userId);
      }
    };
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: details.onStepCancel,
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: const Text('Back', style: TextStyle(color: Colors.white70)),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: details.onStepContinue,
            icon: Icon(_currentStep == 4 ? Icons.check_circle_outline : Icons.arrow_forward),
            label: Text(_currentStep == 4 ? 'Submit' : 'Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[800],
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

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
        content: _buildStep3LovesSlider(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Details', style: TextStyle(color: Colors.white)),
        content: _buildStep4DurationImpact(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Confirm', style: TextStyle(color: Colors.white)),
        content: _buildStep5Summary(),
        isActive: _currentStep >= 4,
        state: _currentStep > 4 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

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
          spacing: 8,
          runSpacing: 8,
          children: _actTypes.entries.map((entry) {
            final selected = _actionType == entry.key;
            return ChoiceChip(
              label: Text(entry.key),
              avatar: Icon(entry.value, color: selected ? Colors.black : Colors.white70),
              selected: selected,
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() => _actionType = entry.key);
                }
              },
              selectedColor: Colors.amber[700],
              backgroundColor: Colors.white.withOpacity(0.1),
              labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
            );
          }).toList(),
        ),
      ],
    );
  }

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
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe the act of goodwill...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
            ),
            style: const TextStyle(color: Colors.white),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please describe the act.' : null,
            onChanged: (val) {
              _description = val;
              _updateLovesScore();
            },
            onSaved: (val) => _description = val ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildStep3LovesSlider() {
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
            Icon(Icons.favorite, color: Colors.redAccent.withOpacity(0.5 + (_lovesValue / 200)), size: 24 + (_lovesValue / 2)),
            const SizedBox(width: 16),
            Text(
              '$_lovesValue Loves',
              style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: _lovesValue.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          label: _lovesValue.toString(),
          onChanged: (val) {
            setState(() => _lovesValue = val.round());
          },
          activeColor: Colors.redAccent,
          inactiveColor: Colors.redAccent.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildStep4DurationImpact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Duration and Impact",
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('duration'),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Duration (minutes)',
            hintText: 'How long did this act last?',
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null) {
              setState(() {
                _durationMinutes = parsed;
                _updateLovesScore();
              });
            }
          },
          onSaved: (val) {
            _durationMinutes = int.tryParse(val ?? '') ?? 0;
          },
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Impact Level',
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          value: _impactLevel,
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white),
          items: ['Low', 'Medium', 'High']
              .map((level) => DropdownMenuItem(value: level, child: Text(level)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _impactLevel = val;
                _updateLovesScore();
              });
            }
          },
          onSaved: (val) {
            if (val != null) _impactLevel = val;
          },
        ),
      ],
    );
  }

  Widget _buildStep5Summary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Review and Confirm",
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildSummaryRow('Type', _actionType),
        _buildSummaryRow('Description', _description),
        _buildSummaryRow('Duration', '$_durationMinutes minutes'),
        _buildSummaryRow('Impact', _impactLevel),
        _buildSummaryRow('Loves', '$_lovesValue'),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm(GoodwillProcessingProvider provider, String userId) async {
    final contextualData = {
      'duration_minutes': _durationMinutes,
      'impact_level': _impactLevel,
    };

    final actionToSend = GoodwillActionToSend(
      performerUserId: userId,
      actionType: _actionType,
      description: _description.trim(),
      lovesValue: _lovesValue,
      contextualData: contextualData,
      timestamp: DateTime.now(),
    );
    
    final success = await provider.submitGoodwill(
      performerUserId: actionToSend.performerUserId,
      actionType: actionToSend.actionType,
      description: actionToSend.description,
      lovesValue: actionToSend.lovesValue,
      contextualData: actionToSend.contextualData,
    );

    if (success && mounted) {
      _showSuccessOverlay();
    } else if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit act: ${provider.error}')),
      );
    }
  }
}

// --- Confetti Overlay for celebration effect ---
class ConfettiOverlay extends StatefulWidget {
  final AnimationController controller;
  const ConfettiOverlay({super.key, required this.controller});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(100, (_) => _ConfettiParticle());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
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
                      children: const [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 100),
                        SizedBox(height: 16),
                        Text(
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
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
