// lib/pages/public_ledger_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/ledger_provider.dart';
import '../widgets/public_action_card.dart';
// NEW: We need to import the MatrixText widget's file or main.dart if it's still there.
// For now, I'll assume it's in a separate file as good practice.
// If you haven't moved it yet, change the import to: import '../../main.dart';
import '../widgets/matrix_text.dart';


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

  // UPDATED: This method now builds a loading skeleton with the Matrix effect.
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, __) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MatrixText(
                    text: "Action Type Placeholder",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'monospace'),
                    speed: const Duration(milliseconds: 80),
                  ),
                  MatrixText(
                    text: "XX Loves",
                    style: TextStyle(
                        color: Colors.amber[600],
                        fontSize: 16,
                        fontFamily: 'monospace'),
                    speed: const Duration(milliseconds: 80),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom row placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   MatrixText(
                    text: "0x000...0000",
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'monospace'),
                    speed: const Duration(milliseconds: 80),
                  ),
                  MatrixText(
                    text: "Date Plchldr",
                     style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
                     speed: const Duration(milliseconds: 80),
                  ),
                ],
              ),
            ],
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
        title: const Text('Public Ledger'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<LedgerProvider>(
        builder: (context, ledgerProvider, child) {
          if (ledgerProvider.isLoading) {
            return _buildLoadingSkeleton();
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
