import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/shared/ui/financial/money_text.dart';

/// Pure UI project selector component with ZERO Riverpod / application-state coupling.
/// Can be rendered as a compact AppBar title widget or an expansive banner.
class ShadProjectSelector extends StatelessWidget {
  final Project? project;
  final VoidCallback onTap;
  final bool isCompact;

  const ShadProjectSelector({
    super.key,
    required this.project,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final projectName = project?.name ?? 'All Projects';

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
                Icon(Icons.apartment, color: tokens.primary, size: 18),
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
                      child: Icon(Icons.apartment, size: 18, color: tokens.primary),
                    ),
                  ),
                  const SizedBox(width: ShadSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ACTIVE PROJECT',
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
                  if (project != null) ...[
                    MoneyText(
                      project!.budgetAmount,
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
