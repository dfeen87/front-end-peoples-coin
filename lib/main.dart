// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

// Import your files
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


// --- MAIN ENTRY POINT ---

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ENHANCEMENT: Load environment variables at startup
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ENHANCEMENT: Get reCAPTCHA key from .env instead of hardcoding
  final reCaptchaKey = dotenv.env['RECAPTCHA_SITE_KEY'] ?? 'YOUR_FALLBACK_KEY_HERE';

  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider(reCaptchaKey),
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest,
  );

  runApp(
    MultiProvider(
      providers: [
        // 1. Provide the main API client
        Provider<PeoplesCoinApiClient>(
          create: (_) => PeoplesCoinApiClient(),
        ),
        // ENHANCEMENT: Use ProxyProvider to simplify dependency injection.
        // These providers now automatically receive the PeoplesCoinApiClient.
        ChangeNotifierProxyProvider<PeoplesCoinApiClient, MyAppAuthProvider.AuthProvider>(
          create: (context) => MyAppAuthProvider.AuthProvider(context.read<PeoplesCoinApiClient>()),
          update: (context, apiClient, previous) => MyAppAuthProvider.AuthProvider(apiClient),
        ),
        ChangeNotifierProxyProvider<PeoplesCoinApiClient, UserProvider>(
          create: (context) => UserProvider(context.read<PeoplesCoinApiClient>()),
          update: (context, apiClient, previous) => UserProvider(apiClient),
        ),
        ChangeNotifierProxyProvider<PeoplesCoinApiClient, ProposalProvider>(
          create: (context) => ProposalProvider(context.read<PeoplesCoinApiClient>()),
          update: (context, apiClient, previous) => ProposalProvider(apiClient),
        ),
        ChangeNotifierProxyProvider<PeoplesCoinApiClient, GoodwillProcessingProvider>(
          create: (context) => GoodwillProcessingProvider(context.read<PeoplesCoinApiClient>()),
          update: (context, apiClient, previous) => GoodwillProcessingProvider(apiClient),
        ),
        ChangeNotifierProxyProvider<PeoplesCoinApiClient, LedgerProvider>(
          create: (context) => LedgerProvider(context.read<PeoplesCoinApiClient>()),
          update: (context, apiClient, previous) => LedgerProvider(apiClient),
        ),
      ],
      child: const BrightActsApp(),
    ),
  );
}


// --- ROOT APP WIDGET ---

class BrightActsApp extends StatelessWidget {
  const BrightActsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Setting system UI overlay for a more immersive feel
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black.withOpacity(0.5),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'BrightActs',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(), // ENHANCEMENT: Extracted theme to a separate function
      // ENHANCEMENT: Start with LandingGate to handle auth state automatically
      home: const LandingGate(),
      routes: {
        '/sign_up': (context) => const SignUpScreen(),
        '/sign_in': (context) => const SignInScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}


// --- AUTHENTICATION GATE ---

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
          return const DevAccessScreen(); // Or SignUpScreen() for production
        }

        // ENHANCEMENT: Fetch user data immediately after login, before showing HomePage
        context.read<UserProvider>().fetchUser(authProvider.user!.uid);
        return const HomePage();
      },
    );
  }
}


// --- HOME PAGE WIDGET ---

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; // Start on 'Record Act'
  late final PageController _pageController;
  late final List<Widget> _pages;

  bool _showUiElements = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);

    // ENHANCEMENT: Build pages list directly. No need for addPostFrameCallback here.
    _pages = _buildPages();
  }
  
  // ENHANCEMENT: Extracted page creation to a separate method for cleanliness.
  List<Widget> _buildPages() {
    return [
      _buildNavigationPage(
        title: 'Governance',
        description: 'View active proposals, create new ones, and cast your votes.',
        icon: Icons.gavel,
        cardColor: AppColors.governance,
        buttonText: "View Proposals",
        pageToOpen: const GovernancePage(),
      ),
      _buildNavigationPage(
        title: 'My Portfolio',
        description: 'Track your personal acts of goodwill and contributions.',
        icon: Icons.account_balance_wallet,
        cardColor: AppColors.portfolio,
        buttonText: "View My Acts",
        pageToOpen: const MyPortfolioPage(),
      ),
      _buildNavigationPage(
        title: 'Record Act',
        description: 'Share a new act of kindness or contribution and earn Loves.',
        icon: Icons.favorite,
        cardColor: AppColors.recordAct,
        buttonText: "Submit a Bright Act",
        pageToOpen: const SubmitGoodwillPage(),
      ),
      _buildNavigationPage(
        title: 'Public Ledger',
        description: 'View all recorded acts of goodwill on the blockchain.',
        icon: Icons.public,
        cardColor: AppColors.ledger,
        buttonText: "View Ledger",
        pageToOpen: const PublicLedgerPage(),
      ),
      _buildNavigationPage(
        title: 'My Wallet',
        description: 'Manage your Loves balance, send, and receive.',
        icon: Icons.wallet,
        cardColor: AppColors.wallet,
        buttonText: "Open Wallet",
        pageToOpen: const MyWalletPage(),
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper method to reduce repetition in page building
  Widget _buildNavigationPage({
    required String title,
    required String description,
    required IconData icon,
    required Color cardColor,
    required String buttonText,
    required Widget pageToOpen,
  }) {
    return NavigationCard(
      title: title,
      description: description,
      icon: icon,
      cardColor: cardColor,
      expandedContent: _cardContent(context, buttonText, pageToOpen: pageToOpen),
    );
  }

  Future<void> _showSlidingFormOverlay(BuildContext context, Widget content) async {
    setState(() => _showUiElements = false);
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
        final mediaQuery = MediaQuery.of(context);
        final isDesktop = mediaQuery.size.width >= AppBreakpoints.desktop;
        return Align(
          alignment: Alignment.center,
          child: Container(
            width: mediaQuery.size.width * (isDesktop ? 0.4 : 0.9),
            height: mediaQuery.size.height * 0.85,
            margin: EdgeInsets.only(
              top: mediaQuery.padding.top + (AppBar().preferredSize.height / 2),
              bottom: mediaQuery.padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25.0),
              child: content,
            ),
          ),
        );
      },
    );

    setState(() => _showUiElements = true);
  }
  
  Widget _cardContent(BuildContext context, String buttonText, {required Widget pageToOpen}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed information about this section.', // Placeholder text
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Center(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSlidingFormOverlay(context, pageToOpen);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(index, duration: AppDurations.fast, curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final verticalMargin = screenWidth >= AppBreakpoints.desktop ? 40.0 : 20.0;

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
                  offset: _showUiElements ? Offset.zero : const Offset(0, -1.5),
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
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedSlide(
        offset: _showUiElements ? Offset.zero : const Offset(0, -1.5),
        duration: AppDurations.fast,
        child: AppBar(
          title: const SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
      opacity: _showUiElements ? 1 : 0,
      duration: AppDurations.fast,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          itemBuilder: (context, index) => _pages[index],
          onPageChanged: (index) {
            if (_selectedIndex != index) {
              HapticFeedback.selectionClick();
              setState(() => _selectedIndex = index);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return AnimatedSlide(
      offset: _showUiElements ? Offset.zero : const Offset(0, 2),
      duration: AppDurations.fast,
      child: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Governance'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Record'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Ledger'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.buttonPrimary,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
        backgroundColor: Colors.black.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
        showSelectedLabels: true,
      ),
    );
  }
}


// --- SETTINGS DIALOG WIDGET ---

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
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
                  // Implement support action, e.g., launching mailto link
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
                  // Pop dialog first, then sign out to avoid context issues
                  Navigator.of(context).pop();
                  await context.read<MyAppAuthProvider.AuthProvider>().signOut();
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
      onPressed: onPressed ?? () async {
        if (url != null) {
          final uri = Uri.parse(url);
          // ENHANCEMENT: Removed deprecated `canLaunchUrl`
          try {
            await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
          } catch (e) {
            // Optional: Show a snackbar or dialog if launching fails
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not launch $url')),
            );
          }
        }
      },
    );
  }
}

// --- HELPER: App Theme ---
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
  );
}

// NOTE: Consider moving these constants to `utils/app_constants.dart`
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

class AppBreakpoints {
  static const double tablet = 768;
  static const double desktop = 1200;
}
