import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/public_ledger_entry.dart';

class PublicActionCard extends StatelessWidget {
  final PublicLedgerEntry entry;

  const PublicActionCard({super.key, required this.entry});

  // Shorten wallet address for compact display
  String _shortenAddress(String address) {
    if (address.length < 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: entry.performerWalletAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wallet address copied!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
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
            // Action type and Loves value row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.actionType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    semanticsLabel: 'Action type: ${entry.actionType}',
                  ),
                ),
                Text(
                  '${entry.lovesValue} Loves',
                  style: TextStyle(
                    color: Colors.amber[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  semanticsLabel: '${entry.lovesValue} Loves',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Wallet address and timestamp row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _shortenAddress(entry.performerWalletAddress),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      semanticsLabel:
                          'Wallet address: ${entry.performerWalletAddress}',
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _copyAddress(context),
                      child: const Icon(
                        Icons.copy,
                        color: Colors.white54,
                        size: 16,
                        semanticLabel: 'Copy wallet address',
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat.yMMMd().add_jm().format(entry.createdAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  semanticsLabel:
                      'Created at: ${DateFormat.yMMMMd().add_jm().format(entry.createdAt)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

