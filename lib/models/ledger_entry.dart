import 'package:flutter/foundation.dart';

@immutable
class LedgerEntry {
  final String id;
  final String senderWalletId;
  final String recipientWalletId;
  final int amount;
  final String? memo;
  final DateTime timestamp;

  const LedgerEntry({
    required this.id,
    required this.senderWalletId,
    required this.recipientWalletId,
    required this.amount,
    this.memo,
    required this.timestamp,
  });

  /// Creates a new instance of [LedgerEntry] with optional new values.
  LedgerEntry copyWith({
    String? id,
    String? senderWalletId,
    String? recipientWalletId,
    int? amount,
    String? memo,
    DateTime? timestamp,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      senderWalletId: senderWalletId ?? this.senderWalletId,
      recipientWalletId: recipientWalletId ?? this.recipientWalletId,
      amount: amount ?? this.amount,
      memo: memo ?? this.memo,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Creates a LedgerEntry instance from a JSON map.
  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id']?.toString() ?? '',
      senderWalletId: json['sender_wallet_id']?.toString() ?? '',
      recipientWalletId: json['recipient_wallet_id']?.toString() ?? '',
      amount: _parseInt(json['amount']),
      memo: json['memo'] as String?,
      timestamp: _parseDate(json['timestamp']),
    );
  }

  /// Converts the LedgerEntry instance to a JSON map.
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

  // Private helper to safely parse int values.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  // Private helper to safely parse DateTime values.
  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // Fallback to Unix epoch on parse failure
        debugPrint('Warning: Failed to parse date string "$value": $e');
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

