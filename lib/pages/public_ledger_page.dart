// lib/pages/public_ledger_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:intl/intl.dart'; // For DateFormat
import 'package:provider/provider.dart';

// Import your state providers
import '../state/ledger_provider.dart'; // Adjust path as per your project structure
import '../state/user_provider.dart'; // Adjust path as per your project structure

// Import your models
import '../models/public_ledger_entry.dart'; // Important: Ensure this model is correctly defined
import '../models/user_account.dart'; // Important: Ensure UserAccount has 'walletId'


// --- PublicLedgerPage Definition ---
class PublicLedgerPage extends StatefulWidget {
  const PublicLedgerPage({super.key});

  @override
  State<PublicLedgerPage> createState() => _PublicLedgerPageState();
}

class _PublicLedgerPageState extends State<PublicLedgerPage> {
  @override
  void initState() {
    super.initState();
    // Fetch initial data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LedgerProvider>(context, listen: false).fetchPublicLedgerEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access LedgerProvider to get public entries
    final ledgerProvider = Provider.of<LedgerProvider>(context);
    // Access UserProvider to get the current user's wallet ID for sending loves
    final userProvider = Provider.of<UserProvider>(context);

    // FIX: Access 'currentUser' getter from UserProvider, then its 'walletId' property from UserAccount.
    // This assumes UserProvider has a 'currentUser' getter (UserAccount?) and UserAccount has a 'walletId'.
    final currentUserWalletId = userProvider.currentUser?.walletId;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Public Ledger',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // For back button
      ),
      extendBodyBehindAppBar: true, // Allows content to go behind the app bar
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A), // Dark Blue
              Color(0xFF1B263B), // Slightly Lighter Blue
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => ledgerProvider.fetchPublicLedgerEntries(),
          color: Colors.amber, // Color of the refresh indicator
          backgroundColor: Colors.grey[800],
          child: Builder(
            builder: (context) {
              if (ledgerProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                );
              } else if (ledgerProvider.errorMessage != null) {
                return Center(
                  child: Text(
                    'Error: ${ledgerProvider.errorMessage}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              } else if (ledgerProvider.publicLedgerEntries.isEmpty) {
                return const Center(
                  child: Text(
                    'No public ledger entries found.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: kToolbarHeight + 20), // Adjust padding for app bar
                itemCount: ledgerProvider.publicLedgerEntries.length,
                itemBuilder: (context, index) {
                  final entry = ledgerProvider.publicLedgerEntries[index];
                  return PublicActionCard(
                    // FIX: Pass PublicLedgerEntry object directly
                    entry: entry,
                    // Pass the sendLoves function from LedgerProvider
                    onSendLoves: ({
                      required String senderWalletId, // This parameter is ignored here; PublicLedgerPage provides the actual sender.
                      required String recipientWalletId,
                      required int amount,
                      String? memo,
                    }) async {
                      if (currentUserWalletId == null || currentUserWalletId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please sign in to send Loves.')),
                        );
                        return; // Exit if no sender wallet ID
                      }
                      await ledgerProvider.sendLoves(
                        senderWalletId: currentUserWalletId, // Use the current user's wallet ID from UserProvider
                        recipientWalletId: recipientWalletId,
                        amount: amount,
                        memo: memo,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- PublicActionCard Definition (Now updated to accept PublicLedgerEntry) ---
// We need to define a more specific type for onSendLoves
// to include senderId and memo, which the LedgerProvider's
// sendLoves likely needs.
typedef OnSendLovesCallback = Future<void> Function({
  required String senderWalletId, // Add senderWalletId
  required String recipientWalletId,
  required int amount,
  String? memo, // Add optional memo
});


class PublicActionCard extends StatefulWidget {
  // FIX: Changed type from Map<String, dynamic> to PublicLedgerEntry
  final PublicLedgerEntry entry;
  // --- Updated the type of onSendLoves to our new typedef ---
  final OnSendLovesCallback? onSendLoves;

  const PublicActionCard({
    super.key,
    required this.entry,
    this.onSendLoves,
  });

  @override
  State<PublicActionCard> createState() => _PublicActionCardState();
}

class _PublicActionCardState extends State<PublicActionCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController(); // NEW: Controller for memo

  bool _isSending = false;

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose(); // Dispose the new memo controller
    super.dispose();
  }

  String _abbreviateWallet(String wallet) {
    if (wallet.length <= 10) return wallet;
    return '${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}';
  }

  void _copyWallet(BuildContext context, String wallet) {
    Clipboard.setData(ClipboardData(text: wallet));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet ID copied to clipboard!')),
    );
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(_amountController.text);
    if (amount == null) return;

    final memo = _memoController.text.trim(); // Get memo text

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Send'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send $amount ❤️ Loves to this wallet?'),
            if (memo.isNotEmpty) Text('Memo: "$memo"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return; // user canceled

    setState(() {
      _isSending = true;
    });

    try {
      if (widget.onSendLoves != null) {
        // --- Call the updated onSendLoves with all required parameters ---
        await widget.onSendLoves!(
          senderWalletId: '', // This will be set by the PublicLedgerPage where PublicActionCard is used
          // FIX: Access walletId directly from the PublicLedgerEntry object
          recipientWalletId: widget.entry.walletId,
          amount: amount,
          memo: memo,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully sent $amount Loves!')),
        );
        _amountController.clear();
        _memoController.clear(); // Clear memo controller
        setState(() {
          _isExpanded = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Send Loves action not configured')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending loves: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Access properties directly from the PublicLedgerEntry object
    final title = widget.entry.title;
    final wallet = widget.entry.walletId;
    final lovesValue = widget.entry.lovesValue;
    // createdAt is already a DateTime in PublicLedgerEntry, no need to parse here.
    final createdAt = widget.entry.createdAt;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            // Wallet (tap to copy)
            GestureDetector(
              onTap: () => _copyWallet(context, wallet),
              child: Row(
                children: [
                  const Icon(Icons.copy, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _abbreviateWallet(wallet),
                    style: TextStyle(
                      color: Colors.amber[400],
                      fontFamily: 'Courier',
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.amber,
                      decorationStyle: TextDecorationStyle.dotted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Loves count + Send Loves button
            Row(
              children: [
                const Text(
                  'Loves: ',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$lovesValue ❤️',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.close : Icons.favorite,
                    color: Colors.redAccent,
                  ),
                  label: Text(
                    _isExpanded ? 'Cancel' : 'Send Loves',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
            // Expandable send loves form
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Form(
                  key: _formKey,
                  child: Column( // Changed to Column to stack input and memo
                    children: [
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount (min 1)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.amber.withOpacity(0.7)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Required';
                          }
                          final n = int.tryParse(val);
                          if (n == null || n < 1) {
                            return 'Enter a positive number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12), // Spacing between amount and memo
                      TextFormField(
                        controller: _memoController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'Memo (optional)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.amber.withOpacity(0.7)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLength: 100, // Optional: Limit memo length
                      ),
                      const SizedBox(height: 12), // Spacing before button
                      // Confirm button
                      _isSending
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : ElevatedButton(
                              onPressed: _handleSend,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                minimumSize: const Size(48, 48),
                              ),
                              child: const Icon(Icons.send),
                            ),
                    ],
                  ),
                ),
              ),
            // FIX: No need for null check on createdAt, it's now a non-nullable DateTime in the model
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Date: ${DateFormat.yMMMd().add_jm().format(createdAt)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
