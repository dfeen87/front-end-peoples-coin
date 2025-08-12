import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../state/user_provider.dart';
import '../state/auth_provider.dart' as MyAppAuthProvider;
import './views/receive_loves_view.dart';
import './views/send_loves_view.dart';
import '../widgets/animated_digit_widget.dart';

class MyWalletPage extends StatefulWidget {
  const MyWalletPage({super.key});

  @override
  State<MyWalletPage> createState() => _MyWalletPageState();
}

class _MyWalletPageState extends State<MyWalletPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  Future<void> _refreshUserData() async {
    final userProvider = context.read<UserProvider>();
    final userId = context.read<MyAppAuthProvider.AuthProvider>().user?.uid;
    if (userId != null) {
      await userProvider.fetchUser(userId);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial fetch if user data missing
    final userProvider = context.read<UserProvider>();
    if (userProvider.currentUser == null) {
      final userId = context.read<MyAppAuthProvider.AuthProvider>().user?.uid;
      if (userId != null) {
        userProvider.fetchUser(userId);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }

            if (userProvider.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userProvider.error ?? 'Failed to load wallet data.',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                      ),
                      onPressed: () => _refreshUserData(),
                    ),
                  ],
                ),
              );
            }

            final balanceStr = userProvider.currentUser?.balance ?? '0';
            final balanceDouble = double.tryParse(balanceStr) ?? 0.0;
            final formattedBalance = NumberFormat.currency(symbol: '', decimalDigits: 2).format(balanceDouble);

            return RefreshIndicator(
              onRefresh: _refreshUserData,
              color: Colors.amber,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Semantics(
                    label: 'Current Loves balance: $formattedBalance',
                    child: _AnimatedBalanceCard(balanceStr: formattedBalance),
                  ),
                  _CustomTabSwitcher(tabController: _tabController),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ReceiveLovesView(onTransactionComplete: _refreshUserData),
                        SendLovesView(onSendComplete: _refreshUserData),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedBalanceCard extends StatefulWidget {
  final String balanceStr;
  const _AnimatedBalanceCard({required this.balanceStr});

  @override
  State<_AnimatedBalanceCard> createState() => _AnimatedBalanceCardState();
}

class _AnimatedBalanceCardState extends State<_AnimatedBalanceCard> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late String _oldBalanceStr;

  @override
  void initState() {
    super.initState();
    _oldBalanceStr = widget.balanceStr;
    _animationController = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balanceStr != widget.balanceStr) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _oldBalanceStr = widget.balanceStr;
          });
          _animationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userBalance = double.tryParse(_oldBalanceStr) ?? 0.0;
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'CURRENT BALANCE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('❤️ ', style: theme.textTheme.displaySmall?.copyWith(fontSize: 38)),
                      AnimatedDigitWidget(
                        value: userBalance,
                        textStyle: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        fractionDigits: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Loves',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
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
}

class _CustomTabSwitcher extends StatelessWidget {
  final TabController tabController;

  const _CustomTabSwitcher({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: theme.colorScheme.secondaryVariant,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withOpacity(0.6),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: theme.colorScheme.onSecondary,
        unselectedLabelColor: theme.colorScheme.secondary.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          letterSpacing: 1.0,
        ),
        tabs: const [
          Tab(text: 'Receive'),
          Tab(text: 'Send'),
        ],
      ),
    );
  }
}

