import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/dynamic_nebula_background.dart';
import 'package:brightacts_frontend_app/models/tech_system.dart'; // Import TechSystem from its central location
import 'code_display_page.dart'; // CodeDisplayPage now expects TechSystem directly

// Data list for backend systems. Consider moving this to a separate data file for better organization.
final List<TechSystem> backendSystems = [
  const TechSystem(
    icon: Icons.cloud_queue,
    title: 'Cloud Infrastructure',
    description: 'Manages scalable cloud resources and services.',
    color: Colors.blueAccent,
    code: '''
# Example Python code for Cloud Infrastructure
class CloudManager:
    def __init__(self, provider='AWS'):
        self.provider = provider
        print(f"Initializing {self.provider} Cloud Manager...")

    def deploy_service(self, service_name, config):
        """Deploys a new service with given configuration."""
        print(f"Deploying {service_name} with config: {config}")
        return {"status": "success", "service_id": f"svc-{hash(service_name)}"}

# ... other systems ...
'''
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
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: CodeDisplayPage(
              title: 'Code Viewer',
              system: system,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
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
              ),
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
        color: Colors.white,
        letterSpacing: 1.4,
        shadows: [
          Shadow(
            offset: Offset(0, 2),
            blurRadius: 8,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionStatement() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Our Goal: A Decentralized Community for Good.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Bright Acts is a Web3 platform built on the principles of transparency, community ownership, and rewarding positive impact. Every act of goodwill is recorded on a public ledger, and our governance is shaped by the community through proposals and voting.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Together, we empower individuals to create lasting change by recognizing and amplifying kindness.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          foregroundColor: Colors.amber[800]!,
          borderColor: Colors.amber[800]!,
          isOutlined: true,
          text: 'Sign In',
        ),
      ],
    );
  }

  Widget _buildTechShowcase(BuildContext context) {
    return Column(
      children: [
        const Text(
          'A Living Ecosystem',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 5,
                color: Colors.black38,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Tap a system to view its backend code and architecture.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHintText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Explore the core backend systems and see how Bright Acts works behind the scenes.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white54,
          fontSize: 13,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.2,
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
        const Text(' | ', style: TextStyle(color: Colors.white24)),
        _FooterLink(
          url: 'https://www.linkedin.com/company/the-people-s-coin/',
          text: 'Follow Us',
        ),
      ],
    );
  }
}

class _TechSystemCard extends StatefulWidget {
  final TechSystem system;
  final VoidCallback onTap;

  const _TechSystemCard({required this.system, required this.onTap});

  @override
  State<_TechSystemCard> createState() => _TechSystemCardState();
}

class _TechSystemCardState extends State<_TechSystemCard> {
  bool _isHoveredOrTapped = false;

  void _setHover(bool hovered) {
    setState(() {
      _isHoveredOrTapped = hovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.system.color;
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTapDown: (_) => _setHover(true),
        onTapUp: (_) => _setHover(false),
        onTapCancel: () => _setHover(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 210,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: color.withOpacity(_isHoveredOrTapped ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withOpacity(_isHoveredOrTapped ? 0.5 : 0.3),
              width: _isHoveredOrTapped ? 2 : 1,
            ),
            boxShadow: _isHoveredOrTapped
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.25),
                child: Icon(widget.system.icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                widget.system.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.system.description,
                style: const TextStyle(
                  color: Colors.white70,
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
          foregroundColor: _hovering ? Colors.amber[400] : Colors.white70,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        child: Text(widget.text),
      ),
    );
  }
}

// -------------------------------------------------------------------
// -- FIXED WIDGET: _AnimatedScaleButton
// -------------------------------------------------------------------

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
      value: 1.0, // Start at full scale
    );
    // Use a CurveTween for a nicer bounce effect
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onTapDown(TapDownDetails _) {
    _controller.reverse(from: 1.0); // Animate to smaller scale
  }

  void _onTapUp(TapUpDetails _) {
    _controller.forward(from: 0.0); // Animate back to full scale
  }

  void _onTapCancel() {
    _controller.forward(from: 0.0); // Animate back to full scale
  }

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
        // The GestureDetector is now only for the visual animation.
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        // The button itself handles the tap action, making it accessible.
        child: widget.isOutlined
            ? OutlinedButton(
                onPressed: widget.onTap, // <-- CORRECTED
                style: buttonStyle,
                child: Text(widget.text),
              )
            : ElevatedButton(
                onPressed: widget.onTap, // <-- CORRECTED
                style: buttonStyle,
                child: Text(widget.text),
              ),
      ),
    );
  }
}
