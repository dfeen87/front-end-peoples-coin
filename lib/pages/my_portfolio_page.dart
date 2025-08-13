// lib/pages/my_portfolio_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // for HapticFeedback
import 'dart:ui';

// --- RIVERPOD PROVIDERS ---

// Placeholder for your user model and authentication logic
// In a real app, this would be your authentication state.
class User {
  final String id;
  final String username;
  User({required this.id, this.username = 'User'});
}
final authUserProvider = Provider<User?>((ref) => User(id: 'user123', username: 'Crypto Dev'));

// A mock data source for GoodwillActions
class GoodwillAction {
  final String id;
  final String title;
  final String description;
  final int score;
  final DateTime createdAt;
  final GoodwillStatus status;
  GoodwillAction({
    required this.id,
    required this.title,
    required this.description,
    required this.score,
    required this.createdAt,
    this.status = GoodwillStatus.verified,
  });
}

enum GoodwillStatus { verified, pendingVerification, rejected }

// A StateNotifier to manage the state of user actions.
class UserActionsNotifier extends StateNotifier<AsyncValue<List<GoodwillAction>>> {
  UserActionsNotifier() : super(const AsyncValue.loading());

  Future<void> fetchUserActions({required String idToken}) async {
    // Only show the loading state if we don't have any data yet.
    if (state is! AsyncData) {
      state = const AsyncValue.loading();
    }
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // This is sample data. You would replace this with a real API call.
      final List<GoodwillAction> fetchedActions = [
        GoodwillAction(
          id: 'act1',
          title: 'Mentorship',
          description: 'Provided mentorship to a junior developer for a month.',
          score: 150,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          status: GoodwillStatus.verified,
        ),
        GoodwillAction(
          id: 'act2',
          title: 'Volunteering',
          description: 'Spent a weekend volunteering at the local animal shelter.',
          score: 80,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          status: GoodwillStatus.verified,
        ),
        GoodwillAction(
          id: 'act3',
          title: 'Donation',
          description: 'Donated to the community fund for new park benches.',
          score: 50,
          createdAt: DateTime.now().subtract(const Duration(days: 35)),
          status: GoodwillStatus.pendingVerification,
        ),
        GoodwillAction(
          id: 'act4',
          title: 'Code Contribution',
          description: 'Contributed to an open-source project by fixing a critical bug.',
          score: 100,
          createdAt: DateTime.now().subtract(const Duration(days: 50)),
          status: GoodwillStatus.verified,
        ),
      ];

      state = AsyncValue.data(fetchedActions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// The provider to access the UserActionsNotifier state.
final userActionsProvider = StateNotifierProvider<UserActionsNotifier, AsyncValue<List<GoodwillAction>>>((ref) {
  final notifier = UserActionsNotifier();
  
  // Fetch user actions when the provider is first created.
  final user = ref.watch(authUserProvider);
  const idToken = 'dummy_id_token'; // Replace with a call to get the real token
  if (user != null) {
     notifier.fetchUserActions(idToken: idToken);
  }

  return notifier;
});

// --- MY PORTFOLIO PAGE WIDGET ---

class MyPortfolioPage extends ConsumerStatefulWidget {
  const MyPortfolioPage({super.key});

  @override
  ConsumerState<MyPortfolioPage> createState() => _MyPortfolioPageState();
}

class _MyPortfolioPageState extends ConsumerState<MyPortfolioPage> with TickerProviderStateMixin {
  late final AnimationController _listAnimationController;
  late final TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _mainTabController.dispose();
    super.dispose();
  }

  // A method to trigger a data refresh and restart the animations.
  Future<void> _refreshData() async {
    final user = ref.read(authUserProvider);
    const idToken = 'dummy_id_token';
    if (user != null) {
      await ref.read(userActionsProvider.notifier).fetchUserActions(idToken: idToken);
      _listAnimationController.reset();
      _listAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Portfolio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: theme.colorScheme.background.withOpacity(0.2)),
          ),
        ),
        bottom: TabBar(
          controller: _mainTabController,
          tabs: const [
            Tab(text: 'Summary', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Status', icon: Icon(Icons.info_outline)),
          ],
          indicatorColor: theme.colorScheme.tertiary,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildSummaryTab(theme, user),
          _buildStatusTab(theme),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(ThemeData theme, User? user) {
    // Watch the provider for the list of actions.
    final userActionsAsync = ref.watch(userActionsProvider);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.colorScheme.tertiary,
      backgroundColor: theme.colorScheme.background,
      child: userActionsAsync.when(
        loading: () => _buildLoadingSkeleton(theme),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
        ),
        data: (userActions) {
          if (userActions.isEmpty) {
            return const _EmptyPortfolioState();
          }

          final totalLoves = userActions.fold<int>(0, (sum, item) => sum + item.score);
          final totalActs = userActions.length;

          // When data is available, start the animation.
          _listAnimationController.forward();

          return CustomScrollView(
            slivers: [
              _buildHeader(theme, user, totalActs, totalLoves),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final action = userActions[index];
                      final animation = Tween(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _listAnimationController,
                          curve: Interval(
                            (1 / userActions.length) * index,
                            1.0,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(animation),
                          child: GoodwillTimelineCard(
                            action: action,
                            isFirst: index == 0,
                            isLast: index == userActions.length - 1,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Tapped on "${action.title}"')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    childCount: userActions.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusTab(ThemeData theme) {
    // Watch the provider for the list of actions.
    final userActionsAsync = ref.watch(userActionsProvider);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.colorScheme.tertiary,
      backgroundColor: theme.colorScheme.background,
      child: userActionsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.tertiary)),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load goodwill acts.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
        ),
        data: (userActions) {
          if (userActions.isEmpty) {
            return const Center(
              child: Text(
                'No Goodwill Actions found.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: userActions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final action = userActions[index];
              return _StatusListTile(
                action: action,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tapped on "${action.title}"')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surface.withOpacity(0.05),
      highlightColor: theme.colorScheme.surface.withOpacity(0.1),
      child: ListView(
        padding: const EdgeInsets.all(16).copyWith(top: kToolbarHeight * 2),
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 24),
          Container(
            height: 100,
            decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(ThemeData theme, User? user, int totalActs, int totalLoves) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 220.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black.withOpacity(0.5)),
            _PortfolioHeaderContent(username: user?.username ?? 'User', totalActs: totalActs, totalLoves: totalLoves),
          ],
        ),
        title: Text('My Portfolio', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground)),
        centerTitle: true,
      ),
    );
  }
}

class _PortfolioHeaderContent extends StatelessWidget {
  final String username;
  final int totalActs;
  final int totalLoves;

  const _PortfolioHeaderContent({
    required this.username,
    required this.totalActs,
    required this.totalLoves,
  });

  Widget _buildAnimatedStatColumn(ThemeData theme, String label, int value, {bool isLoves = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoves) const Text('❤️ ', style: TextStyle(fontSize: 28)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 1200),
              builder: (context, val, child) {
                return Text(
                  val.toInt().toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.7))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0).copyWith(top: kToolbarHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Impact Summary for $username',
              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimatedStatColumn(theme, 'Total Acts', totalActs),
                _buildAnimatedStatColumn(theme, 'Loves Earned', totalLoves, isLoves: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusListTile extends StatelessWidget {
  final GoodwillAction action;
  final VoidCallback? onTap;

  const _StatusListTile({required this.action, this.onTap});

  Color _getBulletColor(GoodwillStatus? status, ThemeData theme) {
    switch (status) {
      case GoodwillStatus.verified:
        return Colors.greenAccent;
      case GoodwillStatus.pendingVerification:
        return Colors.orangeAccent;
      case GoodwillStatus.rejected:
        return Colors.redAccent;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.4);
    }
  }

  IconData _getIconForAction(String? title) {
    switch (title?.toLowerCase()) {
      case 'mentorship':
        return Icons.school_outlined;
      case 'volunteering':
        return Icons.volunteer_activism_outlined;
      case 'donation':
        return Icons.monetization_on_outlined;
      default:
        return Icons.favorite_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bulletColor = _getBulletColor(action.status, theme);
    return Semantics(
      button: true,
      label: 'Goodwill action: ${action.title} with score ${action.score} loves, status: ${action.status}',
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              backgroundColor: bulletColor.withOpacity(0.3),
              radius: 16,
              child: Icon(_getIconForAction(action.title), color: bulletColor, size: 20),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: bulletColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.background, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          action.title,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          action.description,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${action.score} ❤️',
          style: theme.textTheme.titleSmall?.copyWith(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class GoodwillTimelineCard extends StatelessWidget {
  final GoodwillAction action;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const GoodwillTimelineCard({
    super.key,
    required this.action,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  IconData _getIconForAction(String? title) {
    switch (title?.toLowerCase()) {
      case 'mentorship':
        return Icons.school_outlined;
      case 'volunteering':
        return Icons.volunteer_activism_outlined;
      case 'donation':
        return Icons.monetization_on_outlined;
      default:
        return Icons.favorite_border;
    }
  }

  Widget _buildStatusIcon(GoodwillStatus? status) {
    switch (status) {
      case GoodwillStatus.verified:
        return const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20, semanticLabel: 'Verified');
      case GoodwillStatus.pendingVerification:
        return const Icon(Icons.access_time, color: Colors.orangeAccent, size: 20, semanticLabel: 'Pending Verification');
      case GoodwillStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.redAccent, size: 20, semanticLabel: 'Rejected');
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Goodwill action: ${action.title} with score ${action.score} loves',
      child: IntrinsicHeight(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AnimatedTimelineIndicator(isFirst: isFirst, isLast: isLast, icon: _getIconForAction(action.title)),
              const SizedBox(width: 16),
              Expanded(child: _buildCardContent(context, theme)),
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 16),
                child: _buildStatusIcon(action.status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, ThemeData theme) {
    return Card(
      color: theme.colorScheme.surface.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    action.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${action.score} ❤️',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              action.description,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat.yMMMd().format(action.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedTimelineIndicator extends StatefulWidget {
  final bool isFirst;
  final bool isLast;
  final IconData icon;

  const _AnimatedTimelineIndicator({
    required this.isFirst,
    required this.isLast,
    required this.icon,
  });

  @override
  State<_AnimatedTimelineIndicator> createState() => __AnimatedTimelineIndicatorState();
}

class __AnimatedTimelineIndicatorState extends State<_AnimatedTimelineIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _lineOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _lineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLine(bool visible) {
    return visible
        ? FadeTransition(
            opacity: _lineOpacity,
            child: Container(width: 2, color: Colors.white24),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!widget.isFirst) Expanded(child: _buildLine(true)),
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
          child: Icon(widget.icon, color: Theme.of(context).colorScheme.tertiary, size: 20, semanticLabel: 'Action icon'),
        ),
        if (!widget.isLast) Expanded(child: _buildLine(true)),
      ],
    );
  }
}

class _EmptyPortfolioState extends StatelessWidget {
  const _EmptyPortfolioState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note_rounded, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 24),
            Text(
              "Your Portfolio is Your Story",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "You haven't submitted any Bright Acts yet. Tap 'Record Act' on the home screen to begin your journey!",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}


