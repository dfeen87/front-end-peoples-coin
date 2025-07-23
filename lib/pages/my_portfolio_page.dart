// lib/pages/my_portfolio_page.dart

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

class _MyPortfolioPageState extends State<MyPortfolioPage> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to fetch data after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<MyAppAuthProvider.AuthProvider>().user?.uid;
      if (userId != null) {
        context.read<UserProvider>().fetchUserActions(userId);
      }
    });
  }

  // Helper method to build the shimmering loading skeleton
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Match theme
      appBar: AppBar(
        title: const Text('My Portfolio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // 1. Loading State
          if (userProvider.isFetchingActions) {
            return _buildLoadingSkeleton();
          }

          // 2. Error State
          if (userProvider.hasActionsError) {
            return Center(
              child: Text(
                userProvider.actionsError ?? 'An unknown error occurred.',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          // 3. Empty State
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

          // 4. Success State
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: userProvider.userActions.length,
            itemBuilder: (context, index) {
              final action = userProvider.userActions[index];
              return GoodwillActionCard(action: action);
            },
          );
        },
      ),
    );
  }
}
