import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class CategorySpendCard extends StatelessWidget {
  final Map<String, Money> categoryBreakdown;

  const CategorySpendCard({super.key, required this.categoryBreakdown});

  IconData _getGroupIcon(String group) {
    final g = group.toLowerCase();
    if (g.contains('material') || g.contains('grey') || g.contains('structure')) {
      return Icons.construction_outlined;
    } else if (g.contains('finish') || g.contains('paint') || g.contains('tile')) {
      return Icons.palette_outlined;
    } else if (g.contains('labour') || g.contains('contract') || g.contains('site')) {
      return Icons.engineering_outlined;
    } else if (g.contains('plumb') || g.contains('bath') || g.contains('water')) {
      return Icons.water_drop_outlined;
    } else if (g.contains('elect') || g.contains('power')) {
      return Icons.electrical_services_outlined;
    }
    return Icons.category_outlined;
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
              InkWell(
                onTap: () => context.push('/expenses'),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'View Breakdown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.primary,
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

              return Row(
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
              );
            },
          ),
        ],
      ),
    );
  }
}
