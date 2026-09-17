import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/dashboard/presentation/widgets/category_breakdown_sheet.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class CategorySpendCard extends StatelessWidget {
  final Map<String, Money> categoryBreakdown;
  final String? projectName;
  final String? projectId;

  const CategorySpendCard({
    super.key,
    required this.categoryBreakdown,
    this.projectName,
    this.projectId,
  });

  IconData _getGroupIcon(String group) {
    final g = group.toLowerCase();
    if (g.contains('material') || g.contains('grey') || g.contains('structure') || g.contains('cement') || g.contains('steel')) {
      return Icons.construction_outlined;
    } else if (g.contains('finish') || g.contains('paint') || g.contains('tile') || g.contains('wood')) {
      return Icons.palette_outlined;
    } else if (g.contains('labour') || g.contains('contract') || g.contains('site') || g.contains('worker')) {
      return Icons.engineering_outlined;
    } else if (g.contains('plumb') || g.contains('bath') || g.contains('water') || g.contains('pipe')) {
      return Icons.water_drop_outlined;
    } else if (g.contains('elect') || g.contains('power') || g.contains('cable') || g.contains('light')) {
      return Icons.electrical_services_outlined;
    }
    return Icons.category_outlined;
  }

  void _openBreakdown(BuildContext context) {
    CategoryBreakdownSheet.show(
      context,
      breakdown: categoryBreakdown,
      projectName: projectName,
      projectId: projectId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    if (categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalMinor = categoryBreakdown.values.fold<int>(0, (sum, m) => sum + m.minorUnits);

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOP EXPENSE CATEGORIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: tokens.mutedForeground,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openBreakdown(context),
                  borderRadius: ShadRadii.roundedMd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Breakdown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: tokens.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryBreakdown.length,
            separatorBuilder: (_, _) => const ShadSeparator(margin: EdgeInsets.symmetric(vertical: 8)),
            itemBuilder: (context, index) {
              final entry = categoryBreakdown.entries.elementAt(index);
              final group = entry.key;
              final amount = entry.value;
              final percent = totalMinor > 0 ? ((amount.minorUnits / totalMinor) * 100).round() : 0;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: ShadRadii.roundedMd,
                  onTap: () => _openBreakdown(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: tokens.muted,
                            borderRadius: ShadRadii.roundedMd,
                          ),
                          child: Icon(_getGroupIcon(group), size: 16, color: tokens.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            group,
                            style: tokens.typography.p.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ShadBadge(
                          label: '$percent%',
                          variant: ShadBadgeVariant.outline,
                          isSmall: true,
                        ),
                        const SizedBox(width: 10),
                        MoneyText(
                          amount,
                          style: MoneyTextStyle.body,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const ShadSeparator(),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: ShadRadii.roundedMd,
              onTap: () => _openBreakdown(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 15,
                      color: tokens.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'View Detailed Breakdown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
