import 'package:flutter/material.dart';

typedef AnimationCompleteCallback = void Function();

class AnimatedDigitWidget extends StatefulWidget {
  final double value;
  final TextStyle? textStyle;
  final Duration duration;
  final Curve curve;
  final int fractionDigits;
  final AnimationCompleteCallback? onAnimationComplete;
  final double? initialValue; // optional initial start value for first animation

  const AnimatedDigitWidget({
    Key? key,
    required this.value,
    this.textStyle,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOut,
    this.fractionDigits = 0,
    this.onAnimationComplete,
    this.initialValue,
  }) : super(key: key);

  @override
  _AnimatedDigitWidgetState createState() => _AnimatedDigitWidgetState();
}

class _AnimatedDigitWidgetState extends State<AnimatedDigitWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _oldValue;

  @override
  void initState() {
    super.initState();

    // Start from initialValue or zero on first build for nice entry animation
    _oldValue = widget.initialValue ?? 0;

    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: _oldValue, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (widget.onAnimationComplete != null) {
            widget.onAnimationComplete!();
          }
        }
      });

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDigitWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.0001) {
      _oldValue = oldWidget.value;
      _animation = Tween<double>(begin: _oldValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            if (widget.onAnimationComplete != null) {
              widget.onAnimationComplete!();
            }
          }
        });

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
