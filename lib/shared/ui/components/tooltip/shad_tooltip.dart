import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';

/// Minimal tooltip for concise helper cues.
class ShadTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const ShadTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return Tooltip(
      message: message,
      textStyle: tokens.typography.small.copyWith(color: tokens.cardForeground),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: ShadRadii.roundedMd,
        border: Border.all(color: tokens.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: child,
    );
  }
}
