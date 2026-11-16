import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'theme.dart';

/// True when the phone asks for no animations (accessibility setting).
bool reducedMotion(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Smooth appearance: the child fades in and rises a little.
/// [delay] lets neighbours appear one after another.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.offset = 16,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    final start = total.inMilliseconds == 0 ? 0.0 : widget.delay.inMilliseconds / total.inMilliseconds;
    _curve = CurvedAnimation(parent: _controller, curve: Interval(start, 1, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reducedMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(offset: Offset(0, (1 - _curve.value) * widget.offset), child: child),
      ),
    );
  }
}

/// A soft spring press: the child shrinks a little while it is pressed and
/// springs back when released. It listens to raw pointer events, so the
/// button inside keeps working as usual.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true, this.pressedScale = 0.95});

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, lowerBound: 0.5, upperBound: 1.2, value: 1);

  static const _spring = SpringDescription(mass: 1, stiffness: 320, damping: 12);

  void _down(PointerEvent _) {
    if (!widget.enabled || reducedMotion(context)) return;
    _controller.animateTo(widget.pressedScale, duration: const Duration(milliseconds: 90), curve: Curves.easeOut);
  }

  void _up(PointerEvent _) {
    if (reducedMotion(context)) return;
    _controller.animateWith(SpringSimulation(_spring, _controller.value, 1, _controller.velocity));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: ScaleTransition(scale: _controller, child: widget.child),
    );
  }
}

/// Reacts to the result of an answer: a light horizontal shake when it is
/// wrong and a soft glow when it is right. Pass `null` while nothing is checked.
class AnswerFeedbackAnimation extends StatefulWidget {
  const AnswerFeedbackAnimation({super.key, required this.result, required this.child});

  final bool? result;
  final Widget child;

  @override
  State<AnswerFeedbackAnimation> createState() => _AnswerFeedbackAnimationState();
}

class _AnswerFeedbackAnimationState extends State<AnswerFeedbackAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void didUpdateWidget(AnswerFeedbackAnimation old) {
    super.didUpdateWidget(old);
    if (old.result == widget.result) return;
    if (widget.result == null || reducedMotion(context)) {
      _controller.value = 0;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final wrong = widget.result == false;
        final right = widget.result == true;
        final dx = wrong ? math.sin(t * math.pi * 5) * 9 * (1 - t) : 0.0;
        final glow = right ? math.sin(t * math.pi) : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(Colors.transparent, AppColors.paleBlue, glow),
              borderRadius: BorderRadius.circular(24),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
