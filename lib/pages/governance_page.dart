// lib/pages/governance_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/proposal_provider.dart';
import '../widgets/proposal_card.dart'; // Assuming you have a ProposalCard widget
// Import the new content class for creating proposals
import 'create_proposal_page.dart'; // This will be the file containing CreateProposalPageContent

class GovernancePage extends StatefulWidget {
  const GovernancePage({super.key});

  @override
  State<GovernancePage> createState() => _GovernancePageState();
}

class _GovernancePageState extends State<GovernancePage> {
  // State to toggle between list and form view
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    // Fetch proposals only when the list view is first active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProposalsIfListActive();
    });
  }

  void _fetchProposalsIfListActive() {
    if (!_showCreateForm) {
      // Assuming 'ACTIVE' is the desired initial status to fetch for the list
      context.read<ProposalProvider>().fetchProposals(status: 'ACTIVE');
    }
  }

  // Callback to hide the form and refresh the list
  void _onProposalFormCompleted() {
    setState(() {
      _showCreateForm = false; // Switch back to list view
    });
    // Refresh proposals after form submission/cancellation
    _fetchProposalsIfListActive();
  }

  // Builds the list view of proposals
  Widget _buildProposalList() {
    return Consumer<ProposalProvider>(
      builder: (context, proposalProvider, child) {
        if (proposalProvider.isFetchingProposals) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (proposalProvider.hasListError) {
          return Center(
            child: Text(
              proposalProvider.listError ?? 'Failed to load proposals.',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (proposalProvider.proposals.isEmpty) {
          return const Center(
            child: Text(
              "No active proposals found.",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: proposalProvider.proposals.length,
          itemBuilder: (context, index) {
            final proposal = proposalProvider.proposals[index];
            // Assuming ProposalCard takes a Proposal object and handles its own UI
            return ProposalCard(proposal: proposal);
          },
        );
      },
    );
  }

  // Builds the create proposal form view (content from CreateProposalPage)
  Widget _buildCreateProposalForm() {
    // Note: The CreateProposalPage itself was modified to NOT have a Scaffold/AppBar
    return CreateProposalPageContent( // Ensure this class name matches your create_proposal_page.dart
      onFormCompleted: _onProposalFormCompleted, // Pass the callback
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Ensure page background is transparent
      appBar: AppBar(
        title: Text(_showCreateForm ? 'Create New Proposal' : 'Governance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Show different actions based on view
          _showCreateForm // If currently showing the form
              ? IconButton(
                  icon: const Icon(Icons.close), // Close button for the form
                  onPressed: () {
                    setState(() {
                      _showCreateForm = false; // Switch back to list view
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.add), // Add button for the list
                  onPressed: () {
                    setState(() {
                      _showCreateForm = true; // Switch to form view
                    });
                  },
                ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500), // Fade duration
        transitionBuilder: (Widget child, Animation<double> animation) {
          // FadeTransition for the requested fade effect
          return FadeTransition(opacity: animation, child: child);
        },
        // Use a KeyedSubtree to ensure AnimatedSwitcher sees a different widget and animates
        child: _showCreateForm
            ? KeyedSubtree(key: const ValueKey('createForm'), child: _buildCreateProposalForm())
            : KeyedSubtree(key: const ValueKey('proposalList'), child: _buildProposalList()),
      ),
      // If you want a FAB, you can still add it here
      // floatingActionButton: _showCreateForm ? null : FloatingActionButton(
      //   onPressed: () {
      //     setState(() {
      //       _showCreateForm = true;
      //     });
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
