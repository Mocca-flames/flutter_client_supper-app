import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PaymentAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const PaymentAnimation({super.key, this.onComplete});

  @override
  State<PaymentAnimation> createState() => _PaymentAnimationState();
}

class _PaymentAnimationState extends State<PaymentAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'lib/assets/payment_animation.json',
      controller: _controller,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      repeat: true,
      onLoaded: (composition) {
        _controller.duration = composition.duration;
        _controller.forward();
      },
    );
  }
}
