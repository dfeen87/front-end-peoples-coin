import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // for HapticFeedback

import '../state/user_provider.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;
import '../models/goodwill_action.dart';
import '../widgets/dynamic_nebula_background.dart';

class MyPortfolioPage extends StatefulWidget {
  const MyPortfolioPage({super.key});

  @override
  State<MyPortfolioPage> createState() => _MyPortfolioPageState();
}

class _MyPortfolioPageState extends State<MyPortfolioPage> with TickerProviderStateMixin {
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<MyAppAuthProvider.AuthProvider>();
      final user = authProvider.user;
      final idToken = user != null ? await user.getIdToken() : null;

      if (user != null && idToken != null) {
        await context.read<UserProvider>().fetchUserActions();
        if (mounted) {
          _listAnimationController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Portfolio'),
        backgroundColor: Colors.amber[800],
        bottom: TabBar(
          controller: _mainTabController,
          tabs: const [
            Tab(text: 'Summary', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Status', icon: Icon(Icons.info_outline)),
          ],
        ),
      ),
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          TabBarView(
            controller: _mainTabController,
            children: [
              _buildSummaryTab(),
              _buildStatusTab(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return Container(
      color: Colors.black.withOpacity(0.4), // translucent dark glass effect
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoadingActions && userProvider.userActions.isEmpty) {
            return _buildLoadingSkeleton();
          }

          if (userProvider.actionsError != null) {
            return Center(
              child: Text(
                userProvider.actionsError ?? 'An error occurred.',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (userProvider.userActions.isEmpty) {
            return const _EmptyPortfolioState();
          }

          return _buildPortfolioContent(userProvider);
        },
      ),
    );
  }

  Widget _buildStatusTab() {
    return Container(
      color: Colors.black.withOpacity(0.4), // same translucent background
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoadingActions && userProvider.userActions.isEmpty) {
            return Center(child: CircularProgressIndicator(color: Colors.amber[800]));
          }

          if (userProvider.actionsError != null) {
            return Center(
              child: Text(
                userProvider.actionsError ?? 'Failed to load goodwill acts.',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (userProvider.userActions.isEmpty) {
            return const Center(
              child: Text(
                'No Goodwill Actions found.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: userProvider.userActions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final action = userProvider.userActions[index];
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

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: MediaQuery.of(context).padding.top + 20,
          bottom: 20,
        ),
        children: [
          Container(height: 120, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Container(height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 16),
          Container(height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 16),
          Container(height: 100, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12))),
        ],
      ),
    );
  }

  Widget _buildPortfolioContent(UserProvider userProvider) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          expandedHeight: 220.0,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.black.withOpacity(0.5)),
                _buildHeader(userProvider),
              ],
            ),
            title: const Text('My Portfolio', style: TextStyle(fontSize: 16)),
            centerTitle: true,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final action = userProvider.userActions[index];
                final animation = Tween(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      (1 / userProvider.userActions.length) * index,
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
                      isLast: index == userProvider.userActions.length - 1,
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
              childCount: userProvider.userActions.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(UserProvider userProvider) {
    final totalLoves = userProvider.userActions.fold<int>(0, (sum, item) => sum + (item.score ?? 0));
    final totalActs = userProvider.userActions.length;
    final username = userProvider.currentUser?.username ?? 'User';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0).copyWith(top: kToolbarHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Impact Summary for $username',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimatedStatColumn('Total Acts', totalActs),
                _buildAnimatedStatColumn('Loves Earned', totalLoves, isLoves: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStatColumn(String label, int value, {bool isLoves = false}) {
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
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}

/// This widget represents a single item in the Status tab list with a colored bullet for status.
class _StatusListTile extends StatelessWidget {
  final GoodwillAction action;
  final VoidCallback? onTap;

  const _StatusListTile({required this.action, this.onTap});

  Color _getBulletColor(GoodwillStatus? status) {
    switch (status) {
      case GoodwillStatus.verified:
        return Colors.greenAccent;
      case GoodwillStatus.pendingVerification:
        return Colors.orangeAccent;
      case GoodwillStatus.rejected:
        return Colors.redAccent;
      default:
        return Colors.grey;
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
    final bulletColor = _getBulletColor(action.status);
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
            // small status indicator dot on top right
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: bulletColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          action.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          action.description,
          style: const TextStyle(color: Colors.white70),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${action.score} ❤️',
          style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Keeps your old timeline card for the summary tab's list with animations.
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
              Expanded(child: _buildCardContent(context)),
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

  Widget _buildCardContent(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${action.score} ❤️',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              action.description,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat.yMMMd().format(action.createdAt),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
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
          backgroundColor: Colors.amber.withOpacity(0.3),
          child: Icon(widget.icon, color: Colors.amber, size: 20, semanticLabel: 'Action icon'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note_rounded, size: 80, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 24),
            const Text(
              "Your Portfolio is Your Story",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "You haven't submitted any Bright Acts yet. Tap 'Record Act' on the home screen to begin your journey!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

