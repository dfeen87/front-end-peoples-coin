import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';

import '../state/proposal_provider.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;
import '../widgets/proposal_card.dart';
import 'create_proposal_page.dart';
import '../widgets/dynamic_nebula_background.dart';

// --- GovernancePage ---
class GovernancePage extends StatefulWidget {
  const GovernancePage({super.key});

  @override
  State<GovernancePage> createState() => _GovernancePageState();
}

class _GovernancePageState extends State<GovernancePage> with TickerProviderStateMixin {
  String _selectedStatus = 'ACTIVE';
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchProposals();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchProposals() async {
    _listAnimationController.reset();
    // Use `mounted` check for safety in async operations
    if (mounted) {
      // Get the ID token from the AuthProvider
      final authProvider = context.read<MyAppAuthProvider.AuthProvider>();
      final idToken = await authProvider.user?.getIdToken();

      if (idToken != null) {
        await context.read<ProposalProvider>().fetchProposals(status: _selectedStatus, idToken: idToken);
        if (mounted) {
          _listAnimationController.forward();
        }
      }
    }
  }

  void _showCreateProposalForm() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return CreateProposalPageContent(
          onFormCompleted: () {
            Navigator.of(context).pop();
            _fetchProposals();
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeInOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProposalForm,
        icon: const Icon(Icons.add, color: Colors.black),
        // FIX: Made the button translucent
        label: const Text('New Proposal', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.amber[700]!.withOpacity(0.8),
      ),
      body: Stack(
        children: [
          // FIX: The background widget is now a child of AppShell, so we remove it here.
          // This is what prevents it from resetting and makes it continuous.
          // const DynamicNebulaBackground(),
          RefreshIndicator(
            onRefresh: _fetchProposals,
            color: Colors.amber,
            backgroundColor: Colors.grey[850],
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                _buildHeader(),
                _buildFilterBar(),
                _buildProposalList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return const SliverAppBar(
      title: Text('Governance'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
    );
  }

  SliverToBoxAdapter _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ClipRRect(
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
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.white70, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Shape the future of the community by creating and voting on proposals.',
                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildFilterBar() {
    final statuses = ['ACTIVE', 'PASSED', 'FAILED'];
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: SegmentedButton<String>(
          segments: statuses.map((status) {
            return ButtonSegment<String>(
              value: status,
              label: Text(status.toUpperCase()),
            );
          }).toList(),
          selected: {_selectedStatus},
          onSelectionChanged: (newSelection) {
            setState(() {
              _selectedStatus = newSelection.first;
              _fetchProposals();
            });
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white70,
            selectedBackgroundColor: Colors.amber[800]!,
            selectedForegroundColor: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildProposalList() {
    return Consumer<ProposalProvider>(
      builder: (context, proposalProvider, child) {
        // Show a loading shimmer ONLY if the list is empty and we are fetching.
        // This prevents the screen from flashing when refreshing the list.
        if (proposalProvider.isFetchingProposals && proposalProvider.proposals.isEmpty) {
          return _buildLoadingShimmer();
        }

        // Use the CORRECT getter 'hasProposalsError'
        if (proposalProvider.hasProposalsError) {
          return SliverFillRemaining(
            child: Center(
              child: Text(proposalProvider.proposalsError ?? 'Failed to load proposals.'),
            ),
          );
        }

        // Handle the case where there are no proposals after loading.
        if (proposalProvider.proposals.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text("No proposals found for this status."),
            ),
          );
        }

        // If we have proposals, display them in a list.
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final proposal = proposalProvider.proposals[index];
                final animation = Tween(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      (1 / proposalProvider.proposals.length) * index,
                      1.0,
                      curve: Curves.easeOut
                    ),
                  ),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
                    child: ProposalCard(proposal: proposal),
                  ),
                );
              },
              childCount: proposalProvider.proposals.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[850]!.withOpacity(0.3), // FIX: Made the shimmer colors translucent
            highlightColor: Colors.grey[800]!.withOpacity(0.3), // FIX: Made the shimmer colors translucent
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              color: Colors.white.withOpacity(0.05), // FIX: Made the shimmer card transparent
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: const SizedBox(height: 150),
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }
}

