import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';

enum ShadBadgeVariant {
  neutral,
  success,
  destructive,
  warning,
  info,
  outline,
}

/// Semantic badge for status indicators (OPEN, PAID, VOIDED, PENDING, ACTIVE, OVERDUE).
class ShadBadge extends StatelessWidget {
  final String label;
  final Widget? icon;
  final ShadBadgeVariant variant;
  final bool isSmall;

  const ShadBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = ShadBadgeVariant.neutral,
    this.isSmall = false,
  });

  const ShadBadge.success({
    super.key,
    required this.label,
    this.icon,
    this.isSmall = false,
  }) : variant = ShadBadgeVariant.success;

  const ShadBadge.destructive({
    super.key,
    required this.label,
    this.icon,
    this.isSmall = false,
  }) : variant = ShadBadgeVariant.destructive;

  const ShadBadge.warning({
    super.key,
    required this.label,
    this.icon,
    this.isSmall = false,
  }) : variant = ShadBadgeVariant.warning;

  const ShadBadge.info({
    super.key,
    required this.label,
    this.icon,
    this.isSmall = false,
  }) : variant = ShadBadgeVariant.info;

  const ShadBadge.outline({
    super.key,
    required this.label,
    this.icon,
    this.isSmall = false,
  }) : variant = ShadBadgeVariant.outline;

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case ShadBadgeVariant.success:
        bg = tokens.successContainer;
        fg = tokens.success;
        break;
      case ShadBadgeVariant.destructive:
        bg = tokens.destructiveContainer;
        fg = tokens.destructive;
        break;
      case ShadBadgeVariant.warning:
        bg = tokens.warningContainer;
        fg = tokens.warning;
        break;
      case ShadBadgeVariant.info:
        bg = tokens.infoContainer;
        fg = tokens.info;
        break;
      case ShadBadgeVariant.outline:
        bg = Colors.transparent;
        fg = tokens.foreground;
        border = BorderSide(color: tokens.border, width: 1.0);
        break;
      case ShadBadgeVariant.neutral:
        bg = tokens.muted;
        fg = tokens.mutedForeground;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: ShadRadii.roundedMd,
        border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: fg, size: isSmall ? 10 : 12),
              child: icon!,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: isSmall ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
