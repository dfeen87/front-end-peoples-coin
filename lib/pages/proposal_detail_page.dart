import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';

import '../models/proposal.dart';
import '../models/vote_to_send.dart';
import '../state/proposal_provider.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;
import '../widgets/voting_results_bar.dart';
import '../widgets/dynamic_nebula_background.dart';

class ProposalDetailPage extends StatefulWidget {
  final String proposalId;
  const ProposalDetailPage({super.key, required this.proposalId});

  @override
  State<ProposalDetailPage> createState() => _ProposalDetailPageState();
}

class _ProposalDetailPageState extends State<ProposalDetailPage> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProposalProvider>().fetchProposalDetails(widget.proposalId).then((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onVotePressed(String voteValue) {
    final proposal = context.read<ProposalProvider>().selectedProposal;
    final userId = context.read<MyAppAuthProvider.AuthProvider>().user?.uid;
    if (proposal == null || userId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.grey[900]?.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Your Vote'),
          content: const Text('This action costs 50 Loves and cannot be undone. Are you sure?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.amber[800]),
              child: const Text('Confirm & Vote', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final vote = VoteToSend(
                  proposalId: proposal.id,
                  voterUserId: userId,
                  voteValue: voteValue,
                );
                // --- FIX: Correctly check the Map result from the provider ---
                final result = await context.read<ProposalProvider>().submitVote(vote);
                if (result['success'] == true && mounted) {
                  _showVoteSuccessDialog();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVoteSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _VoteSuccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Consumer<ProposalProvider>(
            builder: (context, provider, child) {
              if (provider.isFetchingDetails || provider.selectedProposal == null) {
                return _buildLoadingShimmer();
              }
              if (provider.hasDetailsError) {
                return Center(child: Text(provider.detailsError!, style: const TextStyle(color: Colors.red)));
              }
              return _buildContent(provider.selectedProposal!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Proposal proposal) {
    // --- FIX: Vote counts are not on the Proposal model. ---
    // They should come from the provider. For now, we use mock data so the UI works.
    // In the future, you'll get these from your provider, e.g., `provider.forVotes`.
    const int forVotes = 620;
    const int againstVotes = 210;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Proposal Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildGlassCard(child: _buildStatusHeader(proposal)),
              const SizedBox(height: 16),
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proposal.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text(proposal.description, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Current Results', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _animationController,
                child: VotingResultsBar(forVotes: forVotes, againstVotes: againstVotes),
              ),
              const SizedBox(height: 32),
              if (proposal.status == ProposalStatus.active)
                _buildVotingSection()
              else
                Center(child: Text('Voting has ended for this proposal.', style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic))),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildVotingSection() {
    final provider = context.watch<ProposalProvider>();
    return ScaleTransition(
      scale: CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text('Cost to Vote: 50 Loves', style: TextStyle(color: Colors.amber, fontStyle: FontStyle.italic))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: provider.isSubmittingVote ? null : () => _onVotePressed('FOR'),
            icon: const Icon(Icons.thumb_up_alt_rounded),
            label: const Text('Vote FOR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: provider.isSubmittingVote ? null : () => _onVotePressed('AGAINST'),
            icon: const Icon(Icons.thumb_down_alt_rounded),
            label: const Text('Vote AGAINST'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.shade400, width: 2),
              foregroundColor: Colors.red.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Proposal proposal) {
    // --- FIX: Using the correct enum members from your proposal.dart model ---
    final Map<ProposalStatus, (IconData, Color, String)> statusInfo = {
      ProposalStatus.active: (Icons.hourglass_bottom_rounded, Colors.blueAccent, 'Active'),
      ProposalStatus.closed: (Icons.check_circle_rounded, Colors.green, 'Passed'), // Changed from 'passed'
      ProposalStatus.rejected: (Icons.cancel_rounded, Colors.redAccent, 'Failed'), // Changed from 'failed'
      ProposalStatus.draft: (Icons.edit_note_rounded, Colors.grey, 'Draft'),
      ProposalStatus.unknown: (Icons.question_mark_rounded, Colors.grey, 'Unknown'),
    };
    final info = statusInfo[proposal.status] ?? statusInfo[ProposalStatus.unknown]!;

    return Row(
      children: [
        Icon(info.$1, color: info.$2, size: 30),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${info.$3}', style: TextStyle(color: info.$2, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (proposal.voteEndTime != null)
              Text(
                'Voting ends: ${DateFormat.yMMMd().add_jm().format(proposal.voteEndTime!)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SizedBox(height: kToolbarHeight),
          Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Container(height: 30, width: 150, color: Colors.white),
          const SizedBox(height: 16),
          Container(height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
        ],
      ),
    );
  }
}

class _VoteSuccessDialog extends StatefulWidget {
  const _VoteSuccessDialog();

  @override
  State<_VoteSuccessDialog> createState() => _VoteSuccessDialogState();
}

class _VoteSuccessDialogState extends State<_VoteSuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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
            Icon(Icons.how_to_vote_rounded, color: Colors.greenAccent, size: 70),
            const SizedBox(height: 20),
            const Text(
              'Vote Cast!',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for participating in governance.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

