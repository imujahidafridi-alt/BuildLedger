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
    switch (group?.toLowerCase()) {
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
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final isVoided = expense.isVoided;

    return ShadTransactionTile(
      title: expense.categoryName ?? 'Construction Expense',
      subtitle: expense.supplierName ?? expense.description ?? 'General site purchase',
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

