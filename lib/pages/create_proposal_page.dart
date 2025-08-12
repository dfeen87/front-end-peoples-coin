// lib/pages/create_proposal_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../state/proposal_provider.dart';
import '../models/proposal_to_send.dart';
import '../state/user_provider.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;

typedef ProposalFormCompletedCallback = void Function();

const Map<String, (IconData, Color)> _proposalTypes = {
  'General': (Icons.lightbulb_outline, Colors.blueAccent),
  'Funding': (Icons.monetization_on_outlined, Colors.green),
  'Policy': (Icons.gavel_outlined, Colors.purpleAccent),
  'Community': (Icons.groups_outlined, Colors.orange),
};

class CreateProposalPageContent extends StatefulWidget {
  final ProposalFormCompletedCallback onFormCompleted;

  const CreateProposalPageContent({super.key, required this.onFormCompleted});

  @override
  State<CreateProposalPageContent> createState() => _CreateProposalPageContentState();
}

class _CreateProposalPageContentState extends State<CreateProposalPageContent> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  String _title = '';
  String _description = '';
  String _proposalType = 'General';
  DateTime? _voteEndDate;
  final TextEditingController _detailsController = TextEditingController();

  late final AnimationController _stepAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _stepAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnimation = CurvedAnimation(parent: _stepAnimationController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_fadeAnimation);
    _stepAnimationController.forward();
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
      initialDate: _voteEndDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.amber[700]!,
              onPrimary: Colors.black,
              surface: Colors.grey[850]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _voteEndDate) {
      setState(() => _voteEndDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      _formKey.currentState!.save();

      final authProvider = context.read<MyAppAuthProvider.AuthProvider>();
      final currentUser = authProvider.user;
      final idToken = await currentUser?.getIdToken();

      if (currentUser == null || idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not logged in or token expired.')));
        }
        setState(() => _isSubmitting = false);
        return;
      }

      final proposalToSend = ProposalToSend(
        proposerUserId: currentUser.uid,
        title: _title,
        description: _description,
        proposalType: _proposalType,
        details: _detailsController.text.isNotEmpty ? {'custom_details': _detailsController.text} : null,
        voteEndTime: _voteEndDate,
      );

      final result = await context.read<ProposalProvider>().createProposal(proposal: proposalToSend, idToken: idToken);

      setState(() => _isSubmitting = false);

      if (result['success'] && mounted) {
        await _showSuccessAndExit();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: ${result['error']}')));
      }
    } else {
      setState(() => _currentStep = 0);
    }
  }

  Future<void> _showSuccessAndExit() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SuccessDialog(),
    );
    widget.onFormCompleted();
  }

  void _goToStep(int step) async {
    await _stepAnimationController.reverse();
    setState(() => _currentStep = step);
    _stepAnimationController.forward();
  }

  void _nextStep() async {
    final isValidStep0 = _formKey.currentState?.validate() ?? false;
    if (_currentStep == 0 && !isValidStep0) return;

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
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: (step) => _goToStep(step),
          controlsBuilder: (context, details) {
            final isLastStep = _currentStep == 2;
            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _isSubmitting ? null : _previousStep,
                      child: const Text('Back'),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : () {
                      if (isLastStep) {
                        _submitForm();
                      } else {
                        _nextStep();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[800],
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.amber.withOpacity(0.4),
                      disabledForegroundColor: Colors.black38,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(isLastStep ? 'Submit' : 'Next'),
                  ),
                ],
              ),
            );
          },
        steps: [
          _buildStep('Define', _buildStep1Define(), 0),
          _buildStep('Detail', _buildStep2Detail(), 1),
          _buildStep('Review', _buildStep3Review(), 2),
        ],
      ),
    ),
    );
  }

  Step _buildStep(String title, Widget content, int index) {
    return Step(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: content,
      isActive: _currentStep >= index,
      state: _currentStep > index ? StepState.complete : StepState.indexed,
    );
  }

  Widget _buildStep1Define() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            initialValue: _title,
            decoration: _buildInputDecoration('Proposal Title'),
            style: const TextStyle(color: Colors.white),
            validator: (val) => val == null || val.isEmpty ? 'Please enter a title.' : null,
            onSaved: (val) => _title = val!,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _description,
            decoration: _buildInputDecoration('Description'),
            style: const TextStyle(color: Colors.white),
            maxLines: 5,
            validator: (val) => val == null || val.isEmpty ? 'Please enter a description.' : null,
            onSaved: (val) => _description = val!,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Detail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Proposal Type', style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          physics: const NeverScrollableScrollPhysics(),
          children: _proposalTypes.entries.map((entry) {
            final isSelected = _proposalType == entry.key;
            return InkWell(
              onTap: () => setState(() => _proposalType = entry.key),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? entry.value.$2.withOpacity(0.8) : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? entry.value.$2 : Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(entry.value.$1, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(entry.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Colors.white.withOpacity(0.1),
          title: Text(
            _voteEndDate == null ? 'Select Vote End Date (Optional)' : 'Vote Ends: ${DateFormat.yMMMd().format(_voteEndDate!)}',
            style: const TextStyle(color: Colors.white),
          ),
          trailing: const Icon(Icons.calendar_today, color: Colors.white70),
          onTap: () => _selectDate(context),
        ),
      ],
    );
  }

  Widget _buildStep3Review() {
    _formKey.currentState?.save();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewRow('Title', _title),
          _buildReviewRow('Description', _description),
          _buildReviewRow('Type', _proposalType),
          _buildReviewRow('Voting Ends', _voteEndDate != null ? DateFormat.yMMMd().format(_voteEndDate!) : 'Not Set'),
          if (_detailsController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildReviewRow('Additional Details', _detailsController.text),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const Divider(color: Colors.white24, height: 16),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog();

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      child: AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 70),
            const SizedBox(height: 20),
            const Text(
              'Proposal Submitted!',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'It is now live for the community to review and vote on.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

