import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';

/// Restrained progress bar conforming to ShadCN visual language.
class ShadProgress extends StatelessWidget {
  /// Value between 0.0 and 1.0 (or higher if clamped).
  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const ShadProgress({
    super.key,
    required this.value,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final clamped = value.clamp(0.0, 1.0);
    final fillCol = color ?? tokens.primary;
    final bgCol = backgroundColor ?? tokens.muted;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: ShadRadii.roundedFull,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: fillCol,
            borderRadius: ShadRadii.roundedFull,
          ),
        ),
      ),
    );
  }
}
