import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion.dart';

/// A card that turns around its vertical axis when tapped (3D flip).
class FlipCard extends StatefulWidget {
  const FlipCard({super.key, required this.front, required this.back, this.onFlipped});

  final Widget front;
  final Widget back;

  /// Called with `true` when the back becomes visible.
  final ValueChanged<bool>? onFlipped;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  bool _showBack = false;

  void _toggle() {
    _showBack = !_showBack;
    widget.onFlipped?.call(_showBack);
    if (reducedMotion(context)) {
      _controller.value = _showBack ? 1 : 0;
    } else if (_showBack) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      onTap: _toggle,
      hint: 'Торкніться, щоб перевернути картку',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            final angle = _curve.value * math.pi;
            final onBack = angle > math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: onBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: widget.back,
                    )
                  : widget.front,
            );
          },
        ),
      ),
    );
  }
}
