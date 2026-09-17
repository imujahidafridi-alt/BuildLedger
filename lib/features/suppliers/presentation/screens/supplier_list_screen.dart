import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  void _showAddSupplierDialog(BuildContext context, WidgetRef ref) {
    ShadDialog.show(
      context: context,
      builder: (ctx) => const _AddSupplierDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersListProvider);
    final tokens = context.shad;
    final dynamicBottomPadding = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    final hasSuppliers = suppliersAsync.asData?.value.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers & Vendors'),
      ),
      body: suppliersAsync.when(
        loading: () => const ShadLoadingState(message: 'Loading suppliers & ledgers...'),
        error: (err, _) => ShadErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(suppliersListProvider),
        ),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return ShadEmptyState(
              icon: Icons.store,
              title: 'No Suppliers Yet',
              message: 'Add building material suppliers, hardware stores, and vendors to track credit purchases and outstanding balances.',
              actionLabel: 'Add Supplier',
              onAction: () => _showAddSupplierDialog(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(suppliersListProvider),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 16, 16, dynamicBottomPadding),
              itemCount: suppliers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                final hasOutstanding = supplier.currentBalance.isPositive;

                return ShadCard(
                  onTap: () => context.push('/suppliers/${supplier.id}', extra: supplier),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tokens.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.store,
                          color: tokens.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supplier.name,
                              style: tokens.typography.p.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (supplier.phone != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                supplier.phone!,
                                style: tokens.typography.small.copyWith(
                                  color: tokens.mutedForeground,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasOutstanding)
                            const ShadBadge.destructive(label: 'OUTSTANDING', isSmall: true)
                          else
                            const ShadBadge.success(label: 'SETTLED', isSmall: true),
                          const SizedBox(height: 4),
                          MoneyText(
                            supplier.currentBalance,
                            style: MoneyTextStyle.body,
                            semanticColor: hasOutstanding ? MoneySemanticColor.alert : MoneySemanticColor.profit,
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, size: 18, color: tokens.mutedForeground),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: hasSuppliers
          ? FloatingActionButton.extended(
              heroTag: 'new_supplier_fab',
              backgroundColor: tokens.primary,
              foregroundColor: tokens.primaryForeground,
              elevation: 2,
              onPressed: () => _showAddSupplierDialog(context, ref),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Add Supplier',
                style: TextStyle(
                  color: tokens.primaryForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }
}

class _AddSupplierDialog extends ConsumerStatefulWidget {
  const _AddSupplierDialog();

  @override
  ConsumerState<_AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends ConsumerState<_AddSupplierDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _openingCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _openingFocusNode = FocusNode();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _openingCtrl.dispose();

    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _openingFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final openingBalance = _openingCtrl.text.trim().isNotEmpty
          ? Money.parse(_openingCtrl.text)
          : Money.zero;

      final supplier = Supplier(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      final success = await ref.read(supplierControllerProvider.notifier).createSupplier(
            supplier,
            openingBalance: openingBalance,
          );

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Add Vendor / Supplier'),
      content: KeyboardDismissible(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadInput(
                  controller: _nameCtrl,
                  focusNode: _nameFocusNode,
                  label: 'Supplier Name *',
                  hint: 'e.g. ABC Cement Agency',
                  prefixIcon: const Icon(Icons.store, size: 18),
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.organizationName],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: _phoneCtrl,
                  focusNode: _phoneFocusNode,
                  label: 'Phone Number (Optional)',
                  hint: '0300-1234567',
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _addressFocusNode.requestFocus(),
                  prefixIcon: const Icon(Icons.phone, size: 18),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: _addressCtrl,
                  focusNode: _addressFocusNode,
                  label: 'Address / Market (Optional)',
                  hint: 'e.g. Ring Road, Peshawar',
                  textCapitalization: TextCapitalization.sentences,
                  autofillHints: const [AutofillHints.postalAddress],
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _openingFocusNode.requestFocus(),
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                ),
                const SizedBox(height: 12),
                ShadAmountInput(
                  controller: _openingCtrl,
                  focusNode: _openingFocusNode,
                  label: 'Previous Opening Balance (If any)',
                  hint: '0',
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (_) => null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          size: ShadButtonSize.small,
          label: 'Cancel',
        ),
        ShadButton(
          onPressed: _isSaving ? null : _submit,
          isLoading: _isSaving,
          variant: ShadButtonVariant.primary,
          size: ShadButtonSize.small,
          label: 'Save Supplier',
        ),
      ],
    );
  }
}

