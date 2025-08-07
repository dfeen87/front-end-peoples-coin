import 'package:flutter/material.dart';

class NavigationCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? cardColor;
  final double opacity;
  final Widget? expandedContent;

  const NavigationCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
    this.cardColor,
    this.opacity = 0.25,
    this.expandedContent,
  });

  @override
  State<NavigationCard> createState() => _NavigationCardState();
}

class _NavigationCardState extends State<NavigationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _iconSizeAnimation;
  late final Animation<AlignmentGeometry> _iconAlignmentAnimation;
  late final Animation<Offset> _titleSlideAnimation;
  late final Animation<double> _titleOpacityAnimation;
  late final Animation<Offset> _descriptionSlideAnimation;
  late final Animation<double> _descriptionOpacityAnimation;
  late final Animation<double> _expandedContentOpacityAnimation;
  late final Animation<double> _cardHeightFactorAnimation;

  bool _isExpanded = false;

  static const Curve _commonCurve = Curves.easeInOutCubic;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _iconSizeAnimation = Tween<double>(begin: 60.0, end: 35.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: _commonCurve)),
    );

    _iconAlignmentAnimation = AlignmentTween(
      begin: Alignment.center,
      end: const Alignment(0.0, -0.8),
    ).animate(
      CurvedAnimation(parent: _controller, curve: _commonCurve),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.8),
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: _commonCurve)),
    );

    _titleOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: _commonCurve)),
    );

    _descriptionSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.8),
    ).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: _commonCurve)),
    );

    _descriptionOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: _commonCurve)),
    );

    _expandedContentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: _commonCurve)),
    );

    _cardHeightFactorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: _commonCurve),
    );

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (_isExpanded) {
      _controller.reverse();
      if (widget.onTap != null) {
        widget.onTap!();
      }
    } else {
      _controller.forward();
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final cardColor =
        (widget.cardColor ?? Colors.white.withOpacity(0.15)).withOpacity(widget.opacity);

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Card dimensions
    final collapsedWidth = (screenWidth * 0.55).clamp(240.0, 400.0);
    final collapsedHeight = (screenHeight * 0.3).clamp(180.0, 280.0);
    final expandedExtraHeight = widget.expandedContent != null ? 120.0 : 0.0;

    final cardHeight = _isExpanded ? collapsedHeight + expandedExtraHeight : collapsedHeight;

    return Center(
      child: GestureDetector(
        onTap: _toggleExpanded,
        behavior: HitTestBehavior.opaque,
        child: Card(
          color: cardColor,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: AnimatedContainer(
            duration: _controller.duration ?? const Duration(milliseconds: 700),
            curve: _commonCurve,
            width: collapsedWidth,
            height: cardHeight,
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              physics: _isExpanded
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: _iconAlignmentAnimation.value,
                    child: Icon(widget.icon, size: _iconSizeAnimation.value, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  FractionalTranslation(
                    translation: _titleSlideAnimation.value,
                    child: Opacity(
                      opacity: _titleOpacityAnimation.value,
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  FractionalTranslation(
                    translation: _descriptionSlideAnimation.value,
                    child: Opacity(
                      opacity: _descriptionOpacityAnimation.value,
                      child: Text(
                        widget.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                      ),
                    ),
                  ),
                  SizeTransition(
                    sizeFactor: _cardHeightFactorAnimation,
                    axisAlignment: -1.0,
                    child: FadeTransition(
                      opacity: _expandedContentOpacityAnimation,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: widget.expandedContent ?? const SizedBox(),
                        ),
                      ),
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

