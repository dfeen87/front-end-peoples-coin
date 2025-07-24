// lib/pages/public_ledger_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/ledger_provider.dart';
import '../widgets/public_action_card.dart';
// import '../widgets/matrix_text.dart'; // No longer needed as _buildLoadingSkeleton is removed

class PublicLedgerPage extends StatefulWidget {
  const PublicLedgerPage({super.key});

  @override
  State<PublicLedgerPage> createState() => _PublicLedgerPageState();
}

class _PublicLedgerPageState extends State<PublicLedgerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LedgerProvider>().fetchLedgerEntries();
    });
  }

  // The _buildLoadingSkeleton() method has been removed to simplify the loading UI.
  // The loading state is now represented by a simple CircularProgressIndicator.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Public Ledger'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<LedgerProvider>(
        builder: (context, ledgerProvider, child) {
          if (ledgerProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white), // Simple loading indicator
            );
          }

          if (ledgerProvider.error != null) {
            return Center(
              child: Text(
                ledgerProvider.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (ledgerProvider.entries.isEmpty) {
            return const Center(
              child: Text(
                "No verified acts on the ledger yet.",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: ledgerProvider.entries.length,
            itemBuilder: (context, index) {
              final entry = ledgerProvider.entries[index];
              return PublicActionCard(entry: entry);
            },
          );
        },
      ),
    );
  }
}
