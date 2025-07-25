// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

// Import your files - adjust these paths as needed
import 'models/user_account.dart';
import 'service/api_client.dart';
import 'state/user_provider.dart';
import 'state/proposal_provider.dart';
import 'state/goodwill_processing_provider.dart';
import 'state/ledger_provider.dart';
import 'pages/submit_goodwill_page.dart';
import 'pages/my_portfolio_page.dart';
import 'pages/governance_page.dart';
import 'pages/my_wallet_page.dart';
import 'pages/public_ledger_page.dart';
import 'screens/dev_access_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/sign_in_screen.dart';
import 'state/auth_provider.dart' as MyAppAuthProvider;
import 'firebase_options.dart';
import 'widgets/dynamic_nebula_background.dart';
import 'utils/app_constants.dart';
import 'widgets/navigation_card.dart';
import 'widgets/matrix_text.dart';
import 'widgets/animated_digit_widget.dart';

class AppDurations {
  static const fast = Duration(milliseconds: 300);
  static const medium = Duration(milliseconds: 400);
}

class AppColors {
  static const governance = Color(0xFF8A2BE2);
  static const portfolio = Color(0xFFCC6699);
  static const recordAct = Color(0xFFDA70D6);
  static const ledger = Color(0xFF00BFFF);
  static const wallet = Color(0xFF6A5ACD);
  static final buttonPrimary = Colors.amber[800];
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('6LcwyYUrAAAAAE2Bv6bXHjq23zTBE49ABYmi4ccs'),
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

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
        ChangeNotifierProvider<LedgerProvider>(
          create: (context) => LedgerProvider(
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
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

      // Entry point widget that decides routing based on auth state
      home: const DevAccessScreen(),

      // Named routes for navigation
      routes: {
        '/sign_up': (context) => const SignUpScreen(),
        '/sign_in': (context) => const SignInScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

/// LandingGate widget listens to auth state and routes accordingly
class LandingGate extends StatelessWidget {
  const LandingGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppAuthProvider.AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.user == null) {
          // No user signed in - show SignUp screen first
          return const SignUpScreen();
        }

        // User signed in - go to main HomePage
        return const HomePage();
      },
    );
  }
}

// --- Your HomePage with cards and bottom nav ---

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

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _selectedIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<MyAppAuthProvider.AuthProvider>();
      final String? userId = authProvider.user?.uid;
      if (userId != null) {
        context.read<UserProvider>().fetchUser(userId);
      }
    });

    _pages = [
      NavigationCard(
        title: 'Governance',
        description: 'View active proposals, create new ones, and cast your votes.',
        icon: Icons.gavel,
        cardColor: AppColors.governance,
        expandedContent: _cardContent(
          context,
          "View Proposals",
          pageToOpen: const GovernancePage(),
        ),
      ),
      NavigationCard(
        title: 'My Portfolio',
        description: 'Track your personal acts of goodwill and contributions.',
        icon: Icons.account_balance_wallet,
        cardColor: AppColors.portfolio,
        expandedContent: _cardContent(
          context,
          "View My Acts",
          pageToOpen: const MyPortfolioPage(),
        ),
      ),
      NavigationCard(
        title: 'Record Act',
        description: 'Share a new act of kindness or contribution and earn Loves.',
        icon: Icons.favorite,
        cardColor: AppColors.recordAct,
        expandedContent: _cardContent(
          context,
          "Submit a Bright Act",
          pageToOpen: const SubmitGoodwillPage(),
        ),
      ),
      NavigationCard(
        title: 'Public Ledger',
        description: 'View all recorded acts of goodwill on the blockchain.',
        icon: Icons.public,
        cardColor: AppColors.ledger,
        expandedContent: _cardContent(
          context,
          "View Ledger",
          pageToOpen: const PublicLedgerPage(),
        ),
      ),
      NavigationCard(
        title: 'My Wallet',
        description: 'Manage your Loves balance, send, and receive.',
        icon: Icons.wallet,
        cardColor: AppColors.wallet,
        expandedContent: _cardContent(
          context,
          "Open Wallet",
          pageToOpen: const MyWalletPage(),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showSlidingFormOverlay(BuildContext context, Widget content) async {
    setState(() {
      _showMenuBars = false;
      _showCards = false;
    });
    await Future.delayed(AppDurations.fast);
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: AppDurations.medium,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero).animate(curve),
          child: FadeTransition(opacity: animation, child: child),
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
              border: Border.all(color: Colors.white.withOpacity(0.3)),
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

  Widget _cardContent(BuildContext context, String buttonText, {Widget? pageToOpen}) {
    final Widget contentToShow = pageToOpen ??
        Center(
            child: Text(buttonText,
                style: const TextStyle(color: Colors.white, fontSize: 20)));

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
              HapticFeedback.lightImpact();
              _showSlidingFormOverlay(context, contentToShow);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(index, duration: AppDurations.fast, curve: Curves.ease);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double verticalMargin = screenWidth >= AppBreakpoints.desktop ? 40.0 : 20.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSlide(
                  offset: _showMenuBars ? Offset.zero : const Offset(0, -1),
                  duration: AppDurations.fast,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildWelcomeHeader(),
                  ),
                ),
                SizedBox(height: verticalMargin),
                Expanded(child: _buildPageView()),
                SizedBox(height: verticalMargin),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: AppBar().preferredSize,
      child: AnimatedSlide(
        offset: _showMenuBars ? Offset.zero : const Offset(0, -1),
        duration: AppDurations.fast,
        child: AppBar(
          title: const SizedBox.shrink(),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(0),
            child: SizedBox.shrink(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                HapticFeedback.mediumImpact();
                showDialog(context: context, builder: (_) => const SettingsDialog());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Selector<UserProvider,
        ({bool isLoading, bool hasError, UserAccount? userAccount})>(
      selector: (_, provider) => (
        isLoading: provider.isLoading,
        hasError: provider.hasError,
        userAccount: provider.userAccount
      ),
      builder: (context, data, _) {
        if (data.hasError) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('// CONNECTION INTERRUPTED',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 24,
                      fontFamily: 'monospace')),
              Text('  Could not load user data.',
                  style: TextStyle(color: Colors.white70)),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MatrixText(
              targetText: 'Welcome, ${data.userAccount?.username ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24, fontFamily: 'monospace'),
              isLoading: data.isLoading,
              speed: const Duration(milliseconds: 182),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Your Balance: ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                if (data.isLoading)
                  Text("******", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                if (!data.isLoading && data.userAccount != null)
                  AnimatedDigitWidget(
                    value: data.userAccount!.balance,
                    textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: Colors.white),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOut,
                    fractionDigits: 2,
                  ),
                Text(' Loves',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPageView() {
    return AnimatedOpacity(
      opacity: _showCards ? 1 : 0,
      duration: AppDurations.fast,
      child: AnimatedSlide(
        offset: _showCards ? Offset.zero : const Offset(0, -1),
        duration: AppDurations.fast,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            itemBuilder: (context, index) => _pages[index],
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _selectedIndex = index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return AnimatedSlide(
      offset: _showMenuBars ? Offset.zero : const Offset(0, 1),
      duration: AppDurations.fast,
      child: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Governance'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Share'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Ledger'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.buttonPrimary,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
        backgroundColor: Colors.black.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Settings & Info',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildLinkButton(
                context: context,
                text: 'Docs & Codebase',
                icon: Icons.code,
                url: 'https://github.com/DonMichaelFeeney/Brightacts',
              ),
              const SizedBox(height: 10),
              _buildLinkButton(
                context: context,
                text: 'Get Support',
                icon: Icons.support_agent,
                onPressed: () {
                  // Implement support action
                },
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                onPressed: () async {
                  HapticFeedback.heavyImpact();
                  final authProvider = context.read<MyAppAuthProvider.AuthProvider>();
                  await authProvider.signOut();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    String? url,
    VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      icon: Icon(icon, color: Colors.amber[700]),
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onPressed: onPressed ??
          () async {
            if (url != null) {
              final uri = Uri.parse(url);
              if (await url_launcher.canLaunchUrl(uri)) {
                await url_launcher.launchUrl(uri);
              }
            }
          },
    );
  }
}

