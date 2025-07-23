// lib/pages/views/send_loves_view.dart

import 'package:flutter/material.dart';

class SendLovesView extends StatefulWidget {
  const SendLovesView({super.key});

  @override
  State<SendLovesView> createState() => _SendLovesViewState();
}

class _SendLovesViewState extends State<SendLovesView> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitSend() {
    if (_formKey.currentState!.validate()) {
      // Show a confirmation dialog before sending
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Transaction'),
          content: Text(
              'Are you sure you want to send ${_amountController.text} Loves to ${_addressController.text}?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            FilledButton(
              child: const Text('Confirm & Send'),
              onPressed: () {
                Navigator.of(ctx).pop();
                // TODO: Replace this with a real API call
                // For now, we simulate a success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Transaction submitted successfully! (Simulated)')),
                );
                _addressController.clear();
                _amountController.clear();
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // TODO: Add more robust address validation
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
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Please enter a valid amount greater than zero.';
                }
                // TODO: Add a check against the user's current balance
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
