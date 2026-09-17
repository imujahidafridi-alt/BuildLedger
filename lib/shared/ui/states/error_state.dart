import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/shared/ui/components/button/shad_button.dart';

/// Clean error feedback container with optional retry trigger.
class ShadErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String title;
  final String retryLabel;

  const ShadErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Operation Encountered an Error',
    this.retryLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: ShadSpacing.cardPadding,
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: ShadRadii.roundedLg,
            border: Border.all(color: tokens.destructive.withValues(alpha: 0.3), width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 36, color: tokens.destructive),
              const SizedBox(height: ShadSpacing.md),
              Text(
                title,
                style: tokens.typography.h4,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: tokens.typography.muted,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: ShadSpacing.lg),
                ShadButton.outline(
                  label: retryLabel,
                  icon: const Icon(Icons.refresh, size: 16),
                  size: ShadButtonSize.small,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
