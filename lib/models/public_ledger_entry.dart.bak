import 'package:flutter/foundation.dart';

@immutable
class PublicLedgerEntry {
  final String id;
  final String title;
  final int lovesValue;
  final String walletId;
  final DateTime createdAt;

  const PublicLedgerEntry({
    required this.id,
    required this.title,
    required this.lovesValue,
    required this.walletId,
    required this.createdAt,
  });

  factory PublicLedgerEntry.fromJson(Map<String, dynamic> json) {
    return PublicLedgerEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Unknown Act',
      lovesValue: json['loves_value'] as int? ?? 0,
      walletId: json['wallet_id'] as String? ?? '0x000...000',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  PublicLedgerEntry copyWith({
    String? id,
    String? title,
    int? lovesValue,
    String? walletId,
    DateTime? createdAt,
  }) {
    return PublicLedgerEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      lovesValue: lovesValue ?? this.lovesValue,
      walletId: walletId ?? this.walletId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'loves_value': lovesValue,
      'wallet_id': walletId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

