import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../state/user_provider.dart';
import './views/receive_loves_view.dart';
import './views/send_loves_view.dart';
import '../widgets/dynamic_nebula_background.dart';
import '../widgets/animated_digit_widget.dart'; // Make sure this is imported

class MyWalletPage extends StatefulWidget {
  const MyWalletPage({super.key});

  @override
  State<MyWalletPage> createState() => _MyWalletPageState();
}

class _MyWalletPageState extends State<MyWalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          SafeArea(
            child: Column(
              children: [
                _BalanceCard(),
                _CustomTabSwitcher(tabController: _tabController),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      ReceiveLovesView(),
                      SendLovesView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEW: Glassmorphism Balance Card Widget ---
class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Watch for changes in the user's balance
    final userBalance = context.watch<UserProvider>().currentUser?.balance ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  'CURRENT BALANCE',
                  style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('❤️ ', style: TextStyle(fontSize: 32)),
                    AnimatedDigitWidget(
                      value: userBalance,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                      fractionDigits: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Loves',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- NEW: Custom Tab Switcher Widget ---
class _CustomTabSwitcher extends StatelessWidget {
  final TabController tabController;

  const _CustomTabSwitcher({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.amber[800],
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Receive'),
          Tab(text: 'Send'),
        ],
      ),
    );
  }
}

