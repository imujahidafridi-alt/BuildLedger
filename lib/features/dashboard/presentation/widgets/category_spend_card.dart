import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class CategorySpendCard extends StatelessWidget {
  final Map<String, Money> categoryBreakdown;

  const CategorySpendCard({super.key, required this.categoryBreakdown});

  IconData _getGroupIcon(String group) {
    switch (group.toLowerCase()) {
      case 'materials':
        return Icons.construction;
      case 'labour':
        return Icons.engineering;
      case 'equipment':
        return Icons.precision_manufacturing;
      case 'transport':
        return Icons.local_shipping;
      case 'other':
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    if (categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENDING BY CATEGORY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: tokens.mutedForeground,
            ),
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
