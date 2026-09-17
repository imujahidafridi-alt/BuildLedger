import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/components/card/shad_card.dart';
export 'package:build_ledger/shared/ui/components/card/shad_card.dart';

enum AppCardVariant {
  standard,
  elevated,
  outlined,
}

/// Compatibility wrapper delegating directly to [ShadCard].
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderSide? border;
  final AppCardVariant variant;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.border,
    this.variant = AppCardVariant.standard,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      onTap: onTap,
      padding: padding,
      backgroundColor: color,
      borderColor: border?.color,
      child: child,
    );
  }
}
