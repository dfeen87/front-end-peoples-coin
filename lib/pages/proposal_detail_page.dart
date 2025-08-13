// lib/pages/proposal_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import 'dart:async';

// --- MOCK DATA MODELS AND PROVIDERS (Refactored to use Riverpod) ---

enum ProposalStatus { active, closed, rejected, draft, unknown }

class Proposal {
  final String id;
  final String title;
  final String description;
  final ProposalStatus status;
  final DateTime? voteEndTime;
  final int forVotes;
  final int againstVotes;
  final bool userHasVoted;

  Proposal({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.voteEndTime,
    this.forVotes = 0,
    this.againstVotes = 0,
    this.userHasVoted = false,
  });

  Proposal copyWith({
    String? id,
    String? title,
    String? description,
    ProposalStatus? status,
    DateTime? voteEndTime,
    int? forVotes,
    int? againstVotes,
    bool? userHasVoted,
  }) {
    return Proposal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      voteEndTime: voteEndTime ?? this.voteEndTime,
      forVotes: forVotes ?? this.forVotes,
      againstVotes: againstVotes ?? this.againstVotes,
      userHasVoted: userHasVoted ?? this.userHasVoted,
    );
  }
}

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
  ProposalNotifier() : super(ProposalDetailState());

  Future<void> fetchProposalDetails(String proposalId, {required String idToken}) async {
    state = ProposalDetailState(isLoading: true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    try {
      final mockProposal = Proposal(
        id: proposalId,
        title: 'Launch a community recycling program.',
        description: 'This proposal aims to allocate community funds to a new recycling initiative. It will cover the cost of bins, collection services, and public education. The goal is to reduce waste by 20% over the next year.',
        status: ProposalStatus.active,
        voteEndTime: DateTime.now().add(const Duration(days: 7)),
        forVotes: 620,
        againstVotes: 210,
        userHasVoted: false, // Initial state, assumes user hasn't voted
      );
      state = ProposalDetailState(proposal: mockProposal);
    } catch (e) {
      state = ProposalDetailState(error: 'Failed to fetch proposal details.');
    }
  }

  Future<bool> submitVote({required VoteToSend vote, required String idToken}) async {
    if (state.proposal == null) return false;

    state = ProposalDetailState(proposal: state.proposal, isSubmittingVote: true);

    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    try {
      // Simulate successful vote
      final newForVotes = vote.voteValue == 'FOR' ? state.proposal!.forVotes + 1 : state.proposal!.forVotes;
      final newAgainstVotes = vote.voteValue == 'AGAINST' ? state.proposal!.againstVotes + 1 : state.proposal!.againstVotes;

      state = ProposalDetailState(
        proposal: state.proposal!.copyWith(
          forVotes: newForVotes,
          againstVotes: newAgainstVotes,
          userHasVoted: true,
        ),
      );
      return true;
    } catch (e) {
      state = ProposalDetailState(proposal: state.proposal, error: 'Failed to submit vote.');
      return false;
    }
  }
}

// Use a family provider to manage a separate state for each proposal page.
final proposalDetailProvider = StateNotifierProvider.family<ProposalNotifier, ProposalDetailState, String>((ref, proposalId) {
  return ProposalNotifier();
});

// MOCK AUTH PROVIDER (to simulate user and idToken)
class MockUser {
  final String uid = 'user123';
  Future<String> getIdToken() async => 'mock-id-token';
}

final authProvider = Provider<MockUser?>((ref) => MockUser());

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
    final user = ref.read(authProvider);
    if (user != null) {
      final idToken = await user.getIdToken();
      await ref.read(proposalDetailProvider(widget.proposalId).notifier).fetchProposalDetails(
        widget.proposalId,
        idToken: idToken,
      );
      if (mounted) {
        _animationController.forward();
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
    final user = ref.read(authProvider);
    final idToken = await user?.getIdToken();

    if (state.proposal == null || user?.uid == null || idToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated or proposal not loaded.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

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
                  voterUserId: user!.uid,
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
    // Watch the provider to get the current state
    final proposalState = ref.watch(proposalDetailProvider(widget.proposalId));

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
                Center(child: Text('Voting has ended for this proposal.', style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic))),
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
            icon: state.isSubmittingVote ? const SizedBox(height: 20, width: 20) : const Icon(Icons.thumb_down_alt_rounded), // Use a placeholder to keep alignment
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
          SizedBox(height: kToolbarHeight),
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

// --- MOCK WIDGETS FROM ORIGINAL CODE ---

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
            Text('For: ${forVotes}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            Text('Against: ${againstVotes}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

// --- MAIN APP ENTRY POINT ---

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Proposal App',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          accentColor: Colors.amber,
          backgroundColor: Colors.deepPurple.shade900,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: Colors.amber.shade400,
        ),
        scaffoldBackgroundColor: Colors.deepPurple.shade900,
      ),
      home: const ProposalDetailPage(proposalId: 'prop_123'),
    );
  }
}

