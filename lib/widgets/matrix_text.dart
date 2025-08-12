import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class MatrixText extends StatefulWidget {
  final String targetText;
  final TextStyle? style;
  final bool isLoading; // scramble effect toggle
  final Duration speed;
  final VoidCallback? onTypingComplete; // Callback when typing finishes

  const MatrixText({
    super.key,
    required this.targetText,
    this.style,
    this.isLoading = false,
    this.speed = const Duration(milliseconds: 50),
    this.onTypingComplete,
  });

  @override
  State<MatrixText> createState() => _MatrixTextState();
}

class _MatrixTextState extends State<MatrixText> with SingleTickerProviderStateMixin {
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890*#@!?';
  final _random = Random();
  Timer? _scrambleTimer;
  late String _displayedText;

  int _typingIndex = 0;
  List<String> _typingCharacters = [];
  bool _isTypingAnimating = false;

  @override
  void initState() {
    super.initState();
    _displayedText = widget.isLoading
        ? _generateRandomString(widget.targetText.length)
        : widget.targetText;

    if (widget.isLoading) {
      _startScrambleAnimation();
    } else {
      _startTypingAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant MatrixText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading || widget.targetText != oldWidget.targetText) {
      _scrambleTimer?.cancel();
      _isTypingAnimating = false;
      Future.delayed(const Duration(milliseconds: 10), () {
        if (!mounted) return;
        if (widget.isLoading) {
          _startScrambleAnimation();
        } else {
          _startTypingAnimation();
        }
      });
    }
  }

  void _startScrambleAnimation() {
    _typingIndex = 0;
    _typingCharacters = [];
    _displayedText = _generateRandomString(widget.targetText.length);

    _scrambleTimer = Timer.periodic(widget.speed, (timer) {
      if (mounted && widget.isLoading) {
        setState(() {
          _displayedText = _generateRandomString(widget.targetText.length);
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startTypingAnimation() {
    _scrambleTimer?.cancel();
    _isTypingAnimating = true;
    _typingCharacters = widget.targetText.split('');
    _displayedText = '';
    _typingIndex = 0;

    if (widget.speed.inMilliseconds == 0 || widget(targetText ?? \'\').isEmpty) {
      setState(() {
        _displayedText = widget.targetText;
        _isTypingAnimating = false;
        widget.onTypingComplete?.call();
      });
    } else {
      _animateTyping();
    }
  }

  void _animateTyping() {
    if (!mounted || !_isTypingAnimating || _typingIndex >= _typingCharacters.length) {
      if (mounted && _displayedText != widget.targetText) {
        setState(() {
          _displayedText = widget.targetText;
        });
      }
      _isTypingAnimating = false;
      widget.onTypingComplete?.call();
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
    _scrambleTimer?.cancel();
    _isTypingAnimating = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textToRender = widget.isLoading ? _displayedText : widget.targetText;

    return RepaintBoundary(
      child: Container(
        color: Colors.black.withOpacity(0.001),
        child: Text(
          textToRender,
          style: widget.style,
        ),
      ),
    );
  }
}

