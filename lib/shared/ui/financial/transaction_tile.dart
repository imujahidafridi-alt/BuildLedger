import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/formatting/date_formatter.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/shared/ui/components/badge/shad_badge.dart';
import 'package:build_ledger/shared/ui/financial/money_text.dart';

enum TransactionDirection {
  outflow, // expense, payment made
  inflow, // refund received, adjustment credit
  neutral,
}

/// Unified transaction row tile for expenses, supplier ledger entries, and labour records.
class ShadTransactionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final DateTime date;
  final Money amount;
  final TransactionDirection direction;
  final Widget? leadingIcon;
  final Widget? trailingAction;
  final String? statusBadge;
  final ShadBadgeVariant badgeVariant;
  final bool isVoided;
  final VoidCallback? onTap;

  const ShadTransactionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.date,
    required this.amount,
    this.direction = TransactionDirection.outflow,
    this.leadingIcon,
    this.trailingAction,
    this.statusBadge,
    this.badgeVariant = ShadBadgeVariant.neutral,
    this.isVoided = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    Color iconBg = isVoided
        ? tokens.destructiveContainer
        : tokens.muted;
    Color iconColor = isVoided
        ? tokens.destructive
        : tokens.primary;

    MoneySemanticColor moneySemantic;
    if (isVoided) {
      moneySemantic = MoneySemanticColor.alert;
    } else if (direction == TransactionDirection.inflow) {
      moneySemantic = MoneySemanticColor.profit;
    } else {
      moneySemantic = MoneySemanticColor.neutral;
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
          padding: const EdgeInsets.symmetric(horizontal: ShadSpacing.md, vertical: ShadSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: ShadRadii.roundedMd,
                  ),
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(color: iconColor, size: 20),
                      child: leadingIcon!,
                    ),
                  ),
                ),
                const SizedBox(width: ShadSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: tokens.typography.p.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: isVoided ? TextDecoration.lineThrough : null,
                              color: isVoided ? tokens.destructive : tokens.foreground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVoided) ...[
                          const SizedBox(width: 6),
                          const ShadBadge.destructive(label: 'VOIDED', isSmall: true),
                        ] else if (statusBadge != null) ...[
                          const SizedBox(width: 6),
                          ShadBadge(
                            label: statusBadge!,
                            variant: badgeVariant,
                            isSmall: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          DateFormatter.format(date),
                          style: tokens.typography.muted,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          Text(' • ', style: TextStyle(color: tokens.mutedForeground, fontSize: 11)),
                          Expanded(
                            child: Text(
                              subtitle!,
                              style: tokens.typography.muted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ShadSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoneyText(
                    amount,
                    style: MoneyTextStyle.body,
                    semanticColor: moneySemantic,
                    showSign: direction == TransactionDirection.inflow,
                  ),
                  if (trailingAction != null) ...[
                    const SizedBox(height: 4),
                    trailingAction!,
                  ],
                ],
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: tokens.mutedForeground.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
