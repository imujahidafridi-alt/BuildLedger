import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/shared/ui/components/card/shad_card.dart';
import 'package:build_ledger/shared/ui/financial/money_text.dart';

/// Restrained, high-density KPI stat card.
/// Maintains clear visual distinction between Project Cost, Supplier Payable, and Cash Outflow.
class ShadStatCard extends StatelessWidget {
  final String title;
  final Money amount;
  final String? subtitle;
  final dynamic icon;
  final MoneySemanticColor semanticColor;
  final Widget? progress;
  final double? progressFraction;
  final VoidCallback? onTap;

  const ShadStatCard({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    this.icon,
    this.semanticColor = MoneySemanticColor.neutral,
    this.progress,
    this.progressFraction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return ShadCard(
      onTap: onTap,
      padding: ShadSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: tokens.mutedForeground,
                ),
              ),
              if (icon != null) ...[
                if (icon is IconData)
                  Icon(icon as IconData, size: 16, color: tokens.mutedForeground)
                else if (icon is Widget)
                  IconTheme(
                    data: IconThemeData(size: 16, color: tokens.mutedForeground),
                    child: icon as Widget,
                  ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          MoneyText(
            amount,
            style: MoneyTextStyle.headline,
            semanticColor: semanticColor,
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            progress!,
          ] else if (progressFraction != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progressFraction!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: tokens.secondary,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: tokens.typography.muted,
            ),
          ],
        ],
      ),
    );
  }
}
