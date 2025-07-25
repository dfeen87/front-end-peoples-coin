import 'package:flutter/material.dart';

class AnimatedDigitWidget extends StatefulWidget {
  final double value;
  final TextStyle? textStyle;
  final Duration duration;
  final Curve curve;
  final int fractionDigits;

  const AnimatedDigitWidget({
    Key? key,
    required this.value,
    this.textStyle,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOut,
    this.fractionDigits = 0,
  }) : super(key: key);

  @override
  _AnimatedDigitWidgetState createState() => _AnimatedDigitWidgetState();
}

class _AnimatedDigitWidgetState extends State<AnimatedDigitWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: _oldValue, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDigitWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _animation = Tween<double>(begin: _oldValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.toStringAsFixed(widget.fractionDigits),
          style: widget.textStyle ?? const TextStyle(fontSize: 24, color: Colors.white),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

