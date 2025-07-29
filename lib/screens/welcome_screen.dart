// lib/screens/welcome_screen.dart

import 'dart:async';
import 'dart:ui';
// --- CORRECTED IMPORTS: Replaced '.' with ':' ---
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/dynamic_nebula_background.dart';
import 'package:brightacts_frontend_app/models/tech_system.dart';
import 'code_display_page.dart';

// Data for all backend system cards
final List<TechSystem> backendSystems = [
  const TechSystem(
      icon: Icons.cloud_queue,
      title: 'Cloud Infrastructure',
      description: 'Manages scalable cloud resources and services.',
      color: Colors.blueAccent,
      code: '...'),
  const TechSystem(
      icon: Icons.security,
      title: 'Security Protocol',
      description: 'Ensures data integrity and user authentication.',
      color: Colors.redAccent,
      code: '...'),
  const TechSystem(
      icon: Icons.analytics,
      title: 'Data Analytics',
      description: 'Processes and visualizes community impact data.',
      color: Colors.purpleAccent,
      code: '...'),
  const TechSystem(
      icon: Icons.storage,
      title: 'Blockchain Ledger',
      description: 'Records acts of goodwill on an immutable ledger.',
      color: Colors.greenAccent,
      code: '...'),
];

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _showCodeViewer(BuildContext context, TechSystem system) {
    context.go('/code-viewer', extra: system);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const DynamicNebulaBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildMissionStatement(),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                  const Spacer(flex: 3),
                  _buildTechShowcase(context),
                  const Spacer(flex: 1),
                  _buildFooterLinks(context),
                  const Spacer(flex: 1),
                ],
              ).animate().fadeIn(duration: 500.ms, curve: Curves.easeIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Welcome to Bright Acts',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 10.0, color: Colors.black54, offset: Offset(0, 2))],
          ),
        ).animate().fade(duration: 900.ms).slideY(begin: 0.5),
        const SizedBox(height: 8),
        const DynamicTagline(),
      ],
    );
  }

  Widget _buildMissionStatement() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: const Text(
            'A Web3 platform for recognizing and rewarding positive community impact through a transparent, decentralized public ledger.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
              shadows: [Shadow(blurRadius: 5.0, color: Colors.black38)],
            ),
          ).animate().fadeIn(delay: 600.ms).moveY(begin: 10),
        ),
      ),
    ).animate().fade(delay: 200.ms, duration: 900.ms).slideY(begin: 0.4);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnimatedScaleButton(
            onTap: () => context.go('/sign_up'),
            backgroundColor: Colors.amber[800]!,
            foregroundColor: Colors.black,
            text: 'Join the Movement',
          ).animate(onPlay: (controller) => controller.repeat())
             .shimmer(delay: 2.seconds, duration: 1.5.seconds, color: Colors.amber[400]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _AnimatedScaleButton(
            onTap: () => context.go('/sign_in'),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            borderColor: Colors.white,
            isOutlined: true,
            text: 'Sign In',
          ),
        ),
      ],
    ).animate().fade(delay: 400.ms, duration: 900.ms).slideY(begin: 0.3);
  }

  Widget _buildTechShowcase(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'A Living Ecosystem',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 5.0, color: Colors.black38)],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: backendSystems.map((system) {
            final index = backendSystems.indexOf(system);
            return Flexible(
              child: _TechSystemCard(
                system: system,
                onTap: () => _showCodeViewer(context, system),
              ).animate().fade(delay: (800 + (200 * index)).ms).slideX(begin: 0.5),
            );
          }).toList(),
        ),
      ],
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
        const Text('  |  ', style: TextStyle(color: Colors.white70)),
        _FooterLink(
          url: 'https://www.linkedin.com/company/the-people-s-coin/',
          text: 'Follow Us',
        ),
      ],
    );
  }
}

class DynamicTagline extends StatefulWidget {
  const DynamicTagline({super.key});

  @override
  State<DynamicTagline> createState() => _DynamicTaglineState();
}

class _DynamicTaglineState extends State<DynamicTagline> {
  final List<String> _taglines = ['Transparency', 'Community', 'Goodwill'];
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _taglines.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        _taglines[_currentIndex],
        key: ValueKey<String>(_taglines[_currentIndex]),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
          shadows: [Shadow(blurRadius: 5.0, color: Colors.black38)],
        ),
      ),
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Technology card for ${widget.system.title}. Tap to view code.',
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          onHover: (hovering) => setState(() => _isHovered = hovering),
          borderRadius: BorderRadius.circular(12),
          splashColor: widget.system.color.withOpacity(0.4),
          highlightColor: widget.system.color.withOpacity(0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: _isHovered ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  width: 140,
                  height: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.system.color.withOpacity(_isHovered ? 0.3 : 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.system.color.withOpacity(0.4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: Icon(widget.system.icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.system.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                          shadows: [Shadow(blurRadius: 3.0, color: Colors.black54)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String url;
  final String text;
  const _FooterLink({required this.url, required this.text});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$text. Opens in a new tab.',
      link: true,
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 3.0, color: Colors.black54)],
            ),
          ),
        ),
      ),
    );
  }
}

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
  void _onTapUp(TapDownDetails _) => _controller.forward(from: 0.0);
  void _onTapCancel() => _controller.forward(from: 0.0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.text,
      button: true,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: widget.isOutlined
              ? OutlinedButton(onPressed: widget.onTap, style: _buttonStyle(), child: Text(widget.text))
              : ElevatedButton(onPressed: widget.onTap, style: _buttonStyle(), child: Text(widget.text)),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return widget.isOutlined
      ? OutlinedButton.styleFrom(
          side: BorderSide(
              color: widget.borderColor ?? widget.foregroundColor, width: 2),
          foregroundColor: widget.foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        )
      : ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        );
  }
}
