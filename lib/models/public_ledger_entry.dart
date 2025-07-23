// lib/models/public_ledger_entry.dart

class PublicLedgerEntry {
  final String actionType;
  final int lovesValue;
  final String performerWalletAddress;
  final DateTime createdAt;

  PublicLedgerEntry({
    required this.actionType,
    required this.lovesValue,
    required this.performerWalletAddress,
    required this.createdAt,
  });

  // A factory constructor for creating a new PublicLedgerEntry instance from a map.
  factory PublicLedgerEntry.fromJson(Map<String, dynamic> json) {
    return PublicLedgerEntry(
      actionType: json['action_type'] ?? 'Unknown Act',
      lovesValue: json['loves_value'] ?? 0,
      // Assumes the API provides the address in a nested 'performer' object
      performerWalletAddress: json['performer']?['wallet_address'] ?? '0x000...000',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
