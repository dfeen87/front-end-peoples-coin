// lib/pages/my_wallet_page.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';

// --- MOCK DATA MODELS AND PROVIDERS (REPLACE WITH YOUR BACKEND LOGIC) ---

/// Mock data model for a transaction.
class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final bool isCredit;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.isCredit,
  });
}

/// Mock data model for the wallet.
class Wallet {
  final double balance;
  Wallet({required this.balance});
}

// A simple provider to manage the theme mode.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// A mock stream provider for the wallet state.
/// This simulates a real-time connection to a backend,
/// which automatically pushes updates to the balance.
final walletStreamProvider = StreamProvider<Wallet>((ref) {
  final controller = StreamController<Wallet>();
  double currentBalance = 1250.75;

  // Simulate a change in balance every 5 seconds.
  Timer.periodic(const Duration(seconds: 5), (timer) {
    currentBalance += 10.00; // Simulate a received transaction
    controller.add(Wallet(balance: currentBalance));
  });

  return controller.stream;
});

/// A mock stream provider for the transaction history.
final transactionHistoryProvider = StreamProvider<List<Transaction>>((ref) {
  final controller = StreamController<List<Transaction>>();
  List<Transaction> transactions = [
    Transaction(id: '1', description: 'Initial deposit', amount: 1000.00, date: DateTime.now().subtract(const Duration(days: 30)), isCredit: true),
    Transaction(id: '2', description: 'Received from Jane', amount: 250.75, date: DateTime.now().subtract(const Duration(days: 15)), isCredit: true),
  ];

  // Simulate a new transaction being added every 5 seconds.
  Timer.periodic(const Duration(seconds: 5), (timer) {
    final newTransaction = Transaction(
      id: '3',
      description: 'Received from a friend',
      amount: 10.00,
      date: DateTime.now(),
      isCredit: true,
    );
    transactions = [...transactions, newTransaction];
    controller.add(transactions);
  });

  return controller.stream;
});

// A mock service for biometric authentication.
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticate() async {
    final canAuthenticate = await _localAuth.canCheckBiometrics;
    if (!canAuthenticate) return false;

    return await _localAuth.authenticate(
      localizedReason: 'Please authenticate to complete the transaction',
      options: const AuthenticationOptions(
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
  }
}

// --- APP-WIDE WIDGETS ---

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletAsync = ref.watch(walletStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Wallet'),
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
                      ReceiveLovesView(onTransactionComplete: () => ref.invalidate(transactionHistoryProvider)),
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
  }
}

// --- WIDGETS FOR UI COMPONENTS ---

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
      error: (e, st) => Text('Error loading history: $e'),
      data: (transactions) {
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
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(transaction.date)),
                  trailing: Text(
                    '${transaction.isCredit ? '+' : '-'} \$${transaction.amount.toStringAsFixed(2)}',
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

// --- MOCK VIEWS (FOR COMPLETENESS) ---

class ReceiveLovesView extends StatelessWidget {
  final VoidCallback onTransactionComplete;

  const ReceiveLovesView({required this.onTransactionComplete, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Receive loves view', style: TextStyle(color: Colors.white)));
  }
}

class SendLovesView extends ConsumerWidget {
  const SendLovesView({Key? key}) : super(key: key);

  Future<void> _handleSend(BuildContext context, WidgetRef ref) async {
    final service = BiometricAuthService();
    final didAuthenticate = await service.authenticate();
    if (didAuthenticate) {
      // Simulate sending logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction successful!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed. Transaction cancelled.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Send loves view'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _handleSend(context, ref),
            child: const Text('Send Loves (requires auth)'),
          ),
        ],
      ),
    );
  }
}


// --- WIDGETS FROM ORIGINAL CODE ---

class AnimatedDigitWidget extends StatelessWidget {
  final double value;
  final TextStyle textStyle;
  final int fractionDigits;

  const AnimatedDigitWidget({
    Key? key,
    required this.value,
    required this.textStyle,
    this.fractionDigits = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is a mock widget. In a real app, this would animate the digit change.
    return Text(
      value.toStringAsFixed(fractionDigits),
      style: textStyle,
    );
  }
}

// --- MAIN APP ENTRY POINT ---

void main() {
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
      home: const MyWalletPage(),
    );
  }
}

