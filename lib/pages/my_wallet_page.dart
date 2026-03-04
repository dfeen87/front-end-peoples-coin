// lib/pages/my_wallet_page.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../service/api_client.dart';

// --- DATA MODELS ---

/// Transaction data model
class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final bool isCredit;
  final String? fromUserId;
  final String? toUserId;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.isCredit,
    this.fromUserId,
    this.toUserId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      isCredit: json['is_credit'] as bool? ?? false,
      fromUserId: json['from_user_id'] as String?,
      toUserId: json['to_user_id'] as String?,
    );
  }
}

/// Wallet data model
class Wallet {
  final double balance;
  final String userId;
  final DateTime lastUpdated;

  Wallet({
    required this.balance,
    required this.userId,
    required this.lastUpdated,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: json['balance'].toDouble(),
      userId: json['user_id'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

// --- SERVICES ---

/// Firebase Authentication Service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getIdToken() async {
    final user = currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

/// API Service for backend communication — delegates to PeoplesCoinApiClient
class ApiService {
  final PeoplesCoinApiClient _apiClient;
  final AuthService _authService = AuthService();

  ApiService(this._apiClient);

  Future<String> _getIdToken() async {
    final token = await _authService.getIdToken();
    if (token == null || token.isEmpty) throw Exception('User not authenticated');
    return token;
  }

  Future<Wallet> getWallet() async {
    final idToken = await _getIdToken();
    final json = await _apiClient.getJson('api/wallet', idToken: idToken);
    return Wallet.fromJson(json);
  }

  Future<List<Transaction>> getTransactions({int limit = 50, int offset = 0}) async {
    final idToken = await _getIdToken();
    final data = await _apiClient.getJson(
      'api/transactions',
      idToken: idToken,
      queryParams: {'limit': limit, 'offset': offset},
    );
    final List<dynamic> transactions = data['transactions'] ?? [];
    return transactions.map((j) => Transaction.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> sendLoves({
    required String recipientEmail,
    required double amount,
    required String description,
  }) async {
    final idToken = await _getIdToken();
    await _apiClient.postJson(
      'api/send',
      idToken: idToken,
      body: {
        'recipient_email': recipientEmail,
        'amount': amount,
        'description': description,
      },
    );
  }

  Future<Map<String, dynamic>> generateReceiveLink({
    required double amount,
    String? description,
  }) async {
    final idToken = await _getIdToken();
    return await _apiClient.postJson(
      'api/generate-receive-link',
      idToken: idToken,
      body: {
        'amount': amount,
        if (description != null) 'description': description,
      },
    );
  }
}

// --- PROVIDERS ---

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final apiServiceProvider = Provider<ApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiService(apiClient);
});

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.read(authServiceProvider);
  return authService.authStateChanges;
});

// Theme provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Wallet stream provider with real Firebase data
final walletStreamProvider = StreamProvider<Wallet>((ref) async* {
  final apiService = ref.read(apiServiceProvider);
  final userStream = ref.watch(authStateProvider.stream);
  
  await for (final user in userStream) {
    if (user != null) {
      // Initial load
      yield await apiService.getWallet();
      
      // Poll for updates every 30 seconds
      yield* Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
        try {
          return await apiService.getWallet();
        } catch (e) {
          // If there's an error, re-throw to be handled by the UI
          throw e;
        }
      });
    }
  }
});

// Transaction history provider with real Firebase data
final transactionHistoryProvider = StreamProvider<List<Transaction>>((ref) async* {
  final apiService = ref.read(apiServiceProvider);
  final userStream = ref.watch(authStateProvider.stream);
  
  await for (final user in userStream) {
    if (user != null) {
      // Initial load
      yield await apiService.getTransactions();
      
      // Poll for updates every 30 seconds
      yield* Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
        try {
          return await apiService.getTransactions();
        } catch (e) {
          throw e;
        }
      });
    }
  }
});

// Biometric authentication service
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      if (!canAuthenticate) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to complete the transaction',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}

// --- MAIN WALLET PAGE ---

class MyWalletPage extends ConsumerStatefulWidget {
  const MyWalletPage({super.key});

  @override
  ConsumerState<MyWalletPage> createState() => _MyWalletPageState();
}

class _MyWalletPageState extends ConsumerState<MyWalletPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleSignOut() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authAsync = ref.watch(authStateProvider);
    final walletAsync = ref.watch(walletStreamProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Authentication error: $e'),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          // User not authenticated, redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('My Wallet - ${user.email ?? 'User'}'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(ref.watch(themeModeProvider) == ThemeMode.light ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  ref.read(themeModeProvider.notifier).state =
                      ref.read(themeModeProvider) == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _handleSignOut,
              ),
            ],
          ),
          body: walletAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
            error: (e, st) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load wallet data: $e',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                    ),
                    onPressed: () {
                      ref.invalidate(walletStreamProvider);
                    },
                  ),
                ],
              ),
            ),
            data: (wallet) {
              final balanceStr = wallet.balance.toStringAsFixed(2);
              final formattedBalance = NumberFormat.currency(symbol: '', decimalDigits: 2).format(wallet.balance);

              return SafeArea(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Semantics(
                      label: 'Current Loves balance: $formattedBalance',
                      child: _AnimatedBalanceCard(balanceStr: balanceStr),
                    ),
                    _CustomTabSwitcher(tabController: _tabController),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          ReceiveLovesView(onTransactionComplete: () {
                            ref.invalidate(transactionHistoryProvider);
                            ref.invalidate(walletStreamProvider);
                          }),
                          SendLovesView(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TransactionHistoryView(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- UI COMPONENTS (keeping the same design) ---

class _AnimatedBalanceCard extends StatefulWidget {
  final String balanceStr;
  const _AnimatedBalanceCard({required this.balanceStr});

  @override
  State<_AnimatedBalanceCard> createState() => _AnimatedBalanceCardState();
}

class _AnimatedBalanceCardState extends State<_AnimatedBalanceCard> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late String _oldBalanceStr;

  @override
  void initState() {
    super.initState();
    _oldBalanceStr = widget.balanceStr;
    _animationController = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balanceStr != widget.balanceStr) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _oldBalanceStr = widget.balanceStr;
          });
          _animationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userBalance = double.tryParse(_oldBalanceStr) ?? 0.0;
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'CURRENT BALANCE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('❤️ ', style: theme.textTheme.displaySmall?.copyWith(fontSize: 38)),
                      AnimatedDigitWidget(
                        value: userBalance,
                        textStyle: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        fractionDigits: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Loves',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomTabSwitcher extends StatelessWidget {
  final TabController tabController;

  const _CustomTabSwitcher({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: theme.colorScheme.secondary,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withOpacity(0.6),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: theme.colorScheme.onSecondary,
        unselectedLabelColor: theme.colorScheme.secondary.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          letterSpacing: 1.0,
        ),
        tabs: const [
          Tab(text: 'Receive'),
          Tab(text: 'Send'),
        ],
      ),
    );
  }
}

class _TransactionHistoryView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionHistoryProvider);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Error loading history: $e'),
            ElevatedButton(
              onPressed: () => ref.invalidate(transactionHistoryProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (transactions) {
        if (transactions?.isEmpty == true) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'No transactions yet',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                'Transaction History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: transaction.isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    child: Icon(
                      transaction.isCredit ? Icons.add : Icons.remove,
                      color: transaction.isCredit ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(transaction.description),
                  subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(transaction.date)),
                  trailing: Text(
                    '${transaction.isCredit ? '+' : '-'} ${transaction.amount.toStringAsFixed(2)} ❤️',
                    style: TextStyle(
                      color: transaction.isCredit ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// --- SEND AND RECEIVE VIEWS ---

class ReceiveLovesView extends ConsumerStatefulWidget {
  final VoidCallback onTransactionComplete;

  const ReceiveLovesView({required this.onTransactionComplete, Key? key}) : super(key: key);

  @override
  ConsumerState<ReceiveLovesView> createState() => _ReceiveLovesViewState();
}

class _ReceiveLovesViewState extends ConsumerState<ReceiveLovesView> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedLink;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _generateReceiveLink() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.generateReceiveLink(
        amount: amount!,
        description: _descriptionController.text?.isEmpty == true ? null : _descriptionController.text,
      );
      
      setState(() {
        _generatedLink = result['link'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receive link generated! Share it with others.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount to receive',
              prefixText: '❤️ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isGenerating ? null : _generateReceiveLink,
            child: _isGenerating
                ? const CircularProgressIndicator()
                : const Text('Generate Receive Link'),
          ),
          if (_generatedLink != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share this link:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(_generatedLink!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SendLovesView extends ConsumerStatefulWidget {
  const SendLovesView({Key? key}) : super(key: key);

  @override
  ConsumerState<SendLovesView> createState() => _SendLovesViewState();
}

class _SendLovesViewState extends ConsumerState<SendLovesView> {
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final email = _emailController.text.trim();
    final amount = double.tryParse(_amountController.text);
    final description = _descriptionController.text.trim();

    if (email?.isEmpty == true || amount == null || amount <= 0 || description?.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields with valid values')),
      );
      return;
    }

    // Biometric authentication
    final service = BiometricAuthService();
    final didAuthenticate = await service.authenticate();
    
    if (!didAuthenticate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed. Transaction cancelled.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.sendLoves(
        recipientEmail: email,
        amount: amount!,
        description: description,
      );

      // Clear form
      _emailController.clear();
      _amountController.clear();
      _descriptionController.clear();

      // Refresh data
      ref.invalidate(walletStreamProvider);
      ref.invalidate(transactionHistoryProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction successful! ❤️')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Recipient email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount to send',
              prefixText: '❤️ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSending ? null : _handleSend,
            child: _isSending
                ? const CircularProgressIndicator()
                : const Text('Send Loves (requires auth)'),
          ),
        ],
      ),
    );
  }
}

// --- ANIMATED DIGIT WIDGET ---

class AnimatedDigitWidget extends StatelessWidget {
  final double value;
  final TextStyle? textStyle;
  final int fractionDigits;

  const AnimatedDigitWidget({
    Key? key,
    required this.value,
    this.textStyle,
    this.fractionDigits = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      value.toStringAsFixed(fractionDigits),
      style: textStyle,
    );
  }
}

// --- MAIN APP ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase here
  // await Firebase.initializeApp();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loves Wallet',
      themeMode: themeMode,
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.pink,
          accentColor: Colors.amber,
          backgroundColor: Colors.pink.shade50,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.pink.shade50,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.pink,
          accentColor: Colors.amber,
          backgroundColor: Colors.grey.shade900,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/wallet': (context) => const MyWalletPage(),
      },
    );
  }
}

// --- AUTHENTICATION WRAPPER ---

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Authentication error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(authStateProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        if (user != null) {
          return const MyWalletPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

// --- LOGIN PAGE ---

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email?.isEmpty == true || password?.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = FirebaseAuth.instance;
      
      if (_isSignUp) {
        await auth.createUserWithEmailAndPassword(email: email, password: password);
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      }

      // Navigation will be handled automatically by AuthWrapper
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email.';
          break;
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = e.message ?? 'An error occurred during authentication.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Title
              Text(
                '❤️ Loves Wallet',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Email field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              
              // Password field
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              
              // Auth button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isSignUp ? 'Sign Up' : 'Sign In',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
              
              // Toggle sign up/sign in
              TextButton(
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                  });
                },
                child: Text(
                  _isSignUp 
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Sign Up',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
