import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/dynamic_nebula_background.dart';
import 'package:brightacts_frontend_app/models/tech_system.dart';
import 'code_display_page.dart';

// --- DEFINED new brand color ---
const Color brandBlue = Color(0xFF0A2540); // A deep, professional dark blue
const Color cardBackground = Color(0xFFF6F9FC); // A very light, clean background for cards

// Data list for backend systems.
final List<TechSystem> backendSystems = [
  const TechSystem(
    icon: Icons.cloud_queue,
    title: 'Cloud Infrastructure',
    description: 'Manages scalable cloud resources and services.',
    color: Colors.blueAccent,
    code: '''...''' // Code omitted for brevity
  ),
  // Add other TechSystem objects here...
];

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _showCodeViewer(BuildContext context, TechSystem system) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.5),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: CodeDisplayPage(title: 'Code Viewer', system: system),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using a solid color for the page background to ensure text readability
    return Scaffold(
      backgroundColor: cardBackground,
      body: Stack(
        children: [
          const DynamicNebulaBackground(), // Still here for a dynamic feel underneath
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 36),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildMissionStatement(),
                  ),
                  const SizedBox(height: 36),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildActionButtons(context),
                  ),
                  const SizedBox(height: 72),
                  _buildTechShowcase(context),
                  const SizedBox(height: 16),
                  _buildHintText(),
                  const SizedBox(height: 48),
                  _buildFooterLinks(context),
                ],
              ).animate().fadeIn(duration: 500.ms, curve: Curves.easeIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Welcome to Bright Acts',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        // CHANGED: Text color to brandBlue
        color: brandBlue,
        letterSpacing: 1.4,
      ),
    ).animate().fade(duration: 900.ms).slideY(begin: 0.5, curve: Curves.easeOutCubic);
  }

  // --- REDESIGNED: Mission statement card for better contrast ---
  Widget _buildMissionStatement() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white, // Solid white for max contrast
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Goal: A Decentralized Community for Good.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: brandBlue,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Bright Acts is a Web3 platform built on the principles of transparency, community ownership, and rewarding positive impact. Every act of goodwill is recorded on a public ledger, and our governance is shaped by the community through proposals and voting.',
            style: TextStyle(
              color: brandBlue,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms, duration: 900.ms).slideY(begin: 0.4, curve: Curves.easeOutCubic);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnimatedScaleButton(
          onTap: () => context.go('/sign_up'),
          backgroundColor: Colors.amber[800]!,
          foregroundColor: Colors.black,
          text: 'Join the Community',
        ),
        const SizedBox(height: 14),
        _AnimatedScaleButton(
          onTap: () => context.go('/sign_in'),
          backgroundColor: Colors.transparent,
          // CHANGED: Button text color to brandBlue
          foregroundColor: brandBlue,
          borderColor: brandBlue,
          isOutlined: true,
          text: 'Sign In',
        ),
      ],
    ).animate().fade(delay: 400.ms, duration: 900.ms).slideY(begin: 0.3, curve: Curves.easeOutCubic);
  }

  Widget _buildTechShowcase(BuildContext context) {
    return Column(
      children: [
        const Text(
          'A Living Ecosystem',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: brandBlue,
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Tap a system to view its backend code and architecture.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: brandBlue,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: backendSystems.length,
            itemBuilder: (context, index) {
              return _TechSystemCard(
                system: backendSystems[index],
                onTap: () => _showCodeViewer(context, backendSystems[index]),
              ).animate().fade(delay: (200 * index).ms, duration: 600.ms).slideX(begin: 0.5);
            },
          ),
        ),
      ],
    ).animate().fade(delay: 600.ms, duration: 900.ms);
  }

  Widget _buildHintText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Explore the core backend systems and see how Bright Acts works behind the scenes.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: brandBlue,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterLink(
          url: 'https://github.com/DonMichaelFeeney/Brightacts',
          text: 'View Full Codebase',
        ),
        const Text(' | ', style: TextStyle(color: brandBlue)),
        _FooterLink(
          url: 'https://www.linkedin.com/company/the-people-s-coin/',
          text: 'Follow Us',
        ),
      ],
    );
  }
}

// --- REDESIGNED: Tech card for better contrast and a cleaner look ---
class _TechSystemCard extends StatefulWidget {
  final TechSystem system;
  final VoidCallback onTap;

  const _TechSystemCard({required this.system, required this.onTap});

  @override
  State<_TechSystemCard> createState() => _TechSystemCardState();
}

class _TechSystemCardState extends State<_TechSystemCard> {
  bool _isHoveredOrTapped = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.system.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveredOrTapped = true),
      onExit: (_) => setState(() => _isHoveredOrTapped = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHoveredOrTapped = true),
        onTapUp: (_) => setState(() => _isHoveredOrTapped = false),
        onTapCancel: () => setState(() => _isHoveredOrTapped = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 210,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHoveredOrTapped ? color : Colors.grey.shade300,
              width: _isHoveredOrTapped ? 2 : 1,
            ),
            boxShadow: _isHoveredOrTapped
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: brandBlue.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(widget.system.icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                widget.system.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: brandBlue, // CHANGED to dark blue
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.system.description,
                style: TextStyle(
                  color: brandBlue.withOpacity(0.7), // CHANGED
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String url;
  final String text;

  const _FooterLink({required this.url, required this.text});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovering = false;

  Future<void> _launch() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: TextButton(
        onPressed: _launch,
        style: TextButton.styleFrom(
          // CHANGED: Colors for dark blue text
          foregroundColor: _hovering ? Colors.amber[800] : brandBlue,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        child: Text(widget.text),
      ),
    );
  }
}


// --- This button widget remains unchanged but is included for completeness ---
class _AnimatedScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isOutlined;
  final String text;

  const _AnimatedScaleButton({
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.isOutlined = false,
    required this.text,
  });

  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
      value: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onTapDown(TapDownDetails _) => _controller.reverse(from: 1.0);
  void _onTapUp(TapUpDetails _) => _controller.forward(from: 0.0);
  void _onTapCancel() => _controller.forward(from: 0.0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = widget.isOutlined
        ? OutlinedButton.styleFrom(
            side: BorderSide(
                color: widget.borderColor ?? widget.foregroundColor, width: 2),
            foregroundColor: widget.foregroundColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shadowColor: Colors.black45,
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: widget.isOutlined
            ? OutlinedButton(
                onPressed: widget.onTap,
                style: buttonStyle,
                child: Text(widget.text),
              )
            : ElevatedButton(
                onPressed: widget.onTap,
                style: buttonStyle,
                child: Text(widget.text),
              ),
      ),
    );
  }
}
