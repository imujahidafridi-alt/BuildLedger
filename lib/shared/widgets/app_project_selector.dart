import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/shared/ui/financial/money_text.dart';
export 'package:build_ledger/shared/ui/navigation/project_selector.dart';

/// Compatibility wrapper for project selection header/bar.
class AppProjectSelector extends StatelessWidget {
  final String projectName;
  final VoidCallback onTap;
  final Money? budgetAmount;
  final bool isCompact;
  final IconData prefixIcon;

  const AppProjectSelector({
    super.key,
    required this.projectName,
    required this.onTap,
    this.budgetAmount,
    this.isCompact = false,
    this.prefixIcon = Icons.apartment,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    if (isCompact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: ShadRadii.roundedMd,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(prefixIcon, color: tokens.primary, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    projectName,
                    style: tokens.typography.h4.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.unfold_more_rounded, color: tokens.mutedForeground, size: 16),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: ShadRadii.roundedLg,
        side: BorderSide(color: tokens.border, width: 1.0),
      ),
      child: InkWell(
        borderRadius: ShadRadii.roundedLg,
        onTap: onTap,
        child: Padding(
          padding: ShadSpacing.compactPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tokens.muted,
                      borderRadius: ShadRadii.roundedMd,
                    ),
                    child: Center(
                      child: Icon(prefixIcon, size: 18, color: tokens.primary),
                    ),
                  ),
                  const SizedBox(width: ShadSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ACTIVE REPORTING PROJECT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: tokens.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        projectName,
                        style: tokens.typography.h4,
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (budgetAmount != null) ...[
                    MoneyText(
                      budgetAmount!,
                      style: MoneyTextStyle.caption,
                      compact: true,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(Icons.chevron_right, size: 18, color: tokens.mutedForeground),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
