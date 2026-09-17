import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:build_ledger/core/formatting/money_formatter.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Modal bottom sheet displaying comprehensive details of an expense record.
/// Allows viewing all creation inputs, editing, and deleting the expense.
class ExpenseDetailSheet extends ConsumerWidget {
  final Expense expense;

  const ExpenseDetailSheet({
    super.key,
    required this.expense,
  });

  static Future<void> show(BuildContext context, Expense expense) async {
    await ShadSheet.show(
      context: context,
      builder: (context) => ExpenseDetailSheet(expense: expense),
    );
  }

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

  void _showImagePreview(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              maxScale: 5.0,
              child: Center(
                child: File(imagePath).existsSync()
                    ? Image.file(File(imagePath), fit: BoxFit.contain)
                    : const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Receipt image file not found on device', style: TextStyle(color: Colors.white70)),
                      ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(ctx).pop(),
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ShadConfirmDialog.show(
      context,
      title: 'Delete Expense?',
      message: 'Are you sure you want to delete this expense of ${MoneyFormatter.format(expense.amount)}? '
          'This will permanently remove it from project costs and adjust supplier balances.',
      confirmLabel: 'Delete Expense',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final success = await ref.read(expenseControllerProvider.notifier).deleteExpense(expense.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Expense deleted successfully' : 'Failed to delete expense'),
            backgroundColor: success ? null : Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _onEdit(BuildContext context) async {
    Navigator.of(context).pop(); // Close sheet first
    await context.push('/expenses/edit', extra: expense);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.shad;
    final currentExpense = expense;
    final projectName = currentExpense.projectName ?? 'Site Project';

    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    final timeFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return ShadSheet(
      title: Row(
        children: [
          Expanded(
            child: Text(
              currentExpense.categoryName ?? 'Expense Details',
              style: tokens.typography.h3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          ShadBadge(
            label: currentExpense.isActive ? 'ACTIVE' : 'VOIDED',
            variant: currentExpense.isActive ? ShadBadgeVariant.success : ShadBadgeVariant.destructive,
            isSmall: true,
          ),
        ],
      ),
      description: Text(
        projectName,
        style: tokens.typography.muted,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            // 1. Prominent Spending Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.muted,
                borderRadius: ShadRadii.roundedMd,
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AMOUNT PAID / INCURRED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: tokens.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      MoneyText(
                        currentExpense.amount,
                        style: MoneyTextStyle.headline,
                        semanticColor: currentExpense.isVoided ? MoneySemanticColor.neutral : MoneySemanticColor.alert,
                      ),
                    ],
                  ),
                  ShadBadge(
                    label: currentExpense.paymentMethod.displayName.toUpperCase(),
                    variant: currentExpense.isCredit ? ShadBadgeVariant.warning : ShadBadgeVariant.outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Comprehensive Creation Inputs Grid
            _buildDetailRow(
              context,
              icon: Icons.apartment_outlined,
              label: 'Project',
              value: projectName,
            ),
            const ShadSeparator(margin: EdgeInsets.symmetric(vertical: 8)),

            _buildDetailRow(
              context,
              icon: _getCategoryIcon(currentExpense.categoryGroupName),
              label: 'Category',
              value: currentExpense.categoryName ?? 'Unspecified',
              subtitle: currentExpense.categoryGroupName != null &&
                      currentExpense.categoryGroupName != currentExpense.categoryName
                  ? 'Phase / Group: ${currentExpense.categoryGroupName}'
                  : null,
            ),
            const ShadSeparator(margin: EdgeInsets.symmetric(vertical: 8)),

            _buildDetailRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Expense Date',
              value: dateFormat.format(currentExpense.expenseDate),
            ),
            const ShadSeparator(margin: EdgeInsets.symmetric(vertical: 8)),

            _buildDetailRow(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payment Method',
              value: currentExpense.paymentMethod.displayName,
              subtitle: currentExpense.isCredit ? 'Recorded as liability in vendor ledger' : 'Direct cash/bank outflow',
            ),
            const ShadSeparator(margin: EdgeInsets.symmetric(vertical: 8)),

            _buildDetailRow(
              context,
              icon: Icons.store_outlined,
              label: 'Supplier / Vendor',
              value: currentExpense.supplierName ?? 'None / General Site Vendor',
            ),

            if (currentExpense.description != null && currentExpense.description!.isNotEmpty) ...[
              const ShadSeparator(margin: EdgeInsets.symmetric(vertical: 8)),
              _buildDetailRow(
                context,
                icon: Icons.description_outlined,
                label: 'Description / Items',
                value: currentExpense.description!,
              ),
            ],

            if (currentExpense.notes != null && currentExpense.notes!.isNotEmpty) ...[
              const ShadSeparator(margin: EdgeInsets.symmetric(vertical: 8)),
              _buildDetailRow(
                context,
                icon: Icons.edit_note_outlined,
                label: 'Site Notes',
                value: currentExpense.notes!,
              ),
            ],

            // 3. Receipt Photograph Preview
            if (currentExpense.receiptPath != null && currentExpense.receiptPath!.isNotEmpty) ...[
              const ShadSeparator(margin: EdgeInsets.symmetric(vertical: 8)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: tokens.muted,
                      borderRadius: ShadRadii.roundedMd,
                    ),
                    child: Icon(Icons.receipt_outlined, size: 16, color: tokens.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECEIPT / BILL PHOTOGRAPH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: tokens.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showImagePreview(context, currentExpense.receiptPath!),
                          child: ClipRRect(
                            borderRadius: ShadRadii.roundedMd,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Image.file(
                                  File(currentExpense.receiptPath!),
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    height: 70,
                                    color: tokens.muted,
                                    child: Center(
                                      child: Text(
                                        'Image preview unavailable',
                                        style: tokens.typography.muted,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Inspect Fullscreen',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // 4. Audit Metadata (Created & Updated)
            const ShadSeparator(margin: EdgeInsets.symmetric(vertical: 8)),
            Row(
              children: [
                Icon(Icons.history_outlined, size: 14, color: tokens.mutedForeground),
                const SizedBox(width: 6),
                Text(
                  'Created: ${timeFormat.format(currentExpense.createdAt)}',
                  style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Action Buttons (Edit & Delete)
            Row(
              children: [
                Expanded(
                  child: ShadButton.outline(
                    label: 'Edit Expense',
                    icon: Icons.edit_outlined,
                    size: ShadButtonSize.medium,
                    onPressed: () => _onEdit(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadButton.destructive(
                    label: 'Delete',
                    icon: Icons.delete_outline,
                    size: ShadButtonSize.medium,
                    onPressed: () => _onDelete(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    final tokens = context.shad;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: tokens.muted,
            borderRadius: ShadRadii.roundedMd,
          ),
          child: Icon(icon, size: 16, color: tokens.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: tokens.mutedForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: tokens.typography.p.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
