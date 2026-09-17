import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class QuickExpenseScreen extends ConsumerStatefulWidget {
  const QuickExpenseScreen({super.key});

  @override
  ConsumerState<QuickExpenseScreen> createState() => _QuickExpenseScreenState();
}

class _QuickExpenseScreenState extends ConsumerState<QuickExpenseScreen> {
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  String? _selectedCategoryId;
  String? _selectedSupplierId;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final activeProject = ref.read(selectedProjectProvider);
    if (activeProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create an active project first')),
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap a category')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final amount = Money.parse(_amountController.text);

      final expense = Expense(
        id: const Uuid().v4(),
        projectId: activeProject.id,
        categoryId: _selectedCategoryId!,
        supplierId: _selectedSupplierId,
        amount: amount,
        paymentMethod: _paymentMethod,
        expenseDate: now,
        description: 'Quick Site Entry',
        createdAt: now,
        updatedAt: now,
      );

      final success = await ref.read(expenseControllerProvider.notifier).recordExpense(expense);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully!')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProject = ref.watch(selectedProjectProvider);
    final categories = ref.watch(expenseCategoriesProvider).value ?? [];
    final suppliers = ref.watch(suppliersListProvider).value ?? [];
    final tokens = context.shad;
    final dynamicBottomPadding = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    // Top 8 frequent construction categories for 1-tap selection
    final quickCategories = categories.take(8).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.flash_on, color: tokens.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Quick Site Expense'),
          ],
        ),
      ),
      body: KeyboardDismissible(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 16, 16, dynamicBottomPadding),
          children: [
            // Project banner
            ShadCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.apartment, size: 18, color: tokens.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeProject != null ? 'Project: ${activeProject.name}' : 'No active project selected',
                      style: tokens.typography.p.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Big Amount Field with Autofocus
            ShadAmountInput(
              controller: _amountController,
              focusNode: _amountFocusNode,
              label: 'Amount (Rupees) *',
              autofocus: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _amountFocusNode.unfocus(),
            ),
            const SizedBox(height: 20),

          // 1-Tap Category Grid
          Text(
            'SELECT CATEGORY *',
            style: tokens.typography.small.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: tokens.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickCategories.map((cat) {
              final isSelected = _selectedCategoryId == cat.id;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() => _selectedCategoryId = isSelected ? null : cat.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? tokens.primary : tokens.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? tokens.primary : tokens.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? tokens.primaryForeground : tokens.foreground,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Supplier Dropdown
          ShadSelect<String?>(
            label: 'Supplier / Vendor (Optional)',
            placeholder: 'No Supplier / Site Cash',
            value: _selectedSupplierId,
            enableSearch: true,
            items: [
              const ShadSelectItem<String?>(value: null, label: 'No Supplier / Site Cash'),
              ...suppliers.map((s) => ShadSelectItem<String?>(value: s.id, label: s.name, subtitle: s.phone)),
            ],
            onChanged: (val) => setState(() => _selectedSupplierId = val),
          ),
          const SizedBox(height: 16),

          // Quick Cash / Credit Toggle using ShadTabs
          ShadTabs<PaymentMethod>(
            values: const [PaymentMethod.cash, PaymentMethod.credit],
            selectedValue: _paymentMethod,
            labelBuilder: (m) => m == PaymentMethod.cash ? 'Cash Payment' : 'On Credit',
            onTabSelected: (m) => setState(() => _paymentMethod = m),
          ),
          const SizedBox(height: 32),

          // Big 1-Tap Save Button
          ShadButton(
            label: 'SAVE EXPENSE NOW',
            icon: Icons.check,
            isLoading: _isSaving,
            variant: ShadButtonVariant.primary,
            size: ShadButtonSize.lg,
            fullWidth: true,
            onPressed: _isSaving ? null : _submit,
          ),
        ],
      ),
    ),
  );
}
}
