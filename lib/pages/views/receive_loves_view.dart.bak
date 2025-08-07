// lib/pages/views/receive_loves_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../state/user_provider.dart'; // Adjust path if needed

class ReceiveLovesView extends StatelessWidget {
  const ReceiveLovesView({super.key});

  @override
  Widget build(BuildContext context) {
    // For this view, we'll assume the wallet address is part of the UserAccount model.
    // In a real app, you might fetch a dedicated UserWallet object.
    final walletAddress = context.watch<UserProvider>().currentUser?.profileImageUrl ?? "no-address-found";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Share your address to receive Loves',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // QR Code Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: walletAddress,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 32),
          // Wallet Address Display
          Text(
            walletAddress,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontFamily: 'monospace'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Copy Button
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Address'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.amber[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: walletAddress));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
