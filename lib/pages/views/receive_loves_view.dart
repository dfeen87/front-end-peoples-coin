import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../state/user_provider.dart';

class ReceiveLovesView extends ConsumerWidget {
  final VoidCallback? onTransactionComplete;

  const ReceiveLovesView({super.key, this.onTransactionComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAccountAsync = ref.watch(userAccountProvider);

    return userAccountAsync.when(
      // Show a loading indicator while the user account is being fetched.
      loading: () => const Center(child: CircularProgressIndicator()),
      // Show an error message if the data fails to load.
      error: (error, stack) => Center(
        child: Text(
          'Error: Failed to load user account: $error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
      // Once data is available, build the main content.
      data: (userAccount) {
        final walletAddress = userAccount?.walletId ?? "no-address-found";

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
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

