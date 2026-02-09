/// Core Wallet model
class Wallet {
  final String id;
  final String userId;
  final String? publicAddress;
  final String? encryptedPrivateKey;
  final double balance;
  final bool isPrimary; 
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? networkType;
  final Map<String, dynamic>? metadata;

  const Wallet({
    required this.id,
    required this.userId,
    this.publicAddress,
    this.encryptedPrivateKey,
    this.balance = 0.0,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.networkType = 'mainnet',
    this.metadata,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: json['id'] as String,
        userId: json['userId'] as String,
        publicAddress: json['publicAddress'] as String?,
        encryptedPrivateKey: json['encryptedPrivateKey'] as String?,
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        isPrimary: json['isPrimary'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        isActive: json['isActive'] as bool? ?? true,
        networkType: json['networkType'] as String? ?? 'mainnet',
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'publicAddress': publicAddress,
        'encryptedPrivateKey': encryptedPrivateKey,
        'balance': balance,
        'isPrimary': isPrimary,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isActive': isActive,
        'networkType': networkType,
        'metadata': metadata,
      };

  Wallet copyWith({
    String? id,
    String? userId,
    String? publicAddress,
    String? encryptedPrivateKey,
    double? balance,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? networkType,
    Map<String, dynamic>? metadata,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      publicAddress: publicAddress ?? this.publicAddress,
      encryptedPrivateKey: encryptedPrivateKey ?? this.encryptedPrivateKey,
      balance: balance ?? this.balance,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      networkType: networkType ?? this.networkType,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Wallet Transaction
class WalletTransaction {
  final String id;
  final String walletId;
  final String type; // 'send', 'receive', 'mint', 'burn', etc.
  final double amount;
  final String? toAddress;
  final String? fromAddress;
  final String? transactionHash;
  final String status; // 'pending', 'confirmed', 'failed'
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final double? fee;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    this.toAddress,
    this.fromAddress,
    this.transactionHash,
    required this.status,
    required this.timestamp,
    this.metadata,
    this.fee,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: json['id'] as String,
        walletId: json['walletId'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        toAddress: json['toAddress'] as String?,
        fromAddress: json['fromAddress'] as String?,
        transactionHash: json['transactionHash'] as String?,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: json['metadata'] as Map<String, dynamic>?,
        fee: (json['fee'] as num?)?.toDouble(),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'walletId': walletId,
        'type': type,
        'amount': amount,
        'toAddress': toAddress,
        'fromAddress': fromAddress,
        'transactionHash': transactionHash,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
        'fee': fee,
      };

  WalletTransaction copyWith({
    String? id,
    String? walletId,
    String? type,
    double? amount,
    String? toAddress,
    String? fromAddress,
    String? transactionHash,
    String? status,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    double? fee,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      toAddress: toAddress ?? this.toAddress,
      fromAddress: fromAddress ?? this.fromAddress,
      transactionHash: transactionHash ?? this.transactionHash,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      fee: fee ?? this.fee,
    );
  }
}

/// Wallet Balance
class WalletBalance {
  final String walletId;
  final double availableBalance;
  final double pendingBalance;
  final double totalBalance;
  final String currency;
  final DateTime lastUpdated;

  const WalletBalance({
    required this.walletId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalBalance,
    this.currency = 'LOVES',
    required this.lastUpdated,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
        walletId: json['walletId'] as String,
        availableBalance: (json['availableBalance'] as num).toDouble(),
        pendingBalance: (json['pendingBalance'] as num).toDouble(),
        totalBalance: (json['totalBalance'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'LOVES',
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );
  Map<String, dynamic> toJson() => {
        'walletId': walletId,
        'availableBalance': availableBalance,
        'pendingBalance': pendingBalance,
        'totalBalance': totalBalance,
        'currency': currency,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  WalletBalance copyWith({
    String? walletId,
    double? availableBalance,
    double? pendingBalance,
    double? totalBalance,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return WalletBalance(
      walletId: walletId ?? this.walletId,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalBalance: totalBalance ?? this.totalBalance,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Wallet Key Pair
class WalletKeyPair {
  final String publicKey;
  final String privateKey;
  final String address;
  final String? mnemonic;

  const WalletKeyPair({
    required this.publicKey,
    required this.privateKey,
    required this.address,
    this.mnemonic,
  });

  factory WalletKeyPair.fromJson(Map<String, dynamic> json) => WalletKeyPair(
        publicKey: json['publicKey'] as String,
        privateKey: json['privateKey'] as String,
        address: json['address'] as String,
        mnemonic: json['mnemonic'] as String?,
      );
  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'privateKey': privateKey,
        'address': address,
        'mnemonic': mnemonic,
      };
}

/// Wallet State for UI/Views (to avoid conflict with provider state)
class WalletUiState {
  final Wallet? currentWallet;
  final WalletBalance? currentBalance;
  final List<WalletTransaction> recentTransactions;
  final bool isLoading;
  final String? error;

  const WalletUiState({
    this.currentWallet,
    this.currentBalance,
    this.recentTransactions = const [],
    this.isLoading = false,
    this.error,
  });

  WalletUiState copyWith({
    Wallet? currentWallet,
    WalletBalance? currentBalance,
    List<WalletTransaction>? recentTransactions,
    bool? isLoading,
    String? error,
  }) {
    return WalletUiState(
      currentWallet: currentWallet ?? this.currentWallet,
      currentBalance: currentBalance ?? this.currentBalance,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Transaction Types
enum WalletTransactionType {
  send,
  receive,
  mint,
  burn,
  stake,
  unstake,
  reward,
}

/// Transaction Status
enum WalletTransactionStatus {
  pending,
  confirmed,
  failed,
  cancelled,
}

/// Extensions for display names
extension WalletTransactionTypeExtension on WalletTransactionType {
  String get displayName {
    switch (this) {
      case WalletTransactionType.send:
        return 'Send';
      case WalletTransactionType.receive:
        return 'Receive';
      case WalletTransactionType.mint:
        return 'Mint';
      case WalletTransactionType.burn:
        return 'Burn';
      case WalletTransactionType.stake:
        return 'Stake';
      case WalletTransactionType.unstake:
        return 'Unstake';
      case WalletTransactionType.reward:
        return 'Reward';
    }
  }
}

extension WalletTransactionStatusExtension on WalletTransactionStatus {
  String get displayName {
    switch (this) {
      case WalletTransactionStatus.pending:
        return 'Pending';
      case WalletTransactionStatus.confirmed:
        return 'Confirmed';
      case WalletTransactionStatus.failed:
        return 'Failed';
      case WalletTransactionStatus.cancelled:
        return 'Cancelled';
    }
  }
}
