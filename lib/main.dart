import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'models/user_account.dart';
import 'services/api_client.dart';
import 'state/user_provider.dart';
import 'state/proposal_provider.dart';
import 'state/goodwill_processing_provider.dart';
import 'pages/submit_goodwill_page.dart';
import 'pages/sign_in_page.dart';
import 'state/auth_provider.dart' as MyAppAuthProvider;

import 'firebase_options.dart';
import 'widgets/dynamic_nebula_background.dart';
import 'utils/app_constants.dart';
import 'widgets/navigation_card.dart';

enum SettingsAction { support, donate, docsCodebase, signOut }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized!');

  runApp(
    MultiProvider(
      providers: [
        Provider<PeoplesCoinApiClient>(
          create: (_) => PeoplesCoinApiClient(),
        ),
        ChangeNotifierProvider<MyAppAuthProvider.AuthProvider>(
          create: (context) => MyAppAuthProvider.AuthProvider(
            Provider.of<PeoplesCoinApiClient>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(
            Provider.of<PeoplesCoinApiClient>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<ProposalProvider>(
          create: (context) => ProposalProvider(
            Provider.of<PeoplesCoinApiClient>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<GoodwillProcessingProvider>(
          create: (context) => GoodwillProcessingProvider(
            Provider.of<PeoplesCoinApiClient>(context, listen: false),
          ),
        ),
      ],
      child: const BrightActsApp(),
    ),
  );
}

class BrightActsApp extends StatelessWidget {
  const BrightActsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrightActs',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white70),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.black.withOpacity(0.5),
          textStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      ),
      home: Consumer<MyAppAuthProvider.AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.user != null) {
            return const HomePage();
          } else {
            return const SignInPage();
          }
        },
      ),
      routes: {},
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  late PageController _pageController;
  late final List<Widget> _pages;

  bool _showMenuBars = true;
  bool _showCards = true;

  Future<void> _showSlidingFormOverlay(BuildContext context, Widget content) async {
    setState(() {
      _showMenuBars = false;
      _showCards = false;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, -1.0);
        const end = Offset.zero;
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: begin, end: end).animate(curve),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width > AppBreakpoints.tablet ? 0.4 : 0.9),
            height: MediaQuery.of(context).size.height * 0.85,
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppBar().preferredSize.height,
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25.0),
              child: content,
            ),
          ),
        );
      },
    );
    setState(() {
      _showMenuBars = true;
      _showCards = true;
    });
  }

  // NEW: Show settings dialog with transparent text fields
  void _showSettingsDialog() {
    final TextEditingController supportController = TextEditingController();
    final TextEditingController donateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Support',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: supportController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your support message',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.transparent,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Donate',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: donateController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter donation amount',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.transparent,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // You can add support/donate submit logic here
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[800],
                    ),
                    child: const Text('Submit'),
                  ),
                  const SizedBox(height: 30),
                  Divider(color: Colors.white.withOpacity(0.3)),
                  TextButton(
                    onPressed: () async {
                      const url = 'https://github.com/DonMichaelFeeney/Brightacts';
                      if (await url_launcher.canLaunchUrl(Uri.parse(url))) {
                        await url_launcher.launchUrl(Uri.parse(url));
                      }
                    },
                    child: const Text('Docs & Codebase', style: TextStyle(color: Colors.amber)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final authProvider = Provider.of<MyAppAuthProvider.AuthProvider>(context, listen: false);
                      await authProvider.signOut();
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out.')),
                        );
                      }
                    },
                    child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUser("some-user-id");
      Provider.of<ProposalProvider>(context, listen: false).fetchProposals(status: 'ACTIVE');
    });

    _pages = [
      NavigationCard(
        title: 'Governance',
        description: 'View active proposals, create new ones, and cast your votes.',
        icon: Icons.gavel,
        cardColor: const Color(0xFF8A2BE2),
        expandedContent: _cardContent(context, 'Governance Forms (Not implemented)'),
      ),
      NavigationCard(
        title: 'My Portfolio',
        description: 'Track your personal acts of goodwill and contributions.',
        icon: Icons.account_balance_wallet,
        cardColor: const Color(0xFFCC6699),
        expandedContent: _cardContent(context, 'Portfolio Forms (Not implemented)'),
      ),
      NavigationCard(
        title: 'Record Act',
        description: 'Share a new act of kindness or contribution and earn Loves.',
        icon: Icons.favorite,
        cardColor: const Color(0xFFDA70D6),
        expandedContent: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Log your positive actions to earn Loves in the BrightActs ecosystem.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 15),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _showSlidingFormOverlay(context, const SubmitGoodwillPage());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit a Bright Act', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      NavigationCard(
        title: 'Public Ledger',
        description: 'View all recorded acts of goodwill on the blockchain.',
        icon: Icons.public,
        cardColor: const Color(0xFF00BFFF),
        expandedContent: _cardContent(context, 'Public Ledger Forms (Not implemented)'),
      ),
      NavigationCard(
        title: 'My Wallet',
        description: 'Manage your Loves balance, send, and receive.',
        icon: Icons.wallet,
        cardColor: const Color(0xFF6A5ACD),
        expandedContent: _cardContent(context, 'Wallet Forms (Not implemented)'),
      ),
    ];
  }

  Widget _cardContent(BuildContext context, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed information about this section.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 15),
        Center(
          child: ElevatedButton(
            onPressed: () {
              _showSlidingFormOverlay(context, Center(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 20))));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[800],
              foregroundColor: Colors.white,
            ),
            child: const Text('Explore', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAppAuthProvider.AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < AppBreakpoints.tablet;
    final double verticalMargin = screenWidth >= AppBreakpoints.desktop ? 40.0 : 20.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: AppBar().preferredSize,
        child: AnimatedSlide(
          offset: _showMenuBars ? Offset.zero : const Offset(0, -1),
          duration: const Duration(milliseconds: 300),
          child: AppBar(
            title: const SizedBox.shrink(),
            actions: [
              // REPLACED PopupMenuButton with IconButton opening settings dialog
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showSettingsDialog,
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (userProvider.isLoading) {
                      return const CircularProgressIndicator(color: Colors.white);
                    } else if (userProvider.userAccount != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome, ${userProvider.userAccount!.username ?? 'User'}!',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                          Text('Your Balance: ${userProvider.userAccount!.balance.toStringAsFixed(2)} Loves',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                        ],
                      );
                    }
                    return const Text('Please log in.', style: TextStyle(color: Colors.white));
                  },
                ),
                SizedBox(height: verticalMargin),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showCards ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedSlide(
                      offset: _showCards ? Offset.zero : const Offset(0, -1),
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _pages.length,
                          itemBuilder: (context, index) => _pages[index],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: verticalMargin),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: _showMenuBars ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 300),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Governance'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Portfolio'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Share'),
            BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Ledger'),
            BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          unselectedItemColor: Colors.white70,
          onTap: _onItemTapped,
          backgroundColor: Colors.black.withOpacity(0.5),
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

