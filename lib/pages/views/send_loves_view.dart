import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/ledger_provider.dart';
import '../../state/wallet_provider.dart';
import '../../state/user_provider.dart';

class SendLovesView extends ConsumerStatefulWidget {
  final VoidCallback? onSendComplete;

  const SendLovesView({super.key, this.onSendComplete});

  @override
  ConsumerState<SendLovesView> createState() => _SendLovesViewState();
}

class _SendLovesViewState extends ConsumerState<SendLovesView> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitSend() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Transaction'),
        content: Text(
          'Are you sure you want to send ${_amountController.text} Loves to ${_addressController.text}?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton(
            child: const Text('Confirm & Send'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Use ref.read() to get the current state of the providers at this moment.
    final userAccount = ref.read(userAccountProvider);
    final currentWallet = userAccount.value?.walletId;

    if (currentWallet == null || currentWallet.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to send Loves.')),
        );
      }
      return;
    }

    final recipient = _addressController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    try {
      // Call the method on the ledgerProvider using ref.read
      await ref.read(ledgerProvider).sendLoves(
            senderWallet: currentWallet,
            recipientWallet: recipient,
            amount: amount,
            memo: null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully sent $amount Loves!')),
        );
      }

      _addressController.clear();
      _amountController.clear();

      // Notify parent to refresh balance (which now invalidates the provider)
      widget.onSendComplete?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send Loves: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the wallet provider to get the current balance for validation
    final userBalanceAsync = ref.watch(walletProvider);
    final userBalance = userBalanceAsync.value?.balance ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Recipient Address Field
            TextFormField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Recipient Address',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a recipient address.';
                }
                if (value.length < 10) {
                  return 'Please enter a valid address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Amount Field
            TextFormField(
              controller: _amountController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Amount of Loves',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount.';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount greater than zero.';
                }
                if (amount > userBalance) {
                  return 'Insufficient balance.';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitSend,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send Loves', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

