import 'dart:async'; 
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';

import 'package:brightacts_frontend_app/models/tech_system.dart';
import 'package:brightacts_frontend_app/widgets/dynamic_nebula_background.dart';

// ENHANCEMENT: App-specific card content
final List<TechSystem> backendSystems = [
  const TechSystem(
    icon: Icons.edit_document,
    title: 'Act Submission',
    description: 'Captures and validates user-submitted acts of goodwill.',
    color: Color(0xFFDA70D6), // Matches "Record Act" color
    code: r'''
// Validates and prepares a new "Bright Act" for the network.
class ActValidator {
  bool validate(ActSubmission submission) {
    if (submission.description.isEmpty) {
      return false; // Act must have a description.
    }
    if (submission.evidence.isNotProvided) {
      return false; // Evidence is required for verification.
    }
    // Additional validation logic...
    print("Act validated successfully.");
    return true;
  }
}
''',
  ),
  const TechSystem(
    icon: Icons.gavel,
    title: 'Governance Protocol',
    description: 'Manages community proposals and on-chain voting.',
    color: Color(0xFF8A2BE2), // Matches "Governance" color
    code: r'''
// A smart contract to handle community voting.
contract Governance {
  mapping(uint => Proposal) public proposals;
  mapping(address => bool) public hasVoted;

  function vote(uint proposalId, bool supports) public {
    require(!hasVoted[msg.sender], "Already voted.");
    
    if (supports) {
      proposals[proposalId].yesVotes++;
    } else {
      proposals[proposalId].noVotes++;
    }
    hasVoted[msg.sender] = true;
  }
}
''',
  ),
  const TechSystem(
    icon: Icons.public,
    title: 'Immutable Ledger',
    description: 'Records all verified acts on a transparent, public chain.',
    color: Color(0xFF00BFFF), // Matches "Ledger" color
    code: r'''
// Records a transaction on the distributed ledger.
class Ledger {
  List<Transaction> chain = [];

  void addTransaction(Act act, User user) {
    final newTx = Transaction(
      actId: act.id,
      userId: user.id,
      timestamp: DateTime.now(),
    );
    // Hashing and linking to the previous block...
    chain.add(newTx);
    print("New act recorded on the ledger.");
  }
}
''',
  ),
  const TechSystem(
    icon: Icons.wallet,
    title: 'Tokenomics Engine',
    description: 'Mints and distributes "Loves" tokens as rewards.',
    color: Color(0xFF6A5ACD), // Matches "Wallet" color
    code: r'''
// Mints new tokens as a reward for a verified act.
class TokenMinter {
  final int REWARD_AMOUNT = 10; // Loves per act

  void issueReward(User user, Act verifiedAct) {
    user.wallet.balance += REWARD_AMOUNT;
    print(
      "$REWARD_AMOUNT Loves minted for ${user.id}."
    );
    // Logic to update total supply...
  }
}
''',
  ),
];

final GlobalKey<FlippableCardGroupState> cardGroupKey = GlobalKey();

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => cardGroupKey.currentState?.resetAllCards(),
        child: Stack(
          children: [
            const DynamicNebulaBackground(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildMissionStatement(),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                      const SizedBox(height: 16),
                      _buildTechShowcase(context),
                      const SizedBox(height: 24),
                      _buildFooterLinks(),
                      const SizedBox(height: 24),
                    ],
                  ).animate().fadeIn(duration: 500.ms, curve: Curves.easeIn),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        // CHANGED: The title is now just "Bright Acts"
        StrokedText(
          text: 'Bright Acts',
          fontSize: 36,
          fontWeight: FontWeight.w900,
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMissionStatement() {
    return const Column(
      children: [
        // MOVED: The DynamicTagline is now part of the Mission Statement section
        DynamicTagline(),
        SizedBox(height: 8),
        StrokedText(
          text: 'A Web3 platform for recognizing and rewarding positive community impact through a transparent, decentralized public ledger.',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          textAlign: TextAlign.center,
        ),
      ],
    );
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
            backgroundColor: Colors.amber[800]!,
            foregroundColor: Colors.black,
            text: 'Sign In',
          ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(delay: 2.seconds, duration: 1.5.seconds, color: Colors.amber[400]),
        ),
      ],
    ).animate().fade(delay: 200.ms, duration: 800.ms).slideY(begin: 0.3);
  }

  Widget _buildTechShowcase(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const StrokedText(
          text: 'A Living Ecosystem',
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 16),
        FlippableCardGroup(
          key: cardGroupKey,
          systems: backendSystems,
        ),
      ],
    ).animate().fade(delay: 400.ms, duration: 800.ms);
  }

  Widget _buildFooterLinks() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterLink(
          url: 'https://www.linkedin.com/company/the-people-s-coin/',
          text: 'Follow Us',
        ),
        StrokedText(text: '  |  ', fontSize: 14),
        _FooterLink(
          url: 'https://github.com/DonMichaelFeeney/Brightacts',
          text: 'View Full Codebase',
        ),
        StrokedText(text: '  |  ', fontSize: 14),
        _FooterLink(
          url: 'mailto:support@brightacts.com?subject=Bright Acts Support Request',
          text: 'Support',
        ),
      ],
    );
  }
}

class FlippableCardGroup extends StatefulWidget {
  final List<TechSystem> systems;
  const FlippableCardGroup({required this.systems, super.key});

  @override
  State<FlippableCardGroup> createState() => FlippableCardGroupState();
}

class FlippableCardGroupState extends State<FlippableCardGroup> {
  int? _currentlyFlippedIndex;

  void flipCard(int index) {
    setState(() {
      if (_currentlyFlippedIndex == index) {
        _currentlyFlippedIndex = null;
      } else {
        _currentlyFlippedIndex = index;
      }
    });
  }

  void resetAllCards() {
    setState(() {
      _currentlyFlippedIndex = null;
    });
  }

  Widget _buildCard(int index) {
    if (index >= widget.systems.length) {
      return const SizedBox.shrink();
    }
    final system = widget.systems[index];
    return Flexible(
      child: FlippableTechCard(
        system: system,
        isFlipped: _currentlyFlippedIndex == index,
        onTap: () => flipCard(index),
      ).animate().fade(delay: (800 + (200 * index)).ms).slideX(begin: 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCard(0),
            _buildCard(1),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCard(2),
            _buildCard(3),
          ],
        ),
      ],
    );
  }
}

class FlippableTechCard extends StatefulWidget {
  final TechSystem system;
  final bool isFlipped;
  final VoidCallback onTap;

  const FlippableTechCard({
    required this.system,
    required this.isFlipped,
    required this.onTap,
    super.key,
  });

  @override
  State<FlippableTechCard> createState() => _FlippableTechCardState();
}

class _FlippableTechCardState extends State<FlippableTechCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(covariant FlippableTechCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final isFront = animation.value < 0.5;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(pi * animation.value);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: isFront
                  ? _buildCardFace()
                  : Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _buildCardBack(),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFace() {
    return Container(
      width: 140,
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.system.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.system.color.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
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
    );
  }

  Widget _buildCardBack() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: widget.isFlipped ? 250 : 140,
      height: widget.isFlipped ? 250 : 140,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2E3440),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.system.color),
        boxShadow: [BoxShadow(color: widget.system.color.withOpacity(0.3), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: SyntaxView(
            code: widget.system.code,
            syntax: Syntax.DART,
            syntaxTheme: SyntaxTheme.vscodeDark(),
            fontSize: 13.0,
            withZoom: false,
            withLinesCount: false,
          ),
        ),
      ),
    );
  }
}

class StrokedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  const StrokedText({
    super.key,
    required this.text,
    required this.fontSize,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = Colors.white,
          ),
        ),
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.black,
          ),
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
        setState(() => _currentIndex = (_currentIndex + 1) % _taglines.length);
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
      child: StrokedText(
        key: ValueKey<String>(_taglines[_currentIndex]),
        text: _taglines[_currentIndex],
        fontSize: 18,
        fontWeight: FontWeight.w500,
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
      label: "Link to $text",
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
          child: StrokedText(
            text: text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
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
  final String text;

  const _AnimatedScaleButton({
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ElevatedButton(onPressed: widget.onTap, style: _buttonStyle(), child: Text(widget.text)),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }
}
