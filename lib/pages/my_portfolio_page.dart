// lib/pages/my_portfolio_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // for HapticFeedback
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';

// --- CONFIGURATION ---
const String BACKEND_URL = 'https://your-flask-backend.com'; // Replace with your Flask backend URL

// --- DATA MODELS ---

/// GoodwillAction data model
class GoodwillAction {
  final String id;
  final String title;
  final String description;
  final int score;
  final DateTime createdAt;
  final GoodwillStatus status;
  final String? userId;
  final String? verificationDetails;
  final DateTime? verifiedAt;

  GoodwillAction({
    required this.id,
    required this.title,
    required this.description,
    required this.score,
    required this.createdAt,
    this.status = GoodwillStatus.pendingVerification,
    this.userId,
    this.verificationDetails,
    this.verifiedAt,
  });

  factory GoodwillAction.fromJson(Map<String, dynamic> json) {
    return GoodwillAction(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      score: json['score'],
      createdAt: DateTime.parse(json['created_at']),
      status: GoodwillStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoodwillStatus.pendingVerification,
      ),
      userId: json['user_id'],
      verificationDetails: json['verification_details'],
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'score': score,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'user_id': userId,
      'verification_details': verificationDetails,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}

enum GoodwillStatus { 
  verified, 
  pendingVerification, 
  rejected, 
  inReview,
  needsMoreInfo 
}

/// Portfolio statistics model
class PortfolioStats {
  final int totalActs;
  final int totalLoves;
  final int verifiedActs;
  final int pendingActs;
  final double averageScore;
  final DateTime? lastUpdated;

  PortfolioStats({
    required this.totalActs,
    required this.totalLoves,
    required this.verifiedActs,
    required this.pendingActs,
    required this.averageScore,
    this.lastUpdated,
  });

  factory PortfolioStats.fromJson(Map<String, dynamic> json) {
    return PortfolioStats(
      totalActs: json['total_acts'],
      totalLoves: json['total_loves'],
      verifiedActs: json['verified_acts'],
      pendingActs: json['pending_acts'],
      averageScore: json['average_score'].toDouble(),
      lastUpdated: json['last_updated'] != null ? DateTime.parse(json['last_updated']) : null,
    );
  }
}

// --- SERVICES ---

/// Portfolio API Service
class PortfolioApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> _getHeaders() async {
    final user = _auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    throw Exception('User not authenticated');
  }

  Future<List<GoodwillAction>> getUserActions({int limit = 50, int offset = 0}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$BACKEND_URL/api/portfolio/actions?limit=$limit&offset=$offset'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> actionsJson = data['actions'];
        return actionsJson.map((json) => GoodwillAction.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - please login again');
      } else {
        throw Exception('Failed to load actions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<PortfolioStats> getPortfolioStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$BACKEND_URL/api/portfolio/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return PortfolioStats.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - please login again');
      } else {
        throw Exception('Failed to load portfolio stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<GoodwillAction> submitAction({
    required String title,
    required String description,
    required int score,
    String? evidence,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$BACKEND_URL/api/portfolio/actions'),
        headers: headers,
        body: json.encode({
          'title': title,
          'description': description,
          'score': score,
          'evidence': evidence,
        }),
      );

      if (response.statusCode == 201) {
        return GoodwillAction.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body)['error'];
        throw Exception(error);
      } else {
        throw Exception('Failed to submit action: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteAction(String actionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$BACKEND_URL/api/portfolio/actions/$actionId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return; // Success
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Action not found');
      } else {
        throw Exception('Failed to delete action: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

// --- PROVIDERS ---

final portfolioApiServiceProvider = Provider<PortfolioApiService>((ref) => PortfolioApiService());

// Auth user provider (assuming this exists from wallet page)
final authUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Portfolio statistics provider
final portfolioStatsProvider = FutureProvider<PortfolioStats>((ref) async {
  final authState = await ref.watch(authUserProvider.future);
  if (authState == null) {
    throw Exception('User not authenticated');
  }
  
  final apiService = ref.read(portfolioApiServiceProvider);
  return await apiService.getPortfolioStats();
});

// A StateNotifier to manage the state of user actions
class UserActionsNotifier extends StateNotifier<AsyncValue<List<GoodwillAction>>> {
  final PortfolioApiService _apiService;

  UserActionsNotifier(this._apiService) : super(const AsyncValue.loading());

  Future<void> fetchUserActions({int limit = 50, int offset = 0}) async {
    // Only show loading if we don't have data yet
    if (state is! AsyncData) {
      state = const AsyncValue.loading();
    }

    try {
      final actions = await _apiService.getUserActions(limit: limit, offset: offset);
      state = AsyncValue.data(actions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> submitNewAction({
    required String title,
    required String description,
    required int score,
    String? evidence,
  }) async {
    try {
      final newAction = await _apiService.submitAction(
        title: title,
        description: description,
        score: score,
        evidence: evidence,
      );

      // Add the new action to the existing list
      state.whenData((actions) {
        state = AsyncValue.data([newAction, ...actions]);
      });
    } catch (e, stack) {
      // Don't update state, let the UI handle the error
      throw Exception(e);
    }
  }

  Future<void> deleteAction(String actionId) async {
    try {
      await _apiService.deleteAction(actionId);

      // Remove the action from the current list
      state.whenData((actions) {
        final updatedActions = actions.where((action) => action.id != actionId).toList();
        state = AsyncValue.data(updatedActions);
      });
    } catch (e, stack) {
      throw Exception(e);
    }
  }

  Future<void> refreshActions() async {
    await fetchUserActions();
  }
}

// The provider to access the UserActionsNotifier
final userActionsProvider = StateNotifierProvider<UserActionsNotifier, AsyncValue<List<GoodwillAction>>>((ref) {
  final apiService = ref.read(portfolioApiServiceProvider);
  final notifier = UserActionsNotifier(apiService);
  
  // Watch for auth state changes and fetch data when user is authenticated
  ref.listen(authUserProvider, (previous, next) {
    next.whenData((user) {
      if (user != null) {
        notifier.fetchUserActions();
      }
    });
  });

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

  Future<void> _refreshData() async {
    try {
      await ref.read(userActionsProvider.notifier).refreshActions();
      ref.invalidate(portfolioStatsProvider);
      _listAnimationController.reset();
      _listAnimationController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: $e')),
        );
      }
    }
  }

  void _showAddActionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddActionDialog(
        onActionSubmitted: () {
          // Refresh the actions list after successful submission
          ref.read(userActionsProvider.notifier).refreshActions();
          ref.invalidate(portfolioStatsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authAsync = ref.watch(authUserProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Authentication error: $e'),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

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
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _showAddActionDialog,
                tooltip: 'Add Goodwill Action',
              ),
            ],
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
      },
    );
  }

  Widget _buildSummaryTab(ThemeData theme, User user) {
    final userActionsAsync = ref.watch(userActionsProvider);
    final portfolioStatsAsync = ref.watch(portfolioStatsProvider);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.colorScheme.tertiary,
      backgroundColor: theme.colorScheme.background,
      child: userActionsAsync.when(
        loading: () => _buildLoadingSkeleton(theme),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error: $err',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (userActions) {
          if (userActions.isEmpty) {
            return const _EmptyPortfolioState();
          }

          // When data is available, start the animation
          _listAnimationController.forward();

          return CustomScrollView(
            slivers: [
              portfolioStatsAsync.when(
                loading: () => SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, stack) => _buildHeaderWithFallbackStats(theme, user, userActions),
                data: (stats) => _buildHeaderWithStats(theme, user, stats),
              ),
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
                            onTap: () => _showActionDetails(action),
                            onDelete: () => _deleteAction(action),
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
    final userActionsAsync = ref.watch(userActionsProvider);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.colorScheme.tertiary,
      backgroundColor: theme.colorScheme.background,
      child: userActionsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.tertiary)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load goodwill acts.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Retry'),
              ),
            ],
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
                onTap: () => _showActionDetails(action),
                onDelete: () => _deleteAction(action),
              );
            },
          );
        },
      ),
    );
  }

  void _showActionDetails(GoodwillAction action) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => ActionDetailsDialog(action: action),
    );
  }

  Future<void> _deleteAction(GoodwillAction action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Action'),
        content: Text('Are you sure you want to delete "${action.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(userActionsProvider.notifier).deleteAction(action.id);
        ref.invalidate(portfolioStatsProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Action deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete action: $e')),
          );
        }
      }
    }
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

  SliverAppBar _buildHeaderWithStats(ThemeData theme, User user, PortfolioStats stats) {
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
            _PortfolioHeaderContent(
              username: user.displayName ?? user.email?.split('@')[0] ?? 'User',
              stats: stats,
            ),
          ],
        ),
        title: Text('My Portfolio', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onBackground)),
        centerTitle: true,
      ),
    );
  }

  SliverAppBar _buildHeaderWithFallbackStats(ThemeData theme, User user, List<GoodwillAction> actions) {
    final totalLoves = actions.fold<int>(0, (sum, item) => sum + item.score);
    final totalActs = actions.length;
    
    final fallbackStats = PortfolioStats(
      totalActs: totalActs,
      totalLoves: totalLoves,
      verifiedActs: actions.where((a) => a.status == GoodwillStatus.verified).length,
      pendingActs: actions.where((a) => a.status == GoodwillStatus.pendingVerification).length,
      averageScore: totalActs > 0 ? totalLoves / totalActs : 0.0,
    );

    return _buildHeaderWithStats(theme, user, fallbackStats);
  }
}

// --- UI COMPONENTS ---

class _PortfolioHeaderContent extends StatelessWidget {
  final String username;
  final PortfolioStats stats;

  const _PortfolioHeaderContent({
    required this.username,
    required this.stats,
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
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold, 
                    color: theme.colorScheme.onBackground
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label, 
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.7)
          )
        ),
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
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7)
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimatedStatColumn(theme, 'Total Acts', stats.totalActs),
                _buildAnimatedStatColumn(theme, 'Loves Earned', stats.totalLoves, isLoves: true),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimatedStatColumn(theme, 'Verified', stats.verifiedActs),
                _buildAnimatedStatColumn(theme, 'Pending', stats.pendingActs),
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
  final VoidCallback? onDelete;

  const _StatusListTile({
    required this.action,
    this.onTap,
    this.onDelete,
  });

  Color _getBulletColor(GoodwillStatus status, ThemeData theme) {
    switch (status) {
      case GoodwillStatus.verified:
        return Colors.greenAccent;
      case GoodwillStatus.pendingVerification:
        return Colors.orangeAccent;
      case GoodwillStatus.inReview:
        return Colors.blueAccent;
      case GoodwillStatus.needsMoreInfo:
        return Colors.yellowAccent;
      case GoodwillStatus.rejected:
        return Colors.redAccent;
    }
  }

  IconData _getIconForAction(String title) {
    switch (title.toLowerCase()) {
      case 'mentorship':
        return Icons.school_outlined;
      case 'volunteering':
        return Icons.volunteer_activism_outlined;
      case 'donation':
        return Icons.monetization_on_outlined;
      case 'code contribution':
        return Icons.code;
      case 'community service':
        return Icons.groups;
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
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface, 
            fontWeight: FontWeight.bold
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7)
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Status: ${action.status.name.replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2').toLowerCase()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: bulletColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${action.score} ❤️',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.pinkAccent, 
                fontWeight: FontWeight.bold
              ),
            ),
            if (onDelete != null && action.status == GoodwillStatus.pendingVerification)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: onDelete,
                color: Colors.red.withOpacity(0.7),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class GoodwillTimelineCard extends StatelessWidget {
  final GoodwillAction action;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GoodwillTimelineCard({
    super.key,
    required this.action,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
    this.onDelete,
  });

  IconData _getIconForAction(String title) {
    switch (title.toLowerCase()) {
      case 'mentorship':
        return Icons.school_outlined;
      case 'volunteering':
        return Icons.volunteer_activism_outlined;
      case 'donation':
        return Icons.monetization_on_outlined;
      case 'code contribution':
        return Icons.code;
      case 'community service':
        return Icons.groups;
      default:
        return Icons.favorite_border;
    }
  }

  Widget _buildStatusIcon(GoodwillStatus status) {
    switch (status) {
      case GoodwillStatus.verified:
        return const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20, semanticLabel: 'Verified');
      case GoodwillStatus.pendingVerification:
        return const Icon(Icons.access_time, color: Colors.orangeAccent, size: 20, semanticLabel: 'Pending Verification');
      case GoodwillStatus.inReview:
        return const Icon(Icons.rate_review, color: Colors.blueAccent, size: 20, semanticLabel: 'In Review');
      case GoodwillStatus.needsMoreInfo:
        return const Icon(Icons.info_outline, color: Colors.yellowAccent, size: 20, semanticLabel: 'Needs More Info');
      case GoodwillStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.redAccent, size: 20, semanticLabel: 'Rejected');
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
              _AnimatedTimelineIndicator(
                isFirst: isFirst, 
                isLast: isLast, 
                icon: _getIconForAction(action.title)
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildCardContent(context, theme)),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 16),
                    child: _buildStatusIcon(action.status),
                  ),
                  if (onDelete != null && action.status == GoodwillStatus.pendingVerification)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 8),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: onDelete,
                        color: Colors.red.withOpacity(0.7),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ),
                ],
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, 
                      color: theme.colorScheme.onSurface
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${action.score} ❤️',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold, 
                    color: Colors.pinkAccent
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              action.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7), 
                height: 1.5
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd().format(action.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5)
                  ),
                ),
                Text(
                  action.status.name.replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2').toLowerCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(action.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(GoodwillStatus status) {
    switch (status) {
      case GoodwillStatus.verified:
        return Colors.greenAccent;
      case GoodwillStatus.pendingVerification:
        return Colors.orangeAccent;
      case GoodwillStatus.inReview:
        return Colors.blueAccent;
      case GoodwillStatus.needsMoreInfo:
        return Colors.yellowAccent;
      case GoodwillStatus.rejected:
        return Colors.redAccent;
    }
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
          child: Icon(
            widget.icon, 
            color: Theme.of(context).colorScheme.tertiary, 
            size: 20, 
            semanticLabel: 'Action icon'
          ),
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
            Icon(
              Icons.edit_note_rounded, 
              size: 80, 
              color: theme.colorScheme.onSurface.withOpacity(0.3)
            ),
            const SizedBox(height: 24),
            Text(
              "Your Portfolio is Your Story",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You haven't submitted any Goodwill Acts yet. Tap the '+' button to begin your journey!",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7), 
                height: 1.5
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DIALOGS ---

class AddActionDialog extends ConsumerStatefulWidget {
  final VoidCallback? onActionSubmitted;

  const AddActionDialog({super.key, this.onActionSubmitted});

  @override
  ConsumerState<AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends ConsumerState<AddActionDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scoreController = TextEditingController();
  final _evidenceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scoreController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submitAction() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final scoreText = _scoreController.text.trim();
    final evidence = _evidenceController.text.trim();

    if (title.isEmpty || description.isEmpty || scoreText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final score = int.tryParse(scoreText);
    if (score == null || score <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid score (positive integer)')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(userActionsProvider.notifier).submitNewAction(
        title: title,
        description: description,
        score: score,
        evidence: evidence.isEmpty ? null : evidence,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onActionSubmitted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goodwill action submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit action: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Goodwill Action'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Mentorship, Volunteering',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe your goodwill action...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _scoreController,
              decoration: const InputDecoration(
                labelText: 'Score (Loves) *',
                hintText: 'How many loves should this be worth?',
                border: OutlineInputBorder(),
                suffixText: '❤️',
              ),
              keyboardType: TextInputType.number,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _evidenceController,
              decoration: const InputDecoration(
                labelText: 'Evidence (optional)',
                hintText: 'Links, photos, or other proof...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              enabled: !_isSubmitting,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitAction,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

class ActionDetailsDialog extends StatelessWidget {
  final GoodwillAction action;

  const ActionDetailsDialog({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(action.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow('Description:', action.description),
            const SizedBox(height: 12),
            _DetailRow('Score:', '${action.score} ❤️'),
            const SizedBox(height: 12),
            _DetailRow('Status:', action.status.name.replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2').toLowerCase()),
            const SizedBox(height: 12),
            _DetailRow('Created:', DateFormat.yMMMd().add_jm().format(action.createdAt)),
            if (action.verifiedAt != null) ...[
              const SizedBox(height: 12),
              _DetailRow('Verified:', DateFormat.yMMMd().add_jm().format(action.verifiedAt!)),
            ],
            if (action.verificationDetails != null) ...[
              const SizedBox(height: 12),
              _DetailRow('Verification Details:', action.verificationDetails!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
