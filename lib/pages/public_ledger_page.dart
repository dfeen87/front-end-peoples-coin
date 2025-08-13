// lib/pages/public_ledger_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:ui';

// --- MOCK DATA MODELS AND PROVIDERS (Refactored to use Riverpod) ---

class PublicLedgerEntry {
  final String id;
  final String walletId;
  final String title;
  final int lovesValue;
  final DateTime createdAt;

  PublicLedgerEntry({
    required this.id,
    required this.walletId,
    required this.title,
    required this.lovesValue,
    required this.createdAt,
  });
}

class User {
  final String id;
  final String walletId;
  User({required this.id, required this.walletId});
}

// State class to hold all ledger-related data and status flags.
class LedgerState {
  final List<PublicLedgerEntry> publicLedgerEntries;
  final bool isInitialLoading;
  final bool isFetchingMore;
  final String? errorMessage;
  final String? lastDocumentId;
  final String currentSearchQuery;

  LedgerState({
    required this.publicLedgerEntries,
    this.isInitialLoading = false,
    this.isFetchingMore = false,
    this.errorMessage,
    this.lastDocumentId,
    this.currentSearchQuery = '',
  });

  LedgerState copyWith({
    List<PublicLedgerEntry>? publicLedgerEntries,
    bool? isInitialLoading,
    bool? isFetchingMore,
    String? errorMessage,
    String? lastDocumentId,
    String? currentSearchQuery,
  }) {
    return LedgerState(
      publicLedgerEntries: publicLedgerEntries ?? this.publicLedgerEntries,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      errorMessage: errorMessage,
      lastDocumentId: lastDocumentId ?? this.lastDocumentId,
      currentSearchQuery: currentSearchQuery ?? this.currentSearchQuery,
    );
  }
}

// StateNotifier to manage the state of the public ledger.
class LedgerNotifier extends StateNotifier<LedgerState> {
  LedgerNotifier() : super(LedgerState(publicLedgerEntries: []));

  Future<void> fetchPublicLedgerEntries({bool isRefresh = false}) async {
    if (state.isFetchingMore || state.isInitialLoading) return;

    if (isRefresh) {
      state = state.copyWith(isInitialLoading: true, publicLedgerEntries: [], lastDocumentId: null);
    } else {
      state = state.copyWith(isFetchingMore: true);
    }

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Generate mock data for demonstration
      final newEntries = List.generate(
        10,
        (i) => PublicLedgerEntry(
          id: '${state.publicLedgerEntries.length + i}',
          walletId: 'wallet_${state.publicLedgerEntries.length + i}',
          title: 'Action ${state.publicLedgerEntries.length + i}',
          lovesValue: 50 + (i * 10),
          createdAt: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      state = state.copyWith(
        publicLedgerEntries: [...state.publicLedgerEntries, ...newEntries],
        isInitialLoading: false,
        isFetchingMore: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialLoading: false,
        isFetchingMore: false,
        errorMessage: 'Failed to fetch ledger entries.',
      );
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(
      isInitialLoading: true,
      publicLedgerEntries: [],
      currentSearchQuery: query,
    );
    try {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate search API call
      final mockSearchResults = List.generate(
        5,
        (i) => PublicLedgerEntry(
          id: 'search_$i',
          walletId: 'search_wallet_$i',
          title: 'Search Result for "$query" $i',
          lovesValue: 100 + i,
          createdAt: DateTime.now(),
        ),
      );
      state = state.copyWith(
        publicLedgerEntries: mockSearchResults,
        isInitialLoading: false,
        isFetchingMore: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialLoading: false,
        isFetchingMore: false,
        errorMessage: 'Failed to perform search.',
      );
    }
  }

  Future<bool> sendLoves({required String senderWallet, required String recipientWallet, required int amount, String? memo}) async {
    try {
      // Simulate sending Loves via an API
      await Future.delayed(const Duration(seconds: 1));
      print('Sending $amount Loves from $senderWallet to $recipientWallet with memo: $memo');
      return true;
    } catch (e) {
      print('Error sending loves: $e');
      return false;
    }
  }
}

// Riverpod providers for state management
final userProvider = Provider<User?>((ref) => User(id: 'user123', walletId: 'wallet_user123'));
final ledgerProvider = StateNotifierProvider<LedgerNotifier, LedgerState>((ref) {
  return LedgerNotifier();
});

// --- WIDGETS ---

class PublicLedgerPage extends ConsumerStatefulWidget {
  const PublicLedgerPage({super.key});

  @override
  ConsumerState<PublicLedgerPage> createState() => _PublicLedgerPageState();
}

class _PublicLedgerPageState extends ConsumerState<PublicLedgerPage> with TickerProviderStateMixin {
  late final AnimationController _listAnimationController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scrollController.addListener(_onScroll);
    _fetchInitialData();
  }

  void _fetchInitialData() {
    _listAnimationController.reset();
    ref.read(ledgerProvider.notifier).fetchPublicLedgerEntries(isRefresh: true).then((_) {
      if (mounted) {
        _listAnimationController.forward();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      ref.read(ledgerProvider.notifier).fetchPublicLedgerEntries();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        _fetchInitialData();
      } else {
        ref.read(ledgerProvider.notifier).search(query);
      }
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the providers to get the current state
    final ledgerState = ref.watch(ledgerProvider);
    final user = ref.watch(userProvider);
    final currentUserWalletId = user?.walletId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Public Ledger'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchInitialData(),
              color: Colors.amber,
              backgroundColor: Colors.grey[800],
              child: _buildBody(ledgerState, currentUserWalletId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by Wallet ID or Title...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: InputBorder.none,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LedgerState ledgerState, String? currentUserWalletId) {
    if (ledgerState.isInitialLoading) {
      return _buildLoadingShimmer();
    }

    if (ledgerState.errorMessage != null) {
      return Center(
        child: Text(
          'Error: ${ledgerState.errorMessage}',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (ledgerState.publicLedgerEntries.isEmpty) {
      return Center(
        child: Text(
          ledgerState.currentSearchQuery.isNotEmpty
              ? 'No results found for "${ledgerState.currentSearchQuery}".'
              : 'No public ledger entries found.',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    final itemCount = ledgerState.publicLedgerEntries.length + (ledgerState.isFetchingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= ledgerState.publicLedgerEntries.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          );
        }

        final entry = ledgerState.publicLedgerEntries[index];
        final entryCount = ledgerState.publicLedgerEntries.length;

        final animation = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(
              entryCount > 0 ? (1 / entryCount) * index : 0.0,
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: PublicActionCard(
              entry: entry,
              onSendLoves: (recipientWalletId, amount, memo) async {
                if (currentUserWalletId == null || currentUserWalletId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please sign in to send Loves.')),
                  );
                  return false;
                }
                return ref.read(ledgerProvider.notifier).sendLoves(
                  senderWallet: currentUserWalletId,
                  recipientWallet: recipientWalletId,
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
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20, top: 20),
        itemCount: 5,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          color: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: const SizedBox(height: 150),
        ),
      ),
    );
  }
}

typedef OnSendLovesCallback = Future<bool> Function(String recipientWalletId, int amount, String? memo);

class PublicActionCard extends StatefulWidget {
  final PublicLedgerEntry entry;
  final OnSendLovesCallback onSendLoves;

  const PublicActionCard({super.key, required this.entry, required this.onSendLoves});

  @override
  State<PublicActionCard> createState() => _PublicActionCardState();
}

class _PublicActionCardState extends State<PublicActionCard> with TickerProviderStateMixin {
  bool _isExpanded = false;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  bool _isSending = false;

  late final AnimationController _formAnimationController;

  @override
  void initState() {
    super.initState();
    _formAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    _formAnimationController.dispose();
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
      final success = await widget.onSendLoves(widget.entry.walletId, amount, memo);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully sent $amount Loves!')));
        _amountController.clear();
        _memoController.clear();
        setState(() {
          _isExpanded = false;
          _formAnimationController.reverse();
        });
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending loves.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending loves: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Card(
          color: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildFooter(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? FadeTransition(
                          opacity: _formAnimationController,
                          child: _buildExpansionForm(),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.amber.withOpacity(0.2),
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
              Text(
                widget.entry.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => _copyWallet(context, widget.entry.walletId),
                child: Text(
                  _abbreviateWallet(widget.entry.walletId),
                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
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
          onPressed: () {
            setState(() => _isExpanded = !_isExpanded);
            if (_isExpanded) {
              _formAnimationController.forward();
            } else {
              _formAnimationController.reverse();
            }
          },
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

// --- MAIN APP ENTRY POINT ---

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ledger App',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          accentColor: Colors.amber,
          backgroundColor: Colors.deepPurple.shade900,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: Colors.amber.shade400,
        ),
        scaffoldBackgroundColor: Colors.deepPurple.shade900,
      ),
      home: const PublicLedgerPage(),
    );
  }
}

