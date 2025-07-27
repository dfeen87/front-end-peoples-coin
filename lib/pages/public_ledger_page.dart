import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../state/ledger_provider.dart';
import '../state/user_provider.dart';
import '../models/public_ledger_entry.dart';
import '../widgets/dynamic_nebula_background.dart';

class PublicLedgerPage extends StatefulWidget {
  const PublicLedgerPage({super.key});

  @override
  State<PublicLedgerPage> createState() => _PublicLedgerPageState();
}

class _PublicLedgerPageState extends State<PublicLedgerPage> with TickerProviderStateMixin {
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LedgerProvider>(context, listen: false);
      provider.fetchPublicLedgerEntries().then((_) {
        if (mounted) {
          _listAnimationController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledgerProvider = context.watch<LedgerProvider>();
    final userProvider = context.watch<UserProvider>();
    // --- FIX: Using 'walletId' as confirmed in your user_account.dart model ---
    final currentUserWalletId = userProvider.currentUser?.walletId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Public Ledger'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          RefreshIndicator(
            onRefresh: () async {
              _listAnimationController.reset();
              await ledgerProvider.fetchPublicLedgerEntries();
              _listAnimationController.forward();
            },
            color: Colors.amber,
            backgroundColor: Colors.grey[800],
            child: _buildBody(ledgerProvider, currentUserWalletId),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LedgerProvider ledgerProvider, String? currentUserWalletId) {
    if (ledgerProvider.isLoading && ledgerProvider.publicLedgerEntries.isEmpty) {
      return _buildLoadingShimmer();
    }

    if (ledgerProvider.errorMessage != null) {
      return Center(child: Text('Error: ${ledgerProvider.errorMessage}', style: const TextStyle(color: Colors.redAccent)));
    }

    if (ledgerProvider.publicLedgerEntries.isEmpty) {
      return const Center(child: Text('No public ledger entries found.', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: kToolbarHeight + 20, left: 12, right: 12, bottom: 20),
      itemCount: ledgerProvider.publicLedgerEntries.length,
      itemBuilder: (context, index) {
        final entry = ledgerProvider.publicLedgerEntries[index];
        final animation = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval((1 / ledgerProvider.publicLedgerEntries.length) * index, 1.0, curve: Curves.easeOut),
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
            child: PublicActionCard(
              entry: entry,
              onSendLoves: (recipientWalletId, amount, memo) async {
                if (currentUserWalletId == null || currentUserWalletId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to send Loves.')));
                  return;
                }
                await ledgerProvider.sendLoves(
                  senderWalletId: currentUserWalletId,
                  recipientWalletId: recipientWalletId,
                  amount: amount,
                  memo: memo,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: kToolbarHeight + 20, left: 12, right: 12, bottom: 20),
        itemCount: 5,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          color: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: const SizedBox(height: 150),
        ),
      ),
    );
  }
}

typedef OnSendLovesCallback = Future<void> Function(String recipientWalletId, int amount, String? memo);

class PublicActionCard extends StatefulWidget {
  final PublicLedgerEntry entry;
  final OnSendLovesCallback? onSendLoves;

  const PublicActionCard({super.key, required this.entry, this.onSendLoves});

  @override
  State<PublicActionCard> createState() => _PublicActionCardState();
}

class _PublicActionCardState extends State<PublicActionCard> {
  bool _isExpanded = false;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  String _abbreviateWallet(String wallet) {
    if (wallet.length <= 10) return wallet;
    return '${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}';
  }

  void _copyWallet(BuildContext context, String wallet) {
    Clipboard.setData(ClipboardData(text: wallet));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet ID copied to clipboard!')));
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.tryParse(_amountController.text);
    if (amount == null) return;
    final memo = _memoController.text.trim();

    setState(() => _isSending = true);
    try {
      if (widget.onSendLoves != null) {
        await widget.onSendLoves!(widget.entry.walletId, amount, memo);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully sent $amount Loves!')));
        _amountController.clear();
        _memoController.clear();
        setState(() => _isExpanded = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending loves: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            // --- FIX: Removed the description Text widget as it doesn't exist in the model ---
            _buildFooter(),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded ? _buildExpansionForm() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.amber.withOpacity(0.2),
          // --- FIX: Use the first letter of the title since username is not available ---
          child: Text(
            widget.entry.title.isNotEmpty ? widget.entry.title[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- FIX: Display the title from the entry ---
              Text(
                widget.entry.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => _copyWallet(context, widget.entry.walletId),
                child: Text(
                  _abbreviateWallet(widget.entry.walletId),
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        Text(
          '${widget.entry.lovesValue} ❤️',
          style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat.yMMMd().add_jm().format(widget.entry.createdAt),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          icon: Icon(_isExpanded ? Icons.close : Icons.favorite_outline, size: 18),
          label: Text(_isExpanded ? 'Cancel' : 'Send Loves'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ],
    );
  }

  Widget _buildExpansionForm() {
    // ... (This part of the code was already correct and remains unchanged)
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration('Amount'),
              style: const TextStyle(color: Colors.white),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                final n = int.tryParse(val);
                if (n == null || n < 1) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoController,
              decoration: _buildInputDecoration('Memo (optional)'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _isSending
                ? const CircularProgressIndicator(color: Colors.amber)
                : ElevatedButton(
                    onPressed: _handleSend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Confirm & Send'),
                  ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

