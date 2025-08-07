// lib/models/ledger_entry.dart

class LedgerEntry {
  final String id;
  final String senderWalletId;
  final String recipientWalletId;
  final int amount;
  final String? memo;
  final DateTime timestamp;

  LedgerEntry({
    required this.id,
    required this.senderWalletId,
    required this.recipientWalletId,
    required this.amount,
    this.memo,
    required this.timestamp,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as String,
      senderWalletId: json['sender_wallet_id'] as String,
      recipientWalletId: json['recipient_wallet_id'] as String,
      amount: json['amount'] as int,
      memo: json['memo'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_wallet_id': senderWalletId,
      'recipient_wallet_id': recipientWalletId,
      'amount': amount,
      'memo': memo,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

