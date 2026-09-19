import 'package:flutter/material.dart';
import 'package:build_ledger/features/dashboard/domain/models/project_financial_summary.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class BudgetGaugeCard extends StatelessWidget {
  final ProjectFinancialSummary summary;
  final VoidCallback onSelectProject;

  const BudgetGaugeCard({
    super.key,
    required this.summary,
    required this.onSelectProject,
  });

  ShadBadgeVariant _getUtilizationVariant(int percent) {
    if (percent >= 90) return ShadBadgeVariant.destructive;
    if (percent >= 75) return ShadBadgeVariant.warning;
    return ShadBadgeVariant.outline;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final badgeVariant = _getUtilizationVariant(summary.utilizationPercent);
    final fraction = (summary.utilizationPercent / 100.0).clamp(0.0, 1.0);

    Color progressColor;
    if (summary.utilizationPercent >= 90) {
      progressColor = tokens.destructive;
    } else if (summary.utilizationPercent >= 75) {
      progressColor = tokens.warning;
    } else {
      progressColor = tokens.primary;
    }

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Switcher Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: ShadRadii.roundedMd,
              onTap: onSelectProject,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: tokens.muted,
                            borderRadius: ShadRadii.roundedMd,
                          ),
                          child: Icon(Icons.apartment, size: 16, color: tokens.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          summary.projectName,
                          style: tokens.typography.h3,
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.unfold_more_rounded, size: 18, color: tokens.mutedForeground),
                      ],
                    ),
                    ShadBadge(
                      label: '${summary.utilizationPercent}% USED',
                      variant: badgeVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Total Incurred Spent Headline
          Text(
            'TOTAL INCURRED SPENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: tokens.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          MoneyText(
            summary.actualCost,
            style: MoneyTextStyle.display,
            semanticColor: summary.isOverBudget ? MoneySemanticColor.alert : MoneySemanticColor.neutral,
          ),
          const SizedBox(height: 12),

          // Utilization Bar
          ShadProgress(
            value: fraction,
            height: 8,
            color: progressColor,
          ),
          const SizedBox(height: 16),
          const ShadSeparator(),
          const SizedBox(height: 14),

          // Budget & Remaining Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL BUDGET',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tokens.mutedForeground),
                  ),
                  const SizedBox(height: 2),
                  MoneyText(summary.budget, style: MoneyTextStyle.body),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    summary.isOverBudget ? 'BUDGET DEFICIT' : 'REMAINING BUDGET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: summary.isOverBudget ? tokens.destructive : tokens.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MoneyText(
                    summary.remainingBudget,
                    style: MoneyTextStyle.body,
                    semanticColor: summary.isOverBudget ? MoneySemanticColor.alert : MoneySemanticColor.profit,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const ShadSeparator(),
          const SizedBox(height: 14),

          // Three Pillars Row (Cash Outflow vs Supplier Payable)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: tokens.muted.withValues(alpha: 0.6),
                    borderRadius: ShadRadii.roundedMd,
                    border: Border.all(color: tokens.border.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, size: 14, color: tokens.primary),
                          const SizedBox(width: 5),
                          Text(
                            'CASH OUTFLOW',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: tokens.mutedForeground),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      MoneyText(summary.cashOutflow, style: MoneyTextStyle.body),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: tokens.muted.withValues(alpha: 0.6),
                    borderRadius: ShadRadii.roundedMd,
                    border: Border.all(color: tokens.border.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.store,
                                size: 14,
                                color: summary.supplierPayables.isPositive ? tokens.destructive : tokens.success,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'SUPPLIER PAYABLE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: tokens.mutedForeground),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MoneyText(
                            summary.supplierPayables,
                            style: MoneyTextStyle.body,
                            semanticColor: summary.supplierPayables.isPositive ? MoneySemanticColor.alert : MoneySemanticColor.profit,
                          ),
                          if (summary.supplierPayables.minorUnits == 0)
                            Text(
                              'CLEARED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: tokens.success,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
