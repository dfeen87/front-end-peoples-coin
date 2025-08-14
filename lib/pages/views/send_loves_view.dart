import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final _memoController = TextEditingController();
  bool _isLoading = false;
  bool _showMemo = false;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        _addressController.text = clipboardData.text!;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to paste from clipboard')),
        );
      }
    }
  }

  void _clearForm() {
    _addressController.clear();
    _amountController.clear();
    _memoController.clear();
    setState(() {
      _showMemo = false;
    });
  }

  Future<void> _submitSend() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to send Loves'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Confirm Transaction',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send ${_amountController.text} Loves to:',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _addressController.text,
                style: const TextStyle(
                  color: Colors.amber,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            if (_showMemo && _memoController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Memo: ${_memoController.text}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'From: ${currentUser.email}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
            ),
            child: const Text('Confirm & Send'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use ref.read() to get the current state of the providers at this moment.
      final userAccount = ref.read(userAccountProvider);
      final currentWallet = userAccount.value?.walletId;

      if (currentWallet == null || currentWallet.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wallet not found. Please try refreshing.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final recipient = _addressController.text.trim();
      final amount = int.tryParse(_amountController.text.trim()) ?? 0;
      final memo = _showMemo && _memoController.text.trim().isNotEmpty 
          ? _memoController.text.trim() 
          : null;

      // Call the method on the ledgerProvider using ref.read
      await ref.read(ledgerProvider).sendLoves(
            senderWallet: currentWallet,
            recipientWallet: recipient,
            amount: amount,
            memo: memo,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully sent $amount Loves!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      _clearForm();

      // Notify parent to refresh balance (which now invalidates the provider)
      widget.onSendComplete?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send Loves: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the wallet provider to get the current balance for validation
    final userBalanceAsync = ref.watch(walletProvider);
    final userAccount = ref.watch(userAccountProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    return userBalanceAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(height: 16),
            Text(
              'Loading wallet balance...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load wallet balance',
              style: const TextStyle(color: Colors.red, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(walletProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (wallet) {
        final userBalance = wallet?.balance ?? 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info and balance
                if (currentUser != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sending as:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              currentUser.email ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Available:',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '${userBalance.toStringAsFixed(0)} Loves',
                              style: TextStyle(
                                color: Colors.purple.shade300,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Recipient Address Field
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Recipient Address',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Enter wallet address...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste, color: Colors.white70),
                      onPressed: _pasteFromClipboard,
                      tooltip: 'Paste from clipboard',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a recipient address.';
                    }
                    if (value.trim().length < 10) {
                      return 'Please enter a valid address.';
                    }
                    // Check if sending to self
                    final currentWallet = userAccount.value?.walletId;
                    if (currentWallet != null && value.trim() == currentWallet) {
                      return 'Cannot send Loves to yourself.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Amount of Loves',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Enter amount...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    suffixText: 'Loves',
                    suffixStyle: const TextStyle(color: Colors.white70),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount.';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount greater than zero.';
                    }
                    if (amount > userBalance) {
                      return 'Insufficient balance. Available: ${userBalance.toStringAsFixed(0)} Loves';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Memo Section
                Row(
                  children: [
                    Checkbox(
                      value: _showMemo,
                      onChanged: (value) {
                        setState(() {
                          _showMemo = value ?? false;
                          if (!_showMemo) {
                            _memoController.clear();
                          }
                        });
                      },
                      activeColor: Colors.purple,
                    ),
                    const Text(
                      'Add memo (optional)',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),

                if (_showMemo) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _memoController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: 'Memo',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Optional message...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.white.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitSend,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Send Loves',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
