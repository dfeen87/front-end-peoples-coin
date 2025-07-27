// lib/pages/create_proposal_page.dart
// This file now defines the embedded content for the proposal creation form.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/proposal_provider.dart';
import '../models/proposal_to_send.dart';
import '../state/user_provider.dart'; // REQUIRED: To get current user ID

// Use a typedef for the callback (Good practice for clarity)
typedef ProposalFormCompletedCallback = void Function();

// Class name changed to reflect its new role as embedded content
class CreateProposalPageContent extends StatefulWidget {
  // Add a callback property so the form can notify its parent (GovernancePage)
  // when it's done (submitted or cancelled).
  final ProposalFormCompletedCallback onFormCompleted;

  const CreateProposalPageContent({super.key, required this.onFormCompleted});

  @override
  State<CreateProposalPageContent> createState() => _CreateProposalPageContentState();
}

class _CreateProposalPageContentState extends State<CreateProposalPageContent> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _proposalType = 'General'; // Default type
  DateTime? _voteEndDate;

  // Form field controllers for optional values
  final TextEditingController _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.amber[600]!, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.white, // Calendar text color
              surface: Colors.black54, // Dialog background color
            ),
            dialogBackgroundColor: Colors.black.withOpacity(0.8),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _voteEndDate) {
      setState(() {
        _voteEndDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final currentUser = context.read<UserProvider>().currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.')),
        );
        return;
      }

      final proposalToSend = ProposalToSend(
        proposerUserId: currentUser.id,
        title: _title,
        description: _description,
        proposalType: _proposalType,
        details: _detailsController.text.isNotEmpty
            ? {'custom_details': _detailsController.text}
            : null,
        voteEndTime: _voteEndDate, // Pass voteEndTime
      );

      final result = await context.read<ProposalProvider>().createProposal(proposalToSend);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proposal created successfully!')),
          );
          widget.onFormCompleted(); // Call the callback on success to close the form
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission failed: ${result['error']}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProposalProvider>(
      builder: (context, provider, child) {
        // --- START SizedBox block (Line 115 approx) ---
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7, // Adjust this multiplier as needed to fit your form
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const NeverScrollableScrollPhysics(), // Keep this
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Proposal Title',
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
                        return 'Please enter a title.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _title = value!;
                    },
                  ),
                  const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _description = value!;
                  },
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Proposal Type',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  dropdownColor: Colors.black.withOpacity(0.7),
                  style: const TextStyle(color: Colors.white),
                  value: _proposalType,
                  items: <String>['General', 'Funding', 'Policy'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _proposalType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Details (Optional)',
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
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  title: Text(
                      _voteEndDate == null
                          ? 'Select Vote End Date (Optional)'
                          : 'Vote Ends: ${_voteEndDate!.toLocal().toIso8601String().split('T')[0]}',
                      style: const TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 32.0),
                Center(
                  child: ElevatedButton(
                    onPressed: provider.isSubmittingProposal ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: provider.isSubmittingProposal
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Proposal'),
                  ),
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: TextButton(
                    onPressed: provider.isSubmittingProposal ? null : widget.onFormCompleted,
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ); // END of SizedBox widget (Line 249 approx)
      }, // END of builder callback
    ); // END of Consumer widget
  }
}
