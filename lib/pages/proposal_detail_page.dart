// lib/pages/proposal_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/proposal.dart';
import '../models/vote_to_send.dart';
import '../state/proposal_provider.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;
import '../widgets/voting_results_bar.dart';

class ProposalDetailPage extends StatefulWidget {
  final String proposalId;
  const ProposalDetailPage({super.key, required this.proposalId});

  @override
  State<ProposalDetailPage> createState() => _ProposalDetailPageState();
}

class _ProposalDetailPageState extends State<ProposalDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProposalProvider>().fetchProposalDetails(widget.proposalId);
    });
  }
  
  void _onVotePressed(String voteValue) {
    final proposal = context.read<ProposalProvider>().selectedProposal;
    final userId = context.read<MyAppAuthProvider.AuthProvider>().user?.uid;
    if (proposal == null || userId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Your Vote'),
        content: const Text('Are you sure you want to cast this vote? This action costs 50 Loves and cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            child: const Text('Confirm & Vote'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final vote = VoteToSend(
                proposalId: proposal.id, 
                voterUserId: userId, 
                voteValue: voteValue
              );
              await context.read<ProposalProvider>().submitVote(vote);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Proposal Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ProposalProvider>(
        builder: (context, provider, child) {
          if (provider.isFetchingDetails || provider.selectedProposal == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.hasDetailsError) {
            return Center(child: Text(provider.detailsError!, style: const TextStyle(color: Colors.red)));
          }

          final proposal = provider.selectedProposal!;
          // Mock vote counts for now - this would come from your API
          const int forVotes = 620;
          const int againstVotes = 210;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(proposal.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(proposal.description, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 24),
                const Text('Current Results', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                VotingResultsBar(forVotes: forVotes, againstVotes: againstVotes),
                const SizedBox(height: 32),
                
                // --- Voting Section ---
                if (proposal.status == ProposalStatus.active)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: Text('Cost to Vote: 50 Loves', style: TextStyle(color: Colors.amber, fontStyle: FontStyle.italic))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: provider.isSubmittingVote ? null : () => _onVotePressed('FOR'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: provider.isSubmittingVote ? const CircularProgressIndicator() : const Text('Vote FOR', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: provider.isSubmittingVote ? null : () => _onVotePressed('AGAINST'),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade400), padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: Text('Vote AGAINST', style: TextStyle(fontSize: 18, color: Colors.red.shade400)),
                      ),
                    ],
                  ),
                if (proposal.status != ProposalStatus.active)
                  Center(child: Text('Voting is currently ${proposal.status.name}.', style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic))),
              ],
            ),
          );
        },
      ),
    );
  }
}
