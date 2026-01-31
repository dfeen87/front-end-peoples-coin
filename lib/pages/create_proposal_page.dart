// lib/pages/create_proposal_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Assume these models and providers exist in your project
import '../models/proposal_to_send.dart';
import '../models/user.dart' as app_user;
import '../service/api_service.dart';

// -- RIVERPOD PROVIDERS --
// A simple provider for the form's state. We'll use a `StateProvider` for a simple value.
final proposalTitleProvider = StateProvider<String>((ref) => '');
final proposalDescriptionProvider = StateProvider<String>((ref) => '');
final proposalTypeProvider = StateProvider<String>((ref) => 'General');
final voteEndDateProvider = StateProvider<DateTime?>((ref) => null);
final proposalDetailsProvider = StateProvider<String>((ref) => '');

// Firebase Auth provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Current user provider that watches Firebase Auth state
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// App user provider that converts Firebase User to your app's User model
final authUserProvider = Provider<app_user.AppUser?>((ref) {
  final asyncUser = ref.watch(currentUserProvider);
  return asyncUser.when(
    data: (firebaseUser) => firebaseUser != null 
        ? app_user.AppUser(id: firebaseUser.uid, email: firebaseUser.email ?? '') 
        : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// StateNotifier for the submission logic and state.
class ProposalSubmitNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  final FirebaseAuth _firebaseAuth;

  ProposalSubmitNotifier(this._apiService, this._firebaseAuth) 
      : super(const AsyncValue.data({'success': false}));

  Future<void> submitProposal({
    required ProposalToSend proposal,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Get the current user's ID token
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken();
      
      // Make API call to your Flask backend
      final response = await _apiService.createProposal(proposal, idToken);
      
      if (response['success'] == true) {
        state = AsyncValue.data({'success': true, 'data': response});
      } else {
        throw Exception(response['message'] ?? 'Failed to create proposal');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final proposalSubmitProvider = StateNotifierProvider<ProposalSubmitNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => ProposalSubmitNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(firebaseAuthProvider),
  ),
);

// -- WIDGETS --

typedef ProposalFormCompletedCallback = void Function();

const Map<String, (IconData, Color)> _proposalTypes = {
  'General': (Icons.lightbulb_outline, Colors.blueAccent),
  'Funding': (Icons.monetization_on_outlined, Colors.green),
  'Policy': (Icons.gavel_outlined, Colors.purpleAccent),
  'Community': (Icons.groups_outlined, Colors.orange),
};

class CreateProposalPageContent extends ConsumerStatefulWidget {
  final ProposalFormCompletedCallback onFormCompleted;

  const CreateProposalPageContent({super.key, required this.onFormCompleted});

  @override
  ConsumerState<CreateProposalPageContent> createState() => _CreateProposalPageContentState();
}

class _CreateProposalPageContentState extends ConsumerState<CreateProposalPageContent> with TickerProviderStateMixin {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  int _currentStep = 0;
  final TextEditingController _detailsController = TextEditingController();

  late final AnimationController _stepAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _stepAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnimation = CurvedAnimation(parent: _stepAnimationController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_fadeAnimation);
    _stepAnimationController.forward();
    
    // Set the initial value for the details controller from the provider if it exists
    _detailsController.text = ref.read(proposalDetailsProvider);
  }

  @override
  void dispose() {
    _stepAnimationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(voteEndDateProvider) ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.tertiary,
              onPrimary: Theme.of(context).colorScheme.onTertiary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            dialogBackgroundColor: Theme.of(context).colorScheme.background,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != ref.read(voteEndDateProvider)) {
      ref.read(voteEndDateProvider.notifier).state = picked;
    }
  }

  Future<void> _submitForm() async {
    final user = ref.read(authUserProvider);
    final isSubmitting = ref.read(proposalSubmitProvider).isLoading;

    if (user == null || isSubmitting) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not logged in or a submission is already in progress.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate required fields
    final title = ref.read(proposalTitleProvider);
    final description = ref.read(proposalDescriptionProvider);
    
    if (title.isEmpty || description.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final proposalToSend = ProposalToSend(
      proposerUserId: user.uid,
      title: title,
      description: description,
      proposalType: ref.read(proposalTypeProvider),
      details: ref.read(proposalDetailsProvider).isNotEmpty 
          ? {'custom_details': ref.read(proposalDetailsProvider)} 
          : null,
      voteEndTime: ref.read(voteEndDateProvider),
    );

    await ref.read(proposalSubmitProvider.notifier).submitProposal(
      proposal: proposalToSend,
    );

    final submissionResult = ref.read(proposalSubmitProvider);
    if (submissionResult.hasValue && submissionResult.value!['success'] == true) {
      if (mounted) {
        await _showSuccessAndExit();
      }
    } else if (submissionResult.hasError && mounted) {
      String errorMessage = 'Submission failed';
      if (submissionResult.error is Exception) {
        errorMessage = submissionResult.error.toString().replaceFirst('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _submitForm,
          ),
        ),
      );
    }
  }

  Future<void> _showSuccessAndExit() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SuccessDialog(),
    );
    
    // Clear all the form state providers
    ref.invalidate(proposalTitleProvider);
    ref.invalidate(proposalDescriptionProvider);
    ref.invalidate(proposalTypeProvider);
    ref.invalidate(voteEndDateProvider);
    ref.invalidate(proposalDetailsProvider);
    ref.invalidate(proposalSubmitProvider);
    
    widget.onFormCompleted();
  }

  void _goToStep(int step) async {
    await _stepAnimationController.reverse();
    setState(() => _currentStep = step);
    _stepAnimationController.forward();
  }

  void _nextStep() async {
    bool isValid = false;
    if (_currentStep == 0) {
      isValid = _formKeyStep1.currentState?.validate() ?? false;
    } else if (_currentStep == 1) {
      isValid = true; // Step 2 has no validation fields
    }

    if (!isValid) return;

    await _stepAnimationController.reverse();
    setState(() => _currentStep += 1);
    _stepAnimationController.forward();
  }

  void _previousStep() async {
    if (_currentStep == 0) return;
    await _stepAnimationController.reverse();
    setState(() => _currentStep -= 1);
    _stepAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitting = ref.watch(proposalSubmitProvider).isLoading;
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return _buildAuthRequiredView(theme);
        }
        return _buildMainContent(theme, isSubmitting);
      },
      loading: () => _buildLoadingView(theme),
      error: (error, _) => _buildErrorView(theme, error.toString()),
    );
  }

  Widget _buildAuthRequiredView(ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Create New Proposal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onFormCompleted,
            tooltip: 'Close',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Authentication Required',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign in to create a proposal',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onFormCompleted,
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView(ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Create New Proposal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onFormCompleted,
            tooltip: 'Close',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.tertiary),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, String error) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Create New Proposal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onFormCompleted,
            tooltip: 'Close',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Authentication Error',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onFormCompleted,
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, bool isSubmitting) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Create New Proposal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onFormCompleted,
            tooltip: 'Close',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _stepAnimationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStepperIndicator(theme),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Builder(
                    builder: (context) {
                      switch (_currentStep) {
                        case 0:
                          return _buildStep1Vision(theme);
                        case 1:
                          return _buildStep2Details(theme);
                        case 2:
                          return _buildStep3Review(theme);
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ),
              _buildControls(theme, isSubmitting),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperIndicator(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepIndicator(theme, 0, 'Vision'),
        Expanded(child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.2), height: 1)),
        _buildStepIndicator(theme, 1, 'Details'),
        Expanded(child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.2), height: 1)),
        _buildStepIndicator(theme, 2, 'Review'),
      ],
    );
  }

  Widget _buildStepIndicator(ThemeData theme, int index, String label) {
    final isCurrent = _currentStep == index;
    final isCompleted = _currentStep > index;

    return GestureDetector(
      onTap: () => _goToStep(index),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent ? theme.colorScheme.tertiary : isCompleted ? theme.colorScheme.primary : theme.colorScheme.surface.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              color: isCurrent ? theme.colorScheme.onTertiary : isCompleted ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isCurrent ? theme.colorScheme.tertiary : isCompleted ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Vision(ThemeData theme) {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Give your proposal a powerful title and a clear description.', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: ref.read(proposalTitleProvider),
            decoration: _buildInputDecoration(theme, 'Proposal Title'),
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
            validator: (val) => val == null || val?.isEmpty == true ? 'A great proposal starts with a strong title.' : null,
            onChanged: (val) => ref.read(proposalTitleProvider.notifier).state = val,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: ref.read(proposalDescriptionProvider),
            decoration: _buildInputDecoration(theme, 'Description'),
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
            maxLines: 5,
            validator: (val) => val == null || val?.isEmpty == true ? 'Please provide a clear description of your idea.' : null,
            onChanged: (val) => ref.read(proposalDescriptionProvider.notifier).state = val,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Details(ThemeData theme) {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a category and set a voting deadline.', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          Text('Proposal Type', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            physics: const NeverScrollableScrollPhysics(),
            children: _proposalTypes.entries.map((entry) {
              final isSelected = ref.watch(proposalTypeProvider) == entry.key;
              return InkWell(
                onTap: () => ref.read(proposalTypeProvider.notifier).state = entry.key,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? entry.value.$2.withOpacity(0.8) : theme.colorScheme.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? entry.value.$2 : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(entry.value.$1, color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Text(
                        entry.key, 
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: theme.colorScheme.surface.withOpacity(0.1),
            title: Text(
              ref.watch(voteEndDateProvider) == null 
                  ? 'Set a voting deadline (Optional)' 
                  : 'Voting Ends: ${DateFormat.yMMMd().format(ref.watch(voteEndDateProvider)!)}',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
            ),
            trailing: const Icon(Icons.calendar_today, color: Colors.white70),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _detailsController,
            decoration: _buildInputDecoration(theme, 'Additional Details (Optional)'),
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
            maxLines: 5,
            onChanged: (val) => ref.read(proposalDetailsProvider.notifier).state = val,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Review(ThemeData theme) {
    final title = ref.read(proposalTitleProvider);
    final description = ref.read(proposalDescriptionProvider);
    final type = ref.read(proposalTypeProvider);
    final endDate = ref.read(voteEndDateProvider);
    final details = ref.read(proposalDetailsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewRow(theme, 'Title', title),
          _buildReviewRow(theme, 'Description', description),
          _buildReviewRow(theme, 'Type', type),
          _buildReviewRow(theme, 'Voting Ends', endDate != null ? DateFormat.yMMMd().format(endDate) : 'Not Set'),
          if (details.isNotEmpty) ...[
            _buildReviewRow(theme, 'Additional Details', details),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Divider(color: Colors.white24, height: 16),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(ThemeData theme, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      floatingLabelStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.tertiary),
      filled: true,
      fillColor: theme.colorScheme.surface.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.tertiary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
    );
  }

  Widget _buildControls(ThemeData theme, bool isSubmitting) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          if (_currentStep > 0)
            TextButton(
              onPressed: isSubmitting ? null : _previousStep,
              child: Text('Back', style: TextStyle(color: theme.colorScheme.onSurface)),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: isSubmitting ? null : () {
              if (_currentStep == 2) {
                _submitForm();
              } else {
                _nextStep();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.tertiary,
              foregroundColor: theme.colorScheme.onTertiary,
              disabledBackgroundColor: theme.colorScheme.tertiary.withOpacity(0.4),
              disabledForegroundColor: theme.colorScheme.onTertiary.withOpacity(0.4),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(_currentStep == 2 ? 'Submit' : 'Next'),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends ConsumerStatefulWidget {
  const _SuccessDialog();

  @override
  ConsumerState<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends ConsumerState<_SuccessDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
      child: AlertDialog(
        backgroundColor: theme.colorScheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 70),
            const SizedBox(height: 20),
            Text(
              'Proposal Submitted!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'It is now live for the community to review and vote on.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
