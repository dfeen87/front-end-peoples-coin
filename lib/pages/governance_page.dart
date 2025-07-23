// lib/pages/governance_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../state/proposal_provider.dart';
import '../widgets/proposal_card.dart';
import 'create_proposal_page.dart'; // Import for the new page

class GovernancePage extends StatefulWidget {
  const GovernancePage({super.key});

  @override
  State<GovernancePage> createState() => _GovernancePageState();
}

class _GovernancePageState extends State<GovernancePage> {
  @override
  void initState() {
    super.initState();
    // Fetch active proposals when the page is first loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Using listen: false in initState is good practice.
      Provider.of<ProposalProvider>(context, listen: false)
          .fetchProposals(status: 'ACTIVE');
    });
  }

  // Helper method for the loading UI
  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: ListView.builder(
        itemCount: 3,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          color: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: const SizedBox(height: 140.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Governance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Proposal',
            onPressed: () {
              // This now navigates to the new form page.
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const CreateProposalPage()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProposalProvider>(
        builder: (context, proposalProvider, child) {
          if (proposalProvider.isFetchingProposals) {
            return _buildLoadingSkeleton();
          }

          if (proposalProvider.hasListError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  proposalProvider.listError ?? 'An unknown error occurred.',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (proposalProvider.proposals.isEmpty) {
            return const Center(
              child: Text(
                "There are no active proposals at the moment.",
                style: TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                Provider.of<ProposalProvider>(context, listen: false)
                    .fetchProposals(status: 'ACTIVE'),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: proposalProvider.proposals.length,
              itemBuilder: (context, index) {
                final proposal = proposalProvider.proposals[index];
                return ProposalCard(proposal: proposal);
              },
            ),
          );
        },
      ),
    );
  }
}
