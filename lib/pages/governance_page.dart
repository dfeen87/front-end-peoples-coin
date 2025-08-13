// lib/pages/governance_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';

// Assume these models and widgets exist in your project
import '../models/proposal.dart';
import '../widgets/proposal_card.dart';
import 'create_proposal_page.dart';
import '../models/user.dart';

// --- RIVERPOD PROVIDERS ---

// A StateProvider to manage the selected filter status.
final selectedStatusProvider = StateProvider<String>((ref) => 'ACTIVE');

// This is a placeholder for your actual auth provider and user model.
final authUserProvider = Provider<User?>((ref) => User(uid: 'user123', email: 'user@example.com'));

// A StateNotifier for fetching and managing the list of proposals.
class ProposalsNotifier extends StateNotifier<AsyncValue<List<Proposal>>> {
  ProposalsNotifier() : super(const AsyncValue.loading());

  Future<void> fetchProposals({required String status, required String idToken}) async {
    // We only set to loading if there's no data yet, to avoid flashing on a refresh.
    if (state is! AsyncData) {
      state = const AsyncValue.loading();
    }
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // This is sample data. You would replace this with a real API call.
      final List<Proposal> fetchedProposals = [
        Proposal(
          id: '1',
          title: 'Community Garden Initiative',
          description: 'A proposal to establish a community garden in the central park.',
          proposerId: 'user123',
          status: 'ACTIVE',
          voteEndTime: DateTime.now().add(const Duration(days: 5)),
          votesFor: 120,
          votesAgainst: 30,
        ),
        Proposal(
          id: '2',
          title: 'Upgrade Public WiFi',
          description: 'Allocate funds to improve the public WiFi network in the city center.',
          proposerId: 'user456',
          status: 'ACTIVE',
          voteEndTime: DateTime.now().add(const Duration(days: 10)),
          votesFor: 85,
          votesAgainst: 15,
        ),
      ].where((p) => p.status == status).toList();

      state = AsyncValue.data(fetchedProposals);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// The provider to access the ProposalsNotifier state.
final proposalsProvider = StateNotifierProvider<ProposalsNotifier, AsyncValue<List<Proposal>>>((ref) {
  final status = ref.watch(selectedStatusProvider);
  final notifier = ProposalsNotifier();
  
  // Asynchronously fetch proposals when the provider is first created or the status changes.
  final user = ref.watch(authUserProvider);
  const idToken = 'dummy_id_token'; // Replace with a call to get the real token
  if (user != null) {
     notifier.fetchProposals(status: status, idToken: idToken);
  }
  
  return notifier;
});

// --- GOVERNANCE PAGE WIDGET ---

class GovernancePage extends ConsumerStatefulWidget {
  const GovernancePage({super.key});

  @override
  ConsumerState<GovernancePage> createState() => _GovernancePageState();
}

class _GovernancePageState extends ConsumerState<GovernancePage> with TickerProviderStateMixin {
  late final AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }
  
  // This method is now much simpler, as Riverpod handles the state and fetching.
  Future<void> _onRefresh() async {
    final status = ref.read(selectedStatusProvider);
    final user = ref.read(authUserProvider);
    const idToken = 'dummy_id_token'; 
    if (user != null) {
      // Trigger a re-fetch by calling the notifier directly.
      await ref.read(proposalsProvider.notifier).fetchProposals(status: status, idToken: idToken);
      _listAnimationController.forward();
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
            _onRefresh(); // Refresh the list when the form is submitted.
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
    final theme = Theme.of(context);
    final proposalsAsync = ref.watch(proposalsProvider);
    final selectedStatus = ref.watch(selectedStatusProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProposalForm,
        icon: const Icon(Icons.add),
        label: const Text('Create Proposal'),
        backgroundColor: theme.colorScheme.tertiary,
        foregroundColor: theme.colorScheme.onTertiary,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: theme.colorScheme.tertiary,
        backgroundColor: theme.colorScheme.background,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(theme),
            _buildHeader(theme),
            _buildFilterBar(theme, selectedStatus),
            _buildProposalList(theme, proposalsAsync),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      title: Text('Governance', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onBackground)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: theme.colorScheme.background.withOpacity(0.2)),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(ThemeData theme) {
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
                color: theme.colorScheme.surface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel_rounded, color: theme.colorScheme.tertiary, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Empower the community. Propose new ideas and vote to shape our future.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.5,
                      ),
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

  SliverToBoxAdapter _buildFilterBar(ThemeData theme, String selectedStatus) {
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
          selected: {selectedStatus},
          onSelectionChanged: (newSelection) {
            ref.read(selectedStatusProvider.notifier).state = newSelection.first;
            _onRefresh();
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.1),
            foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
            selectedBackgroundColor: theme.colorScheme.tertiary,
            selectedForegroundColor: theme.colorScheme.onTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildProposalList(ThemeData theme, AsyncValue<List<Proposal>> proposalsAsync) {
    return proposalsAsync.when(
      loading: () => _buildLoadingShimmer(),
      error: (err, stack) => SliverFillRemaining(
        child: Center(
          child: Text('Error: $err', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
        ),
      ),
      data: (proposals) {
        if (proposals.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text("No proposals found in this category. Be the first to create one!"),
            ),
          );
        }
        _listAnimationController.forward();
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final proposal = proposals[index];
                final animation = Tween(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      (1 / proposals.length) * index,
                      1.0,
                      curve: Curves.easeOut,
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
              childCount: proposals.length,
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
            baseColor: Theme.of(context).colorScheme.surface.withOpacity(0.2),
            highlightColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
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

// Placeholder for your models for the code to be runnable
class Proposal {
  final String id;
  final String title;
  final String description;
  final String proposerId;
  final String status;
  final DateTime voteEndTime;
  final int votesFor;
  final int votesAgainst;

  Proposal({
    required this.id,
    required this.title,
    required this.description,
    required this.proposerId,
    required this.status,
    required this.voteEndTime,
    required this.votesFor,
    required this.votesAgainst,
  });
}

