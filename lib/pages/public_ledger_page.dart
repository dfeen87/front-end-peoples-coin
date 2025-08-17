// lib/pages/public_ledger_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:async';
import 'dart:ui';
import 'dart:convert';

// --- DATA MODELS ---

class PublicLedgerEntry {
  final String id;
  final String walletId;
  final String title;
  final int lovesValue;
  final DateTime createdAt;
  final String? description;
  final String? transactionHash;

  PublicLedgerEntry({
    required this.id,
    required this.walletId,
    required this.title,
    required this.lovesValue,
    required this.createdAt,
    this.description,
    this.transactionHash,
  });

  factory PublicLedgerEntry.fromJson(Map<String, dynamic> json) {
    return PublicLedgerEntry(
      id: json['id'] ?? '',
      walletId: json['wallet_id'] ?? json['walletId'] ?? '',
      title: json['title'] ?? '',
      lovesValue: (json['loves_value'] ?? json['lovesValue'] ?? 0).toInt(),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      description: json['description'],
      transactionHash: json['transaction_hash'] ?? json['transactionHash'],
    );
  }
}

class User {
  final String id;
  final String walletId;
  final String? name;
  final String? email;

  User({
    required this.id,
    required this.walletId,
    this.name,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      walletId: json['wallet_id'] ?? json['walletId'] ?? '',
      name: json['name'],
      email: json['email'],
    );
  }
}

// --- FLASK API SERVICE ---

class FlaskLedgerService {
  final String baseUrl;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  FlaskLedgerService({required this.baseUrl});

  // Get Firebase ID token for authentication with Flask
  Future<String?> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getIdToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<PublicLedgerEntry>> fetchPublicLedgerEntries({
    int limit = 10,
    String? lastDocumentId,
    String? searchQuery,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (lastDocumentId != null) {
        queryParams['after'] = lastDocumentId;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final uri = Uri.parse('$baseUrl/api/ledger/entries')
          .replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> entries = data['entries'] ?? data['data'] ?? [];
        
        return entries
            .map((entry) => PublicLedgerEntry.fromJson(entry))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please sign in again.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch ledger entries');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  Future<bool> sendLoves({
    required String senderWallet,
    required String recipientWallet,
    required int amount,
    String? memo,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/ledger/send-loves'),
        headers: headers,
        body: json.encode({
          'sender_wallet': senderWallet,
          'recipient_wallet': recipientWallet,
          'amount': amount,
          'memo': memo,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please sign in again.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send loves');
      }
    } catch (e) {
      print('Error sending loves: $e');
      if (e is Exception) rethrow;
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        await firebaseUser.getIdToken(true);
        return getCurrentUser(); // Retry once
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }
}

// --- STATE MANAGEMENT ---

class LedgerState {
  final List<PublicLedgerEntry> publicLedgerEntries;
  final bool isInitialLoading;
  final bool isFetchingMore;
  final String? errorMessage;
  final String? lastDocumentId;
  final String currentSearchQuery;
  final bool hasMoreData;

  LedgerState({
    required this.publicLedgerEntries,
    this.isInitialLoading = false,
    this.isFetchingMore = false,
    this.errorMessage,
    this.lastDocumentId,
    this.currentSearchQuery = '',
    this.hasMoreData = true,
  });

  LedgerState copyWith({
    List<PublicLedgerEntry>? publicLedgerEntries,
    bool? isInitialLoading,
    bool? isFetchingMore,
    String? errorMessage,
    String? lastDocumentId,
    String? currentSearchQuery,
    bool? hasMoreData,
  }) {
    return LedgerState(
      publicLedgerEntries: publicLedgerEntries ?? this.publicLedgerEntries,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      errorMessage: errorMessage,
      lastDocumentId: lastDocumentId ?? this.lastDocumentId,
      currentSearchQuery: currentSearchQuery ?? this.currentSearchQuery,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }
}

class LedgerNotifier extends StateNotifier<LedgerState> {
  final FlaskLedgerService _service;

  LedgerNotifier(this._service) : super(LedgerState(publicLedgerEntries: []));

  Future<void> fetchPublicLedgerEntries({bool isRefresh = false}) async {
    if ((state.isFetchingMore || state.isInitialLoading) && !isRefresh) return;
    if (!state.hasMoreData && !isRefresh) return;

    if (isRefresh) {
      state = state.copyWith(
        isInitialLoading: true,
        publicLedgerEntries: [],
        lastDocumentId: null,
        hasMoreData: true,
        errorMessage: null,
      );
    } else {
      state = state.copyWith(isFetchingMore: true, errorMessage: null);
    }

    try {
      final newEntries = await _service.fetchPublicLedgerEntries(
        limit: 10,
        lastDocumentId: isRefresh ? null : state.lastDocumentId,
        searchQuery: state.currentSearchQuery.isEmpty ? null : state.currentSearchQuery,
      );

      final updatedEntries = isRefresh 
          ? newEntries 
          : [...state.publicLedgerEntries, ...newEntries];

      final lastDocId = newEntries.isNotEmpty ? newEntries.last.id : state.lastDocumentId;

      state = state.copyWith(
        publicLedgerEntries: updatedEntries,
        isInitialLoading: false,
        isFetchingMore: false,
        lastDocumentId: lastDocId,
        hasMoreData: newEntries.length >= 10,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialLoading: false,
        isFetchingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(
      isInitialLoading: true,
      publicLedgerEntries: [],
      currentSearchQuery: query,
      lastDocumentId: null,
      hasMoreData: true,
      errorMessage: null,
    );

    try {
      final searchResults = await _service.fetchPublicLedgerEntries(
        limit: 10,
        searchQuery: query.isEmpty ? null : query,
      );

      state = state.copyWith(
        publicLedgerEntries: searchResults,
        isInitialLoading: false,
        isFetchingMore: false,
        lastDocumentId: searchResults.isNotEmpty ? searchResults.last.id : null,
        hasMoreData: searchResults.length >= 10,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialLoading: false,
        isFetchingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> sendLoves({
    required String senderWallet,
    required String recipientWallet,
    required int amount,
    String? memo,
  }) async {
    try {
      return await _service.sendLoves(
        senderWallet: senderWallet,
        recipientWallet: recipientWallet,
        amount: amount,
        memo: memo,
      );
    } catch (e) {
      print('Error sending loves: $e');
      return false;
    }
  }
}

// User state notifier - Fixed subscription type
class UserNotifier extends StateNotifier<User?> {
  final FlaskLedgerService _service;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  // Fix: Use correct type for auth subscription
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  UserNotifier(this._service) : super(null) {
    // Fix the subscription type
    _authSubscription = _auth.authStateChanges().listen((firebaseUser) {
      // Handle authentication state changes
      if (firebaseUser != null) {
        // User is signed in
        print('User signed in: ${firebaseUser.uid}');
        _fetchUserProfile();
      } else {
        // User is signed out
        print('User signed out');
        state = null;
      }
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = await _service.getCurrentUser();
      state = user;
    } catch (e) {
      print('Error fetching user profile: $e');
      state = null;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// --- RIVERPOD PROVIDERS ---

// Configuration provider - change this to your Flask backend URL
final flaskBaseUrlProvider = Provider<String>((ref) {
  // Replace with your actual Flask backend URL
  return 'http://your-flask-backend-url.com'; // e.g., 'https://api.yourapp.com'
});

final flaskServiceProvider = Provider<FlaskLedgerService>((ref) {
  final baseUrl = ref.watch(flaskBaseUrlProvider);
  return FlaskLedgerService(baseUrl: baseUrl);
});

final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  final service = ref.watch(flaskServiceProvider);
  return UserNotifier(service);
});

final ledgerProvider = StateNotifierProvider<LedgerNotifier, LedgerState>((ref) {
  final service = ref.watch(flaskServiceProvider);
  return LedgerNotifier(service);
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
  
  // Fix line 353 - Use correct type for auth subscription
  StreamSubscription<firebase_auth.User?>? _authSubscription;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scrollController.addListener(_onScroll);
    
    // Fix the subscription type
    _authSubscription = _auth.authStateChanges().listen((firebaseUser) {
      // Handle authentication state changes
      if (firebaseUser != null) {
        // User is signed in
        print('User signed in: ${firebaseUser.uid}');
        // Refresh ledger data or update UI
        _fetchInitialData();
      } else {
        // User is signed out
        print('User signed out');
        // Clear data or redirect to login
        // Optionally clear the ledger state
        if (mounted) {
          ref.read(ledgerProvider.notifier).state = LedgerState(publicLedgerEntries: []);
        }
      }
    });
    
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
    _authSubscription?.cancel();
    _listAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInitialData,
          ),
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
              child: // Fix line 956 - Use correct stream type
              StreamBuilder<firebase_auth.User?>(
                stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final authUser = snapshot.data;
                  if (authUser == null) {
                    return const Center(
                      child: Text(
                        'Please sign in to view the public ledger',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  
                  // User is authenticated, show ledger content
                  return _buildLedgerContent(ledgerState, currentUserWalletId);
                },
              ),
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

  // Separated ledger content builder for better organization
  Widget _buildLedgerContent(LedgerState ledgerState, String? currentUserWalletId) {
    if (ledgerState.isInitialLoading) {
      return _buildLoadingShimmer();
    }

    if (ledgerState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${ledgerState.errorMessage}',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (ledgerState.publicLedgerEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              ledgerState.currentSearchQuery.isNotEmpty
                  ? 'No results found for "${ledgerState.currentSearchQuery}".'
                  : 'No public ledger entries found.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final itemCount = ledgerState.publicLedgerEntries.length + 
        (ledgerState.isFetchingMore ? 1 : 0);

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
                try {
                  final success = await ref.read(ledgerProvider.notifier).sendLoves(
                    senderWallet: currentUserWalletId,
                    recipientWallet: recipientWalletId,
                    amount: amount,
                    memo: memo,
                  );
                  if (success) {
                    // Refresh the ledger after successful transaction
                    _fetchInitialData();
                  }
                  return success;
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                  return false;
                }
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
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending loves.')));
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
      home: const AuthWrapper(),
    );
  }
}

// Auth wrapper to handle Firebase Authentication state - Enhanced with proper error handling
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.deepPurple,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.amber),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.deepPurple,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Restart the app or navigate to sign in
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return const PublicLedgerPage();
        } else {
          return const SignInPage();
        }
      },
    );
  }
}

// Simple sign-in page for demonstration - Enhanced with better validation
class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      String message = 'Sign in failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your connection';
          break;
        default:
          message = e.message ?? 'An unknown error occurred';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Ledger',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email, color: Colors.white70),
                      errorStyle: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      errorStyle: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.amber.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      // Add sign up navigation or functionality here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign up functionality coming soon!')),
                      );
                    },
                    child: const Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      // Add forgot password functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Forgot password functionality coming soon!')),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.white54),
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
