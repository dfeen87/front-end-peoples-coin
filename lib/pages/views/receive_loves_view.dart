import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../state/user_provider.dart'; // Adjust path if needed

class ReceiveLovesView extends StatelessWidget {
  final VoidCallback? onTransactionComplete;

  const ReceiveLovesView({super.key, this.onTransactionComplete});

  @override
  Widget build(BuildContext context) {
    final walletAddress = context.watch<UserProvider>().currentUser?.walletId ?? "no-address-found";

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
          // QR Code Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: walletAddress,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 32),
          // Wallet Address Display (Selectable)
          SelectableText(
            walletAddress,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Copy to Clipboard Button
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Address'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: walletAddress));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address copied to clipboard!')),
              );
              // You could call onTransactionComplete here if you want to trigger a refresh on copy (optional)
              // onTransactionComplete?.call();
            },
          ),
        ],
      ),
    );
  }
}

