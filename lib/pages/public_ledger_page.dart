import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Clipboard

class PublicActionCard extends StatefulWidget {
  final Map<String, dynamic> entry;
  final Future<void> Function(String walletId, int amount)? onSendLoves;

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

  bool _isSending = false;

  @override
  void dispose() {
    _amountController.dispose();
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

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Send'),
        content: Text('Send $amount ❤️ Loves to this wallet?'),
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
        await widget.onSendLoves!(widget.entry['wallet_id'], amount);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully sent $amount Loves!')),
        );
        _amountController.clear();
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
    final title = widget.entry['title'] ?? 'No Title';
    final wallet = widget.entry['wallet_id'] ?? 'Unknown Wallet';
    final lovesValue = widget.entry['loves_value'] ?? 0;
    final createdAtStr = widget.entry['created_at'] ?? '';
    DateTime? createdAt;

    try {
      createdAt = DateTime.parse(createdAtStr);
    } catch (_) {
      createdAt = null;
    }

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
                Text(
                  'Loves: ',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$lovesValue ❤️',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
                    style: TextStyle(color: Colors.redAccent),
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
                  child: Row(
                    children: [
                      // Input for amount of loves
                      Expanded(
                        child: TextFormField(
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
                      ),
                      const SizedBox(width: 12),
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
            if (createdAt != null)
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

