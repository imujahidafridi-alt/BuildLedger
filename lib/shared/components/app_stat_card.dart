import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/shared/ui/financial/money_text.dart';
import 'package:build_ledger/shared/ui/financial/stat_card.dart';
import 'package:build_ledger/shared/ui/components/progress/shad_progress.dart';
export 'package:build_ledger/shared/ui/financial/stat_card.dart';

/// Compatibility wrapper delegating directly to [ShadStatCard].
class AppStatCard extends StatelessWidget {
  final String title;
  final Money amount;
  final String? subtitle;
  final IconData? icon;
  final MoneySemanticColor semanticColor;
  final double? progressFraction;
  final Color? progressColor;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    this.icon,
    this.semanticColor = MoneySemanticColor.neutral,
    this.progressFraction,
    this.progressColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ShadStatCard(
      title: title,
      amount: amount,
      subtitle: subtitle,
      icon: icon != null ? Icon(icon) : null,
      semanticColor: semanticColor,
      progress: progressFraction != null
          ? ShadProgress(
              value: progressFraction!,
              color: progressColor,
            )
          : null,
      onTap: onTap,
    );
  }
}
