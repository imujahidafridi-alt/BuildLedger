import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:build_ledger/features/suppliers/presentation/dialogs/record_supplier_payment_dialog.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class SupplierDetailLedgerScreen extends ConsumerWidget {
  final String supplierId;
  final Supplier? initialSupplier;

  const SupplierDetailLedgerScreen({
    super.key,
    required this.supplierId,
    this.initialSupplier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(supplierLedgerProvider(supplierId));
    final tokens = context.shad;
    final dynamicBottomPadding = MediaQuery.paddingOf(context).bottom + 16;

    // Find the latest supplier record with up-to-date balance from suppliersListProvider
    final suppliers = ref.watch(suppliersListProvider).value ?? [];
    final supplier = suppliers.cast<Supplier?>().firstWhere(
          (s) => s?.id == supplierId,
          orElse: () => initialSupplier,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(supplier?.name ?? 'Supplier Ledger'),
      ),
      body: Column(
        children: [
          // Header Financial Summary Card
          if (supplier != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: tokens.card,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT OUTSTANDING PAYABLE',
                            style: tokens.typography.small.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: tokens.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          MoneyText(
                            supplier.currentBalance,
                            style: MoneyTextStyle.headline,
                            semanticColor: supplier.currentBalance.isPositive
                                ? MoneySemanticColor.alert
                                : MoneySemanticColor.profit,
                          ),
                        ],
                      ),
                      ShadButton(
                        onPressed: () async {
                          final recorded = await RecordSupplierPaymentDialog.show(context, supplier);
                          if (recorded == true) {
                            ref.invalidate(supplierLedgerProvider(supplierId));
                            ref.invalidate(suppliersListProvider);
                          }
                        },
                        icon: Icons.payment,
                        size: ShadButtonSize.small,
                        variant: ShadButtonVariant.primary,
                        label: 'Record Payment',
                      ),
                    ],
                  ),
                  if (supplier.phone != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: tokens.mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          supplier.phone!,
                          style: tokens.typography.small.copyWith(color: tokens.mutedForeground),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          Divider(height: 1, color: tokens.border),

          // Ledger Entries List
          Expanded(
            child: ledgerAsync.when(
              loading: () => const ShadLoadingState(message: 'Loading ledger statement...'),
              error: (err, _) => ShadErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(supplierLedgerProvider(supplierId)),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const ShadEmptyState(
                    icon: Icons.receipt_long,
                    title: 'No Transactions',
                    message: 'No purchase or payment records found for this vendor.',
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, dynamicBottomPadding),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isCredit = entry.isCredit;

                    return ShadTransactionTile(
                      title: entry.description,
                      subtitle: entry.entryType.displayName,
                      date: entry.entryDate,
                      amount: entry.amount,
                      direction: isCredit ? TransactionDirection.inflow : TransactionDirection.outflow,
                      leadingIcon: Icon(isCredit ? Icons.add_shopping_cart : Icons.check_circle_outline),
                      statusBadge: isCredit ? 'PURCHASE' : 'PAYMENT',
                      badgeVariant: isCredit ? ShadBadgeVariant.warning : ShadBadgeVariant.success,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

