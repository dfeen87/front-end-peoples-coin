// lib/pages/my_wallet_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/user_provider.dart';
import './views/receive_loves_view.dart';
import './views/send_loves_view.dart';

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
    // We get the balance from UserProvider.
    final userBalance = context.watch<UserProvider>().currentUser?.balance ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber[700],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.arrow_downward), text: 'Receive'),
            Tab(icon: Icon(Icons.arrow_upward), text: 'Send'),
          ],
        ),
      ),
      body: Column(
        children: [
          // A header to show the current balance
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  'Current Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '${userBalance.toStringAsFixed(2)} Loves',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // The content of the selected tab
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
    );
  }
}
