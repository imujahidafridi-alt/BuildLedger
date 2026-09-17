import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/shared/ui/components/button/shad_button.dart';

/// Purposeful, non-decorative empty state with exactly one primary CTA.
class ShadEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customAction;

  const ShadEmptyState({
    super.key,
    required this.icon,
    required this.title,
    String? message,
    String? description,
    this.actionLabel,
    this.onAction,
    this.customAction,
  }) : message = message ?? description ?? '';

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.muted,
                borderRadius: ShadRadii.roundedLg,
                border: Border.all(color: tokens.border, width: 1.0),
              ),
              child: Icon(
                icon,
                size: 32,
                color: tokens.primary,
              ),
            ),
            const SizedBox(height: ShadSpacing.lg),
            Text(
              title,
              style: tokens.typography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ShadSpacing.xs),
            Text(
              message,
              style: tokens.typography.muted,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: ShadSpacing.xl),
              ShadButton(
                label: actionLabel!,
                onPressed: onAction,
                size: ShadButtonSize.medium,
              ),
            ] else if (customAction != null) ...[
              const SizedBox(height: ShadSpacing.xl),
              customAction!,
            ],
          ],
        ),
      ),
    );
  }
}
