import 'dart:async';
import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Primary App Check import
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform; // defaultTargetPlatform imported here

// Import your project-specific files
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
import 'screens/welcome_screen.dart';
import 'package:brightacts_frontend_app/models/tech_system.dart';
import 'screens/code_display_page.dart';

import 'screens/sign_up_screen.dart' as sign_up;
import 'screens/sign_in_screen.dart' as sign_in;

import 'pages/dev_access_screen.dart';

import 'state/auth_provider.dart' as MyAppAuthProvider;
import 'firebase_options.dart';
import 'widgets/dynamic_nebula_background.dart';
import 'utils/app_constants.dart';
import 'widgets/navigation_card.dart';
import 'widgets/matrix_text.dart';
import 'widgets/animated_digit_widget.dart';

// --- Global Constants & Definitions ---

const String recaptchaSiteKeyProd = '6LcwyYUrAAAAAE2Bv6bXHjq23zTBE49ABYmi4ccs';

// Define the reCAPTCHA site key for PRODUCTION web builds
// This value MUST be passed using --dart-define=RECAPTCHA_SITE_KEY_PROD=YOUR_SITE_KEY during flutter build web --release
const String _reCaptchaSiteKeyProd = String.fromEnvironment(
  'RECAPTCHA_SITE_KEY_PROD', // This is the variable name that --dart-define will set
  defaultValue: '', // Default to empty string if not provided (e.g., in debug mode)
);

// --- MAIN ENTRY POINT ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: ".env"); // Load .env for other local env vars

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- Firebase App Check Activation ---
  // Activate App Check with different providers based on platform and build mode
  await FirebaseAppCheck.instance.activate(
    // Web Provider: Debug for local development, reCAPTCHA v3 for production
    webProvider: ReCaptchaV3Provider('6LcwyYUrAAAAAE2Bv6bXHjq23zTBE49ABYmi4ccsd'), // For flutter build web --release
  );

  // Consolidated print statements for App Check activation status
  if (kIsWeb && kDebugMode) {
    print('[App Check] Using DebugProvider for Web (Debug Mode).');
    // For DebugAppCheckProvider, we can directly get the token
    FirebaseAppCheck.instance.getToken(true).then((String? token) {
      if (token != null && token.isNotEmpty) {
        print('------------------------------------------------------------');
        print('App Check Debug Token: $token');
        print('-> Register this token in Firebase Console -> App Check -> Apps -> Your Web App -> Debug tokens.');
        print('------------------------------------------------------------');
      }
    });
  } else if (!kIsWeb) {
    // For Android/iOS, defaultTargetPlatform is available via flutter/foundation.dart
    print('[App Check] Activated for ${defaultTargetPlatform.name} (DebugMode: $kDebugMode).');
  } else if (kIsWeb && !kDebugMode) { // Web Release Mode
     if (_reCaptchaSiteKeyProd.isEmpty) {
        print('[App Check] CRITICAL: RECAPTCHA_SITE_KEY_PROD was NOT defined during build. App Check will NOT activate!');
      } else {
        print('[App Check] Activated for Web (Release Mode) using injected reCAPTCHA key.');
      }
  }

  final apiClient = PeoplesCoinApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<PeoplesCoinApiClient>.value(value: apiClient),
        ChangeNotifierProvider(create: (context) => MyAppAuthProvider.AuthProvider(context.read<PeoplesCoinApiClient>())),
        ChangeNotifierProvider(create: (context) => UserProvider(context.read<PeoplesCoinApiClient>())),
        ChangeNotifierProvider(create: (context) => ProposalProvider(context.read<PeoplesCoinApiClient>())),
        ChangeNotifierProvider(create: (context) => GoodwillProcessingProvider(context.read<PeoplesCoinApiClient>())),
        ChangeNotifierProvider(create: (context) => LedgerProvider(context.read<PeoplesCoinApiClient>())),
      ],
      child: const BrightActsApp(),
    ),
  );
}

// --- Theme Definition ---
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.deepPurple,
    brightness: Brightness.light,
    fontFamily: 'Roboto',
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Roboto',
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

// --- ROUTER CONFIGURATION ---
final _router = GoRouter(
  initialLocation: '/dev-sign-in',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AppStartupController()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/sign_in', builder: (context, state) => const sign_in.SignInScreen()),
    GoRoute(path: '/sign_up', builder: (context, state) => const sign_up.SignUpScreen()),
    GoRoute(path: '/dev-sign-in', builder: (context, state) => const DevAccessScreen()),
    GoRoute(
      path: '/code-viewer',
      builder: (context, state) {
        final system = state.extra as TechSystem?;
        if (system != null) {
          return CodeDisplayPage(title: 'Code Viewer', system: system);
        }
        return const Scaffold(body: Center(child: Text('Error: No system data provided.')));
      },
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      ],
    ),
  ],
);

// --- APP SHELL, ROOT APP, and STARTUP CONTROLLER WIDGETS ---
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: DynamicNebulaBackground()),
        child,
      ],
    );
  }
}

class BrightActsApp extends StatelessWidget {
  const BrightActsApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black.withOpacity(0.5),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    return MaterialApp.router(
      title: 'BrightActs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}

class AppStartupController extends StatefulWidget {
  const AppStartupController({super.key});
  @override
  State<AppStartupController> createState() => _AppStartupControllerState();
}

class _AppStartupControllerState extends State<AppStartupController> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await WidgetsBinding.instance.endOfFrame;
    final authProvider = Provider.of<MyAppAuthProvider.AuthProvider>(context, listen: false);
    await authProvider.checkCurrentUser();
    if (mounted) {
      if (authProvider.user == null) {
        context.go('/welcome');
      } else {
        context.read<UserProvider>().fetchUser(authProvider.user!.uid);
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
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
  int _selectedIndex = 2;
  late final PageController _pageController;
  late final List<Widget> _pages;
  bool _showUiElements = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _pages = _buildPages();
  }

  List<Widget> _buildPages() {
    return [
      _buildNavigationPage(
        title: 'Governance',
        description: 'Influence the future of the platform. View active proposals, create new ones, and cast your votes on community-led initiatives.',
        icon: Icons.gavel,
        cardColor: AppColors.governance,
        buttonText: "View Proposals",
        pageToOpen: const GovernancePage(),
      ),
      _buildNavigationPage(
        title: 'My Portfolio',
        description: 'Review your personal history of contributions, track your impact, and see how your acts have strengthened the community.',
        icon: Icons.account_balance_wallet,
        cardColor: AppColors.portfolio,
        buttonText: "View My Acts",
        pageToOpen: const MyPortfolioPage(),
      ),
      _buildNavigationPage(
        title: 'Record Act',
        description: 'Document a new act of kindness or contribution. Each verified act is rewarded with \'Loves\' and permanently added to the ledger.',
        icon: Icons.favorite,
        cardColor: AppColors.recordAct,
        buttonText: "Submit a Bright Act",
        pageToOpen: const SubmitGoodwillPage(),
      ),
      _buildNavigationPage(
        title: 'Public Ledger',
        description: 'Explore the transparent and immutable record of every act of goodwill submitted by the community. A testament to our collective impact.',
        icon: Icons.public,
        cardColor: AppColors.ledger,
        buttonText: "View Ledger",
        pageToOpen: const PublicLedgerPage(),
      ),
      _buildNavigationPage(
        title: 'My Wallet',
        description: 'Securely manage your \'Loves\' balance, view transaction history, and send tokens to other members of the community.',
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

  Widget _buildNavigationPage({required String title, required String description, required IconData icon, required Color cardColor, required String buttonText, required Widget pageToOpen}) {
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
            margin: EdgeInsets.only(top: mediaQuery.padding.top + (AppBar().preferredSize.height / 2), bottom: mediaQuery.padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(25.0), child: content),
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
        const Text('Detailed information about this section.', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildAppBar(context),
      body: SafeArea(
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
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const SettingsBottomSheet(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Selector<UserProvider, ({bool isLoading, bool hasError, UserAccount? userAccount})>(
      selector: (_, provider) => (isLoading: provider.isLoading, hasError: provider.hasError, userAccount: provider.currentUser),
      builder: (context, data, _) {
        if (data.hasError) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('// CONNECTION INTERRUPTED', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontFamily: 'monospace')),
              Text('  Could not load user data.', style: TextStyle(color: Colors.white70)),
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
                Text('Your Balance: ', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                if (data.isLoading)
                  Text("******", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                if (!data.isLoading && data.userAccount != null)
                  AnimatedDigitWidget(
                    value: data.userAccount!.balance,
                    textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: Colors.white),
                  ),
                Text(' Loves', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
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

// --- SettingsBottomSheet ---
class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  void _launchSupportEmail(BuildContext context) async {
    const String businessEmail = 'support@brightacts.com';
    const String subject = 'Bright Acts Support Request';
    const String body = '''
      Please describe your issue or question in detail below.
      
      --------------------
      App Version: 1.0.0
      Platform: Web
      User ID: [Please leave this for faster support]
      --------------------

      My issue is:
    ''';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: businessEmail,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      await url_launcher.launchUrl(emailLaunchUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email app. Please contact support@brightacts.com directly.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 20),
            const Text('Settings & Info', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            _buildLinkButton(
              context: context,
              text: 'Donate to Bright Acts',
              icon: Icons.volunteer_activism,
              color: Colors.pinkAccent,
              url: 'https://buy.stripe.com/4gM3cv65RfBnbOue7i24000',
            ),
            const SizedBox(height: 10),

            _buildLinkButton(
              context: context,
              text: 'Change Background',
              icon: Icons.wallpaper,
              onPressed: null,
            ),
            const SizedBox(height: 10),

            _buildLinkButton(
              context: context,
              text: 'Follow on LinkedIn',
              icon: Icons.group_work,
              color: Colors.lightBlueAccent,
              url: 'https://www.linkedin.com/company/the-people-s-coin/',
            ),
            const SizedBox(height: 10),

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
              onPressed: () => _launchSupportEmail(context),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              onPressed: () async {
                HapticFeedback.heavyImpact();
                Navigator.of(context).pop();
                await context.read<MyAppAuthProvider.AuthProvider>().signOut();
                if (context.mounted) {
                  context.go('/welcome');
                }
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkButton({required BuildContext context, required String text, required IconData icon, Color? color, String? url, VoidCallback? onPressed}) {
    final bool isEnabled = onPressed != null || url != null;
    final Color enabledColor = color ?? Colors.amber[700]!;
    final Color disabledColor = Colors.grey[600]!;

    return TextButton.icon(
      icon: Icon(icon, color: isEnabled ? enabledColor : disabledColor),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(color: isEnabled ? Colors.white : Colors.grey[600], fontSize: 16),
          ),
          if (!isEnabled)
            const Text(' (Coming Soon)', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
      onPressed: isEnabled ? (onPressed ?? () async {
        if (url != null) {
          final uri = Uri.parse(url);
          try {
            await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not launch $url')),
              );
            }
          }
        }
      }) : null,
    );
  }
}

// --- HELPER CONSTANTS ---
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
