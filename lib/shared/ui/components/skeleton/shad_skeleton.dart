import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';

/// Subtle pulse placeholder for skeleton loading states.
class ShadSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShadSkeleton({
    super.key,
    this.width,
    this.height = 16.0,
    this.borderRadius,
  });

  const ShadSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = ShadRadii.roundedFull;

  @override
  State<ShadSkeleton> createState() => _ShadSkeletonState();
}

class _ShadSkeletonState extends State<ShadSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: tokens.muted.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? ShadRadii.roundedMd,
          ),
        );
      },
    );
  }
}
