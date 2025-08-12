import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../state/goodwill_processing_provider.dart';
import '../state/user_provider.dart';
import '../service/backend_status_service.dart';

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

class _SubmitGoodwillPageState extends State<SubmitGoodwillPage> with TickerProviderStateMixin, SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  String _actionType = '';
  String _description = '';
  String _impactLevel = 'Medium';

  int _lovesValue = 25;
  int _durationMinutes = 0;

  late final AnimationController _celebrationController;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _tabController.dispose();
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

    final overlayEntry = OverlayEntry(
      builder: (_) => CyclingCelebrationOverlay(controller: _celebrationController),
    );

    overlay.insert(overlayEntry);
    _celebrationController.forward(from: 0.0);

    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
      if (mounted) Navigator.of(context).pop();
    });
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

  Future<void> _submitForm(GoodwillProcessingProvider provider) async {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not found."), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final success = await provider.submitGoodwill(
      performerUserId: currentUser.id!,
      actionType: _actionType,
      description: _description.trim(),
      lovesValue: _lovesValue,
      contextualData: {
        'duration_minutes': _durationMinutes,
        'impact_level': _impactLevel,
      },
    );

    if (success && mounted) {
      _showSuccessOverlay();

      // Optionally: reset form and stepper
      setState(() {
        _currentStep = 0;
        _actionType = '';
        _description = '';
        _impactLevel = 'Medium';
        _durationMinutes = 0;
        _lovesValue = 25;
      });

    } else if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit act: ${provider.error}')),
      );
    }
  }

  VoidCallback _handleStepContinue(GoodwillProcessingProvider provider) {
    return () async {
      final isStepValid = _validateAndSaveStep(_currentStep);
      if (!isStepValid) return;

      if (_currentStep < 4) {
        setState(() => _currentStep += 1);
      } else {
        await _submitForm(provider);
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

  // --- Step Content Widgets ---

  Widget _buildStep1ChooseAct() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _actTypes.entries.map((entry) {
        final selected = _actionType == entry.key;
        return ChoiceChip(
          label: Text(entry.key),
          avatar: Icon(entry.value, color: selected ? Colors.white : Colors.black54),
          selected: selected,
          onSelected: (v) {
            setState(() => _actionType = v ? entry.key : '');
          },
          selectedColor: Colors.amber[700],
          backgroundColor: Colors.grey[800],
          labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
        );
      }).toList(),
    );
  }

  Widget _buildStep2Describe() {
    return Form(
      key: _formKey,
      child: TextFormField(
        initialValue: _description,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Describe your act of goodwill...',
          filled: true,
          fillColor: Colors.white12,
          border: OutlineInputBorder(),
        ),
        validator: (val) => val == null || val.trim().isEmpty ? 'Description cannot be empty' : null,
        onSaved: (val) => _description = val ?? '',
      ),
    );
  }

  Widget _buildStep3LovesSlider() {
    return Column(
      children: [
        Text('Assign a Loves Value: $_lovesValue', style: const TextStyle(color: Colors.white)),
        Slider(
          min: 1,
          max: 100,
          divisions: 99,
          value: _lovesValue.toDouble(),
          onChanged: (val) => setState(() => _lovesValue = val.toInt()),
          activeColor: Colors.amber,
          inactiveColor: Colors.amber[200],
        ),
      ],
    );
  }

  Widget _buildStep4DurationImpact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _impactLevel,
          decoration: const InputDecoration(
            labelText: 'Impact Level',
            filled: true,
            fillColor: Colors.white12,
          ),
          items: ['Low', 'Medium', 'High']
              .map((level) => DropdownMenuItem(value: level, child: Text(level)))
              .toList(),
          onChanged: (val) => setState(() => _impactLevel = val ?? 'Medium'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Duration (minutes)',
            filled: true,
            fillColor: Colors.white12,
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null) setState(() => _durationMinutes = parsed);
          },
          validator: (val) {
            if (val == null || val.isEmpty) return 'Duration required';
            final parsed = int.tryParse(val);
            if (parsed == null || parsed <= 0) return 'Enter valid positive minutes';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep5Summary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type: $_actionType', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Text('Description:', style: const TextStyle(color: Colors.white70)),
        Text(_description, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Text('Loves Value: $_lovesValue', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Text('Impact Level: $_impactLevel', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Text('Duration: $_durationMinutes minutes', style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  // --- New backend status tab ---

  @override
  Widget build(BuildContext context) {
    final goodwillProvider = context.watch<GoodwillProcessingProvider>();
    final backendStatusService = context.watch<BackendStatusService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Bright Act'),
        backgroundColor: Colors.amber[800],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Submit Act'),
            Tab(icon: Icon(Icons.cloud_queue), text: 'Submission Status'),
          ],
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: TabBarView(
        controller: _tabController,
        children: [
          // Submit Act Form
          Stepper(
            currentStep: _currentStep,
            onStepContinue: _handleStepContinue(goodwillProvider),
            onStepCancel: _currentStep == 0 ? null : () => setState(() => _currentStep -= 1),
            controlsBuilder: _buildControls,
            steps: _buildSteps(),
            type: StepperType.vertical,
            physics: const ClampingScrollPhysics(),
          ),

          // Submission Status Tab
          _BackendStatusTab(
            backendStatusService: backendStatusService,
            goodwillProvider: goodwillProvider,
          ),
        ],
      ),
      floatingActionButton: goodwillProvider.isProcessingGoodwill
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.amber,
              child: const CircularProgressIndicator(color: Colors.white),
            )
          : null,
    );
  }
}

/// Widget to display backend status & pending submissions nicely
class _BackendStatusTab extends StatelessWidget {
  final BackendStatusService backendStatusService;
  final GoodwillProcessingProvider goodwillProvider;

  const _BackendStatusTab({
    required this.backendStatusService,
    required this.goodwillProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (backendStatusService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (backendStatusService.error != null) {
      return Center(child: Text('Error: ${backendStatusService.error}', style: const TextStyle(color: Colors.redAccent)));
    }

    final status = backendStatusService.currentStatus;
    if (status == null) {
      return const Center(child: Text('No backend status available.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Node Version: ${status.nodeVersion}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _statusChip('Metabolic System', status.metabolicActive),
              _statusChip('Nervous System', status.nervousActive),
              _statusChip('Endocrine System', status.endocrineActive),
              _statusChip('Immune System', status.immuneActive),
            ],
          ),
          const Divider(height: 32, color: Colors.white24),
          const Text('Recent Events:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
          Expanded(
            child: ListView.builder(
              itemCount: status.recentEvents.length,
              itemBuilder: (context, index) {
                final event = status.recentEvents[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.bolt, color: Colors.amberAccent),
                  title: Text(event, style: const TextStyle(color: Colors.white70)),
                );
              },
            ),
          ),

          // Pending goodwill submissions (show from GoodwillProcessingProvider)
          const Divider(height: 32, color: Colors.white24),
          const Text('Pending Goodwill Submissions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
          Expanded(
            child: _PendingSubmissionsList(goodwillProvider: goodwillProvider),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool active) {
    return Chip(
      label: Text(label),
      avatar: Icon(
        active ? Icons.check_circle : Icons.cancel,
        color: active ? Colors.greenAccent : Colors.redAccent,
      ),
      backgroundColor: Colors.grey[800],
      labelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

/// A simple list widget showing pending goodwill submissions
class _PendingSubmissionsList extends StatelessWidget {
  final GoodwillProcessingProvider goodwillProvider;

  const _PendingSubmissionsList({required this.goodwillProvider});

  @override
  Widget build(BuildContext context) {
    // For this demo, let's assume goodwillProvider has a List<GoodwillAction> pendingSubmissions.
    // You would need to add this pending queue tracking in your GoodwillProcessingProvider.
    final pending = goodwillProvider.pendingSubmissions;

    if (pending.isEmpty) {
      return const Center(child: Text('No pending submissions.', style: TextStyle(color: Colors.white70)));
    }

    return ListView.separated(
      itemCount: pending.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white24),
      itemBuilder: (context, index) {
        final submission = pending[index];
        return ListTile(
          leading: const Icon(Icons.hourglass_empty, color: Colors.amber),
          title: Text(submission.actionType, style: const TextStyle(color: Colors.amber)),
          subtitle: Text(submission.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
          trailing: const Text('Pending', style: TextStyle(color: Colors.amberAccent)),
        );
      },
    );
  }
}

