// lib/pages/create_proposal_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/proposal_to_send.dart';
import '../state/proposal_provider.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;

class CreateProposalPage extends StatefulWidget {
  const CreateProposalPage({super.key});

  @override
  State<CreateProposalPage> createState() => _CreateProposalPageState();
}

class _CreateProposalPageState extends State<CreateProposalPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // State for our dropdown and date picker
  String? _selectedProposalType;
  DateTime? _voteEndDate;
  final List<String> _proposalTypes = ['Rule Change', 'Community Grant', 'Feature Request', 'General'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _voteEndDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _voteEndDate) {
      setState(() {
        _voteEndDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final userId = context.read<MyAppAuthProvider.AuthProvider>().user?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in.')));
        return;
      }
      
      // Confirmation Dialog
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Submission'),
          content: const Text('Are you sure you want to submit this proposal? This will deduct 200 Loves from your balance.'),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop(false)),
            FilledButton(child: const Text('Confirm & Pay 200 Loves'), onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      );

      if (confirmed == true) {
        final proposalToSend = ProposalToSend(
          proposerUserId: userId,
          title: _titleController.text,
          description: _descriptionController.text,
          proposalType: _selectedProposalType!,
          voteEndTime: _voteEndDate!,
        );

        final result = await context.read<ProposalProvider>().createProposal(proposalToSend);
        
        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal submitted successfully!')));
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: ${result['error']}')));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Create a New Proposal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Proposal Title', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Please enter a title.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Full Description', border: OutlineInputBorder()),
              maxLines: 8,
              validator: (v) => v!.isEmpty ? 'Please enter a description.' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedProposalType,
              style: const TextStyle(color: Colors.white),
              dropdownColor: const Color(0xFF1e1e3f),
              decoration: const InputDecoration(labelText: 'Proposal Type', border: OutlineInputBorder()),
              items: _proposalTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (v) => setState(() => _selectedProposalType = v),
              validator: (v) => v == null ? 'Please select a type.' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: Colors.white54)),
              title: Text(_voteEndDate == null ? 'Select Voting End Date' : DateFormat.yMMMd().format(_voteEndDate!), style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.calendar_today, color: Colors.white70),
              onTap: () => _selectDate(context),
            ),
            // Custom validation message for the date picker
            if (_formKey.currentState?.validate() == false && _voteEndDate == null)
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 8),
                child: Text('Please select an end date.', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber),
              ),
              child: const Center(child: Text('Submission Fee: 200 Loves', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16))),
            ),
            const SizedBox(height: 16),
            Consumer<ProposalProvider>(
              builder: (context, provider, child) {
                return ElevatedButton(
                  onPressed: provider.isSubmittingProposal ? null : _submitForm,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: provider.isSubmittingProposal
                      ? const CircularProgressIndicator()
                      : const Text('Submit Proposal', style: TextStyle(fontSize: 18)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
