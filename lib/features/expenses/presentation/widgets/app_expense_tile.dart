import 'package:flutter/material.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class AppExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onVoid;

  const AppExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
    this.onVoid,
  });

  IconData _getCategoryIcon(String? group) {
    final g = group?.toLowerCase() ?? '';
    if (g.contains('material') || g.contains('grey') || g.contains('structure') || g.contains('masonry')) {
      return Icons.construction_outlined;
    } else if (g.contains('finish') || g.contains('tile') || g.contains('paint') || g.contains('sanitary')) {
      return Icons.palette_outlined;
    } else if (g.contains('external') || g.contains('earth') || g.contains('site')) {
      return Icons.landscape_outlined;
    } else if (g.contains('prof') || g.contains('labour') || g.contains('contract')) {
      return Icons.engineering_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final isVoided = expense.isVoided;

    final subtitleParts = <String>[];
    if (expense.categoryGroupName != null && expense.categoryGroupName != expense.categoryName) {
      subtitleParts.add(expense.categoryGroupName!);
    }
    if (expense.supplierName != null) {
      subtitleParts.add(expense.supplierName!);
    } else if (expense.description != null && expense.description!.isNotEmpty) {
      subtitleParts.add(expense.description!);
    }
    final subtitle = subtitleParts.isNotEmpty ? subtitleParts.join(' · ') : 'General site purchase';

    return ShadTransactionTile(
      title: expense.categoryName ?? 'Construction Expense',
      subtitle: subtitle,
      date: expense.expenseDate,
      amount: expense.amount,
      direction: TransactionDirection.outflow,
      isVoided: isVoided,
      leadingIcon: Icon(_getCategoryIcon(expense.categoryGroupName)),
      statusBadge: isVoided ? null : (expense.isCredit ? 'CREDIT' : null),
      badgeVariant: ShadBadgeVariant.warning,
      onTap: onTap,
      trailingAction: (onVoid != null && !isVoided)
          ? InkWell(
              onTap: onVoid,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Void',
                  style: tokens.typography.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens.destructive,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

