// lib/pages/proposal_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'dart:ui';
import 'dart:async';

// Import the actual service and model files
import '../service/proposal_service.dart';
import '../models/proposal.dart';
import '../models/vote.dart';

// --- DATA MODELS AND PROVIDERS ---

class VoteToSend {
  final String proposalId;
  final String voterUserId;
  final String voteValue;
  VoteToSend({required this.proposalId, required this.voterUserId, required this.voteValue});
}

// A state class to represent the different states of the proposal detail page.
class ProposalDetailState {
  final Proposal? proposal;
  final bool isSubmittingVote;
  final bool isLoading;
  final String? error;

  ProposalDetailState({
    this.proposal,
    this.isSubmittingVote = false,
    this.isLoading = false,
    this.error,
  });
}

// StateNotifier for proposal-related business logic.
class ProposalNotifier extends StateNotifier<ProposalDetailState> {
  final ProposalService _service;
  ProposalNotifier(this._service) : super(ProposalDetailState());

  Future<void> fetchProposalDetails(String proposalId, {required String idToken}) async {
    state = ProposalDetailState(isLoading: true);
    try {
      final fetchedProposal = await _service.fetchProposalDetails(proposalId, idToken: idToken);
      state = ProposalDetailState(proposal: fetchedProposal);
    } catch (e) {
      state = ProposalDetailState(error: 'Failed to fetch proposal details.');
    }
  }

  Future<bool> submitVote({required VoteToSend vote, required String idToken}) async {
    if (state.proposal == null) return false;

    state = ProposalDetailState(proposal: state.proposal, isSubmittingVote: true);
    
    try {
      final success = await _service.submitVote(vote: vote, idToken: idToken);
      if (success) {
        // If the vote was successful, update the local state to reflect the change
        // This is a simple optimistic update. A more robust solution might refetch the data.
        final newForVotes = vote.voteValue == 'FOR' ? state.proposal!.forVotes + 1 : state.proposal!.forVotes;
        final newAgainstVotes = vote.voteValue == 'AGAINST' ? state.proposal!.againstVotes + 1 : state.proposal!.againstVotes;

        state = ProposalDetailState(
          proposal: state.proposal!.copyWith(
            forVotes: newForVotes,
            againstVotes: newAgainstVotes,
            userHasVoted: true,
          ),
        );
      } else {
        state = ProposalDetailState(proposal: state.proposal, error: 'Failed to submit vote.');
      }
      return success;
    } catch (e) {
      state = ProposalDetailState(proposal: state.proposal, error: 'Failed to submit vote.');
      return false;
    }
  }
}

// Use a family provider to manage a separate state for each proposal page.
final proposalDetailProvider = StateNotifierProvider.family<ProposalNotifier, ProposalDetailState, String>((ref, proposalId) {
  final service = ref.watch(proposalServiceProvider);
  return ProposalNotifier(service);
});

final proposalServiceProvider = Provider<ProposalService>((ref) {
  return ProposalService();
});

final authProvider = StreamProvider<auth.User?>((ref) {
  return auth.FirebaseAuth.instance.authStateChanges();
});

// --- APP-WIDE WIDGETS ---

class ProposalDetailPage extends ConsumerStatefulWidget {
  final String proposalId;
  const ProposalDetailPage({super.key, required this.proposalId});

  @override
  ConsumerState<ProposalDetailPage> createState() => _ProposalDetailPageState();
}

class _ProposalDetailPageState extends ConsumerState<ProposalDetailPage> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchProposalData();
  }

  Future<void> _fetchProposalData() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view proposal details.')),
        );
      }
      return;
    }

    try {
      final idToken = await user.getIdToken();
      await ref.read(proposalDetailProvider(widget.proposalId).notifier).fetchProposalDetails(
        widget.proposalId,
        idToken: idToken,
      );
      if (mounted) {
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error. Please sign in again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onVotePressed(String voteValue) async {
    final state = ref.read(proposalDetailProvider(widget.proposalId));
    final user = auth.FirebaseAuth.instance.currentUser;

    if (state.proposal == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated or proposal not loaded.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    try {
      final idToken = await user.getIdToken();

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
                    proposalId: state.proposal!.id,
                    voterUserId: user.uid,
                    voteValue: voteValue,
                  );
                  final success = await ref.read(proposalDetailProvider(widget.proposalId).notifier).submitVote(vote: vote, idToken: idToken);
                  if (success && mounted) {
                    _showVoteSuccessDialog();
                  } else if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to cast vote.'), backgroundColor: Colors.redAccent),
                     );
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please try again.'), backgroundColor: Colors.redAccent),
      );
    }
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
    final proposalState = ref.watch(proposalDetailProvider(widget.proposalId));
    final authState = ref.watch(authProvider);

    // Show authentication prompt if user is not signed in
    if (authState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState.hasError || authState.value == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Proposal Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                'Sign in required',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please sign in to view proposal details.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          proposalState.isLoading
              ? _buildLoadingShimmer()
              : proposalState.error != null
                  ? Center(child: Text(proposalState.error!, style: const TextStyle(color: Colors.red)))
                  : proposalState.proposal != null
                      ? _buildContent(proposalState.proposal!)
                      : const Center(child: Text('No proposal found.', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildContent(Proposal proposal) {
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
                child: VotingResultsBar(forVotes: proposal.forVotes, againstVotes: proposal.againstVotes),
              ),
              const SizedBox(height: 32),
              if (proposal.status == ProposalStatus.active)
                _buildVotingSection(proposal)
              else
                const Center(child: Text('Voting has ended for this proposal.', style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic))),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildVotingSection(Proposal proposal) {
    final state = ref.watch(proposalDetailProvider(widget.proposalId));
    final bool canVote = !state.isSubmittingVote && !proposal.userHasVoted;

    return ScaleTransition(
      scale: CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (proposal.userHasVoted)
            const Center(child: Text('You have already voted on this proposal.', style: TextStyle(color: Colors.amber, fontStyle: FontStyle.italic)))
          else
            const Center(child: Text('Cost to Vote: 50 Loves', style: TextStyle(color: Colors.amber, fontStyle: FontStyle.italic))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: canVote ? () => _onVotePressed('FOR') : null,
            icon: state.isSubmittingVote ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.thumb_up_alt_rounded),
            label: Text(state.isSubmittingVote ? 'Submitting...' : 'Vote FOR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: canVote ? () => _onVotePressed('AGAINST') : null,
            icon: state.isSubmittingVote ? const SizedBox(height: 20, width: 20) : const Icon(Icons.thumb_down_alt_rounded),
            label: Text(state.isSubmittingVote ? 'Submitting...' : 'Vote AGAINST'),
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
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
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
    final Map<ProposalStatus, (IconData, Color, String)> statusInfo = {
      ProposalStatus.active: (Icons.hourglass_bottom_rounded, Colors.blueAccent, 'Active'),
      ProposalStatus.closed: (Icons.check_circle_rounded, Colors.green, 'Passed'),
      ProposalStatus.rejected: (Icons.cancel_rounded, Colors.redAccent, 'Failed'),
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
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: kToolbarHeight),
          Container(height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Container(height: 200, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Container(height: 30, width: 150, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          Container(height: 50, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8))),
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
            const Icon(Icons.how_to_vote_rounded, color: Colors.greenAccent, size: 70),
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

class VotingResultsBar extends StatelessWidget {
  final int forVotes;
  final int againstVotes;

  const VotingResultsBar({super.key, required this.forVotes, required this.againstVotes});

  @override
  Widget build(BuildContext context) {
    final totalVotes = forVotes + againstVotes;
    final forPercentage = totalVotes > 0 ? forVotes / totalVotes : 0.0;
    final againstPercentage = totalVotes > 0 ? againstVotes / totalVotes : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('For: $forVotes', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            Text('Against: $againstVotes', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: forPercentage,
            backgroundColor: Colors.red.shade400,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(forPercentage * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white70)),
            Text('${(againstPercentage * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }
}
