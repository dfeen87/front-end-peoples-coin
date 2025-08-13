// lib/pages/submit_goodwill_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:ui';

// --- MOCK DATA MODELS AND PROVIDERS (Refactored to use Riverpod) ---

class GoodwillAction {
  final String performerUserId;
  final String actionType;
  final String description;
  final int lovesValue;
  final Map<String, dynamic> contextualData;

  GoodwillAction({
    required this.performerUserId,
    required this.actionType,
    required this.description,
    required this.lovesValue,
    required this.contextualData,
  });
}

class GoodwillProcessingState {
  final bool isProcessingGoodwill;
  final String? error;
  final List<GoodwillAction> pendingSubmissions;

  GoodwillProcessingState({
    this.isProcessingGoodwill = false,
    this.error,
    this.pendingSubmissions = const [],
  });

  GoodwillProcessingState copyWith({
    bool? isProcessingGoodwill,
    String? error,
    List<GoodwillAction>? pendingSubmissions,
  }) {
    return GoodwillProcessingState(
      isProcessingGoodwill: isProcessingGoodwill ?? this.isProcessingGoodwill,
      error: error,
      pendingSubmissions: pendingSubmissions ?? this.pendingSubmissions,
    );
  }
}

class BackendStatus {
  final String nodeVersion;
  final bool metabolicActive;
  final bool nervousActive;
  final bool endocrineActive;
  final bool immuneActive;
  final List<String> recentEvents;

  BackendStatus({
    required this.nodeVersion,
    required this.metabolicActive,
    required this.nervousActive,
    required this.endocrineActive,
    required this.immuneActive,
    required this.recentEvents,
  });
}

// State Notifier to manage the goodwill submission process.
class GoodwillProcessingNotifier extends StateNotifier<GoodwillProcessingState> {
  GoodwillProcessingNotifier() : super(GoodwillProcessingState());

  Future<bool> submitGoodwill({
    required String performerUserId,
    required String actionType,
    required String description,
    required int lovesValue,
    required Map<String, dynamic> contextualData,
  }) async {
    state = state.copyWith(isProcessingGoodwill: true, error: null);
    final newSubmission = GoodwillAction(
      performerUserId: performerUserId,
      actionType: actionType,
      description: description,
      lovesValue: lovesValue,
      contextualData: contextualData,
    );
    state = state.copyWith(
      pendingSubmissions: [...state.pendingSubmissions, newSubmission],
    );

    try {
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      // On success, we would remove the item from the pending list and update the user's data.
      final updatedPendingList = List<GoodwillAction>.from(state.pendingSubmissions);
      updatedPendingList.remove(newSubmission);
      state = state.copyWith(
        isProcessingGoodwill: false,
        pendingSubmissions: updatedPendingList,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessingGoodwill: false,
        error: 'Failed to submit goodwill: $e',
      );
      return false;
    }
  }
}

// State Notifier to manage the backend status.
class BackendStatusNotifier extends StateNotifier<BackendStatus?> {
  BackendStatusNotifier() : super(null) {
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      state = BackendStatus(
        nodeVersion: '1.2.3-alpha',
        metabolicActive: true,
        nervousActive: true,
        endocrineActive: Random().nextBool(),
        immuneActive: true,
        recentEvents: const [
          'Metabolic system processed new batch.',
          'New goodwill act received.',
          'Endocrine system experiencing minor latency.',
        ],
      );
    } catch (e) {
      // In a real app, handle errors gracefully.
      state = null;
    }
  }
}

// MOCK User Provider for demonstration
class User {
  final String id;
  User({required this.id});
}
final userProvider = Provider<User?>((ref) => User(id: 'user123'));

// Riverpod providers
final goodwillProcessingProvider = StateNotifierProvider<GoodwillProcessingNotifier, GoodwillProcessingState>((ref) {
  return GoodwillProcessingNotifier();
});

final backendStatusProvider = StateNotifierProvider<BackendStatusNotifier, BackendStatus?>((ref) {
  return BackendStatusNotifier();
});

// --- WIDGETS ---

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

class SubmitGoodwillPage extends ConsumerStatefulWidget {
  const SubmitGoodwillPage({super.key});

  @override
  ConsumerState<SubmitGoodwillPage> createState() => _SubmitGoodwillPageState();
}

class _SubmitGoodwillPageState extends ConsumerState<SubmitGoodwillPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  String _actionType = '';
  String _description = '';
  String _impactLevel = 'Medium';

  int _lovesValue = 25;
  int _durationMinutes = 0;

  late final TabController _tabController;
  OverlayEntry? _celebrationOverlay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _celebrationOverlay?.remove();
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
    _celebrationOverlay = OverlayEntry(
      builder: (_) => const CyclingCelebrationOverlay(
        message: "Submission Successful!",
      ),
    );

    Overlay.of(context).insert(_celebrationOverlay!);

    // Schedule the removal of the overlay after the animation completes
    Future.delayed(const Duration(seconds: 4 * 3), () { // 4 seconds per effect, 3 effects
      _celebrationOverlay?.remove();
      _celebrationOverlay = null;
      if (mounted) {
        Navigator.of(context).pop();
      }
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

  Future<void> _submitForm() async {
    final currentUser = ref.read(userProvider);
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: User not found."), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    final success = await ref.read(goodwillProcessingProvider.notifier).submitGoodwill(
      performerUserId: currentUser.id,
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
      setState(() {
        _currentStep = 0;
        _actionType = '';
        _description = '';
        _impactLevel = 'Medium';
        _durationMinutes = 0;
        _lovesValue = 25;
      });
    } else if (mounted) {
      final error = ref.read(goodwillProcessingProvider).error;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit act: ${error ?? "Unknown error"}')),
      );
    }
  }

  VoidCallback _handleStepContinue() {
    return () async {
      final isStepValid = _validateAndSaveStep(_currentStep);
      if (!isStepValid) return;

      if (_currentStep < 4) {
        setState(() => _currentStep += 1);
      } else {
        await _submitForm();
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
    final goodwillState = ref.watch(goodwillProcessingProvider);

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
            onStepContinue: _handleStepContinue(),
            onStepCancel: _currentStep == 0 ? null : () => setState(() => _currentStep -= 1),
            controlsBuilder: _buildControls,
            steps: _buildSteps(),
            type: StepperType.vertical,
            physics: const ClampingScrollPhysics(),
          ),

          // Submission Status Tab
          const _BackendStatusTab(),
        ],
      ),
      floatingActionButton: goodwillState.isProcessingGoodwill
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
class _BackendStatusTab extends ConsumerWidget {
  const _BackendStatusTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendStatus = ref.watch(backendStatusProvider);
    final goodwillState = ref.watch(goodwillProcessingProvider);

    if (backendStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Node Version: ${backendStatus.nodeVersion}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _statusChip('Metabolic System', backendStatus.metabolicActive),
              _statusChip('Nervous System', backendStatus.nervousActive),
              _statusChip('Endocrine System', backendStatus.endocrineActive),
              _statusChip('Immune System', backendStatus.immuneActive),
            ],
          ),
          const Divider(height: 32, color: Colors.white24),
          const Text('Recent Events:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
          Expanded(
            child: ListView.builder(
              itemCount: backendStatus.recentEvents.length,
              itemBuilder: (context, index) {
                final event = backendStatus.recentEvents[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.bolt, color: Colors.amberAccent),
                  title: Text(event, style: const TextStyle(color: Colors.white70)),
                );
              },
            ),
          ),
          const Divider(height: 32, color: Colors.white24),
          const Text('Pending Goodwill Submissions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
          Expanded(
            child: _PendingSubmissionsList(pending: goodwillState.pendingSubmissions),
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
  final List<GoodwillAction> pending;

  const _PendingSubmissionsList({required this.pending});

  @override
  Widget build(BuildContext context) {
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
          subtitle: Text(submission.description, maxLines: 2, overflow: Text.ellipsis, style: const TextStyle(color: Colors.white70)),
          trailing: const Text('Pending', style: TextStyle(color: Colors.amberAccent)),
        );
      },
    );
  }
}

// --- MAIN APP ENTRY POINT ---

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Goodwill App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      home: const SubmitGoodwillPage(),
    );
  }
}

// ==========================================================
// COMBINED AND ENHANCED CELEBRATION OVERLAY
// ==========================================================

/// The main widget that cycles through multiple celebration effects.
/// It also displays a success message.
class CyclingCelebrationOverlay extends StatefulWidget {
  final Duration cycleDuration;
  final String message;

  const CyclingCelebrationOverlay({
    Key? key,
    this.cycleDuration = const Duration(seconds: 4),
    this.message = 'Submission Successful!',
  }) : super(key: key);

  @override
  State<CyclingCelebrationOverlay> createState() => _CyclingCelebrationOverlayState();
}

class _CyclingCelebrationOverlayState extends State<CyclingCelebrationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Widget Function(Animation<double>)> _effectsBuilders = [];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _effectsBuilders.addAll([
      (anim) => ConfettiOverlay(controller: anim),
      (anim) => HeartsOverlay(controller: anim),
      (anim) => SparklesOverlay(controller: anim),
    ]);

    _controller = AnimationController(vsync: this, duration: widget.cycleDuration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _effectsBuilders.length;
        });
        _controller.forward(from: 0.0);
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builder = _effectsBuilders[_currentIndex];
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // The cycling particle effects
            builder(_controller),
            
            // The success message text
            Align(
              alignment: Alignment.center,
              child: AnimatedOpacity(
                opacity: _controller.value > 0.5 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  widget.message,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        blurRadius: 8.0,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CONFETTI EFFECT ---

class ConfettiOverlay extends StatelessWidget {
  final Animation<double> controller;

  const ConfettiOverlay({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: ConfettiPainter(progress: controller.value),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final int particleCount = (progress * 100).toInt();

    for (int i = 0; i < particleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height * (1 - progress);
      paint.color = Color.fromARGB(
        (255 * (1 - progress)).toInt(),
        _random.nextInt(256),
        _random.nextInt(256),
        _random.nextInt(256),
      );

      final radius = _random.nextDouble() * 4 + 2;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

// --- HEARTS EFFECT ---

class HeartsOverlay extends StatelessWidget {
  final Animation<double> controller;

  const HeartsOverlay({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: HeartsPainter(progress: controller.value),
      ),
    );
  }
}

class HeartsPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  HeartsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    int particleCount = (progress * 40).toInt();

    for (int i = 0; i < particleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = size.height - (_random.nextDouble() * size.height * progress);
      final scale = 0.5 + _random.nextDouble();

      paint.color = Colors.red.withOpacity(1 - progress);

      _drawHeart(canvas, paint, Offset(x, y), 10 * scale);
    }
  }

  void _drawHeart(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();

    final double x = center.dx;
    final double y = center.dy;
    final double s = size / 2;

    path.moveTo(x, y + s / 4);
    path.cubicTo(x, y, x - s, y, x - s, y + s / 2);
    path.cubicTo(x - s, y + s, x, y + s * 1.5, x, y + s * 2);
    path.cubicTo(x, y + s * 1.5, x + s, y + s, x + s, y + s / 2);
    path.cubicTo(x + s, y, x, y, x, y + s / 4);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeartsPainter oldDelegate) => oldDelegate.progress != progress;
}

// --- SPARKLES EFFECT ---

class SparklesOverlay extends StatelessWidget {
  final Animation<double> controller;

  const SparklesOverlay({required this.controller, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: SparklesPainter(progress: controller.value),
      ),
    );
  }
}

class SparklesPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  SparklesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final int sparkleCount = (progress * 80).toInt();

    for (int i = 0; i < sparkleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;

      paint.color = Colors.white.withOpacity(1 - progress);

      _drawSparkle(canvas, paint, Offset(x, y), 3 + 2 * (1 - progress));
    }
  }

  void _drawSparkle(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    final s = size / 2;

    path.moveTo(center.dx, center.dy - s);
    path.lineTo(center.dx + s / 3, center.dy - s / 3);
    path.lineTo(center.dx + s, center.dy);
    path.lineTo(center.dx + s / 3, center.dy + s / 3);
    path.lineTo(center.dx, center.dy + s);
    path.lineTo(center.dx - s / 3, center.dy + s / 3);
    path.lineTo(center.dx - s, center.dy);
    path.lineTo(center.dx - s / 3, center.dy - s / 3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklesPainter oldDelegate) => oldDelegate.progress != progress;
}

