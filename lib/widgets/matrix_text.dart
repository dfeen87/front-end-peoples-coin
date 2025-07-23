import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'dart:math'; // For Random

class MatrixText extends StatefulWidget {
  final String targetText;
  final TextStyle? style;
  final bool isLoading;
  final Duration speed;

  const MatrixText({
    super.key,
    required this.targetText,
    this.style,
    this.isLoading = false,
    this.speed = const Duration(milliseconds: 50),
  });

  @override
  State<MatrixText> createState() => _MatrixTextState();
}

class _MatrixTextState extends State<MatrixText> {
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890*#@!?';
  final _random = Random();
  Timer? _scrambleTimer; // Timer specifically for scrambling effect
  late String _displayedText; // The text currently visible

  // For typing animation (when not loading)
  int _typingIndex = 0;
  List<String> _typingCharacters = [];
  bool _isTypingAnimating = false; // Flag for the typing animation

  @override
  void initState() {
    super.initState();
    // Initialize with correct state based on isLoading
    if (widget.isLoading) {
      _startScrambleAnimation();
    } else {
      _startTypingAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant MatrixText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If loading state or target text changes, stop current animations and restart
    if (widget.isLoading != oldWidget.isLoading || widget.targetText != oldWidget.targetText) {
      _scrambleTimer?.cancel(); // Cancel any existing scramble timer
      _isTypingAnimating = false; // Signal to stop any ongoing typing animation

      // A small delay to allow previous animation frames to clean up before starting new one
      Future.delayed(const Duration(milliseconds: 10), () {
        if (mounted) { // Ensure widget is still mounted before starting
          if (widget.isLoading) {
            _startScrambleAnimation();
          } else {
            _startTypingAnimation();
          }
        }
      });
    }
  }

  void _startScrambleAnimation() {
    _typingIndex = 0; // Reset typing animation state
    _typingCharacters = []; // Clear typing characters
    _displayedText = _generateRandomString(widget.targetText.length); // Initial scramble

    _scrambleTimer = Timer.periodic(widget.speed, (timer) {
      if (mounted && widget.isLoading) { // Only scramble if still loading and mounted
        setState(() {
          _displayedText = _generateRandomString(widget.targetText.length);
        });
      } else {
        timer.cancel(); // Stop scrambling if no longer loading or widget unmounted
      }
    });
  }

  void _startTypingAnimation() {
    _scrambleTimer?.cancel(); // Stop any scramble timer
    _isTypingAnimating = true; // Set flag for typing animation
    _typingCharacters = widget.targetText.split('');
    _displayedText = ''; // Start with empty string for typing effect
    _typingIndex = 0;

    // Immediately set full text if speed is 0 or very fast, or target is empty
    if (widget.speed.inMilliseconds == 0 || widget.targetText.isEmpty) {
      setState(() {
        _displayedText = widget.targetText;
        _isTypingAnimating = false;
      });
    } else {
      _animateTyping();
    }
  }

  void _animateTyping() {
    // Stop conditions for typing animation
    if (!mounted || !_isTypingAnimating || _typingIndex >= _typingCharacters.length) {
      // Ensure full text is displayed if animation completes or stops prematurely
      if (mounted && _displayedText != widget.targetText) {
        setState(() {
          _displayedText = widget.targetText;
        });
      }
      _isTypingAnimating = false;
      return;
    }

    setState(() {
      _displayedText += _typingCharacters[_typingIndex];
      _typingIndex++;
    });

    Future.delayed(widget.speed, _animateTyping);
  }

  String _generateRandomString(int length) {
    if (length <= 0) return '';
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_random.nextInt(_chars.length))));
  }

  @override
  void dispose() {
    _scrambleTimer?.cancel(); // Cancel scramble timer on dispose
    _isTypingAnimating = false; // Stop typing animation on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When not loading, ensure the full targetText is always shown when animation is done
    final textToRender = widget.isLoading ? _displayedText : widget.targetText;

    return Text(
      textToRender,
      style: widget.style,
    );
  }
}
