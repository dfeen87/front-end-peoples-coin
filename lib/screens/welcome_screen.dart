import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/dynamic_nebula_background.dart';
import 'package:brightacts_frontend_app/models/tech_system.dart'; // Import TechSystem from its central location
import 'code_display_page.dart'; // CodeDisplayPage now expects TechSystem directly

// Removed the duplicate TechSystem class definition from here.
// It is now defined only in 'package:brightacts_frontend_app/models/tech_system.dart'.

final List<TechSystem> backendSystems = [
  // Example systems (you might have more defined in your actual project)
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
        # Simulate deployment logic
        return {"status": "success", "service_id": f"svc-{hash(service_name)}"}

    def scale_resources(self, service_id, scale_factor):
        """Scales resources for an existing service."""
        print(f"Scaling service {service_id} by factor {scale_factor}")
        # Simulate scaling logic
        return {"status": "scaled", "new_capacity": 100 * scale_factor}

# Example usage:
if __name__ == "__main__":
    manager = CloudManager(provider='Google Cloud')
    app_config = {"memory": "2GB", "cpu": "2 cores"}
    service_result = manager.deploy_service("WebApp", app_config)
    print(service_result)
    manager.scale_resources(service_result["service_id"], 2)
'''
  ),
  const TechSystem(
    icon: Icons.security,
    title: 'Security Protocol',
    description: 'Ensures data integrity and user authentication.',
    color: Colors.redAccent,
    code: '''
# Example Python code for Security Protocol
class SecurityModule:
    def __init__(self, encryption_algo='AES256'):
        self.encryption_algo = encryption_algo
        print(f"Security module initialized with {self.encryption_algo} encryption.")

    def encrypt_data(self, data):
        """Encrypts sensitive data."""
        encrypted_data = f"ENCRYPTED_{data}_{self.encryption_algo}"
        print(f"Data encrypted: {encrypted_data[:20]}...")
        return encrypted_data

    def authenticate_user(self, username, password_hash):
        """Authenticates a user against stored credentials."""
        # In a real system, this would involve hashing and comparison
        if username == "admin" and password_hash == "hashed_password":
            print("User authenticated successfully.")
            return True
        print("Authentication failed.")
        return False

# Example usage:
if __name__ == "__main__":
    security = SecurityModule()
    sensitive_info = "MySecretData123"
    encrypted = security.encrypt_data(sensitive_info)
    
    security.authenticate_user("admin", "hashed_password")
    security.authenticate_user("guest", "wrong_password")
'''
  ),
  const TechSystem(
    icon: Icons.analytics,
    title: 'Data Analytics Engine',
    description: 'Processes and visualizes community impact data.',
    color: Colors.purpleAccent,
    code: '''
# Example Python code for Data Analytics Engine
import pandas as pd
import numpy as np

class AnalyticsEngine:
    def __init__(self):
        print("Analytics engine ready.")

    def process_data(self, raw_data):
        """Processes raw data into a structured DataFrame."""
        df = pd.DataFrame(raw_data)
        print("Data processed into DataFrame.")
        return df

    def generate_report(self, dataframe):
        """Generates a summary report from the DataFrame."""
        total_acts = len(dataframe)
        avg_loves = dataframe['loves'].mean()
        print(f"Report Generated: Total Acts = {total_acts}, Average Loves = {avg_loves:.2f}")
        return {"total_acts": total_acts, "avg_loves": avg_loves}

# Example usage:
if __name__ == "__main__":
    engine = AnalyticsEngine()
    data = [
        {"user": "Alice", "loves": 10, "type": "Donation"},
        {"user": "Bob", "loves": 15, "type": "Volunteering"},
        {"user": "Charlie", "loves": 8, "type": "Donation"},
    ]
    processed_df = engine.process_data(data)
    report = engine.generate_report(processed_df)
    print(report)
'''
  ),
  const TechSystem(
    icon: Icons.storage,
    title: 'Blockchain Ledger',
    description: 'Records all acts of goodwill on an immutable blockchain.',
    color: Colors.greenAccent,
    code: '''
# Example Python code for Blockchain Ledger (simplified)
import hashlib
import json
import time

class Block:
    def __init__(self, index, timestamp, data, previous_hash):
        self.index = index
        self.timestamp = timestamp
        self.data = data
        self.previous_hash = previous_hash
        self.hash = self.calculate_hash()

    def calculate_hash(self):
        block_string = json.dumps(self.__dict__, sort_keys=True)
        return hashlib.sha256(block_string.encode()).hexdigest()

class Blockchain:
    def __init__(self):
        self.chain = [self.create_genesis_block()]

    def create_genesis_block(self):
        return Block(0, time.time(), "Genesis Block", "0")

    def get_latest_block(self):
        return self.chain[-1]

    def add_block(self, new_block):
        new_block.previous_hash = self.get_latest_block().hash
        new_block.hash = new_block.calculate_hash()
        self.chain.append(new_block)

# Example usage:
if __name__ == "__main__":
    brightacts_chain = Blockchain()
    
    brightacts_chain.add_block(Block(1, time.time(), {"act": "Donated blood", "user": "Alice"}, ""))
    brightacts_chain.add_block(Block(2, time.time(), {"act": "Volunteered at shelter", "user": "Bob"}, ""))
    
    print("Blockchain created:")
    for block in brightacts_chain.chain:
        print(f"Block #{block.index}: Hash={block.hash}, Data={block.data}")
'''
  ),
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
              // Pass the TechSystem object directly, as CodeDisplayPage now expects it.
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
        const Text('|', style: TextStyle(color: Colors.white24)),
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

  const _TechSystemCard({required this.system, required this.onTap, Key? key}) : super(key: key);

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

  const _FooterLink({required this.url, required this.text, Key? key}) : super(key: key);

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovering = false;

  void _onHover(bool hover) {
    setState(() {
      _hovering = hover;
    });
  }

  Future<void> _launch() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
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
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller.drive(Tween(begin: 1.0, end: 0.95));
  }

  void _onTapDown(TapDownDetails _) => _controller.reverse();

  void _onTapUp(TapUpDetails _) {
    _controller.forward();
    widget.onTap();
  }

  void _onTapCancel() => _controller.forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btn = widget.isOutlined
        ? OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: widget.borderColor ?? widget.foregroundColor, width: 2),
              foregroundColor: widget.foregroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: Text(widget.text),
          )
        : ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shadowColor: Colors.black45,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(widget.text),
          );

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: btn,
      ),
    );
  }
}

