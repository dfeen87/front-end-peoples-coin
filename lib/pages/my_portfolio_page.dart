import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/user_provider.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;
import '../widgets/goodwill_action_card.dart';
import 'package:shimmer/shimmer.dart';

class MyPortfolioPage extends StatefulWidget {
  const MyPortfolioPage({super.key});

  @override
  State<MyPortfolioPage> createState() => _MyPortfolioPageState();
}

class _MyPortfolioPageState extends State<MyPortfolioPage> with TickerProviderStateMixin {
  late AnimationController _heartController;

  @override
  void initState() {
    super.initState();

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<MyAppAuthProvider.AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<UserProvider>().fetchUserActions(userId);
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: 120.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHearts(int loves) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        loves.clamp(1, 5),
        (index) => ScaleTransition(
          scale: CurvedAnimation(
            parent: _heartController,
            curve: Interval(
              index * 0.1,
              1.0,
              curve: Curves.elasticOut,
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.0),
            child: Text('❤️', style: TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Portfolio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isFetchingActions) {
            return _buildLoadingSkeleton();
          }

          if (userProvider.hasActionsError) {
            return Center(
              child: Text(
                userProvider.actionsError ?? 'An unknown error occurred.',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (userProvider.userActions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "You haven't submitted any Bright Acts yet.\nTap 'Record Act' to get started!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: userProvider.userActions.length,
            itemBuilder: (context, index) {
              final action = userProvider.userActions[index];
              final loves = (action.score ?? 0).clamp(1, 100); // or use action.loves

              _heartController.forward(from: 0.0);

              return Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title ?? 'Bright Act',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action.description ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '💗 $loves Loves Earned',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          _buildAnimatedHearts((loves / 20).ceil()) // Up to 5 hearts
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

