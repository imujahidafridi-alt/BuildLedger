import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/features/expenses/presentation/widgets/receipt_picker_widget.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  final _amountFocusNode = FocusNode();
  final _descFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  String? _selectedProjectId;
  String? _selectedCategoryId;
  String? _selectedSupplierId;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime _expenseDate = DateTime.now();
  String? _stagedReceiptPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default to active project
    _selectedProjectId = ref.read(selectedProjectProvider)?.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _notesController.dispose();

    _amountFocusNode.dispose();
    _descFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project')),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expense category')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final amount = Money.parse(_amountController.text);

      final expense = Expense(
        id: const Uuid().v4(),
        projectId: _selectedProjectId!,
        categoryId: _selectedCategoryId!,
        supplierId: _selectedSupplierId,
        amount: amount,
        paymentMethod: _paymentMethod,
        expenseDate: _expenseDate,
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      final success = await ref.read(expenseControllerProvider.notifier).recordExpense(
            expense,
            stagedReceiptPath: _stagedReceiptPath,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsListProvider).value ?? [];
    final categories = ref.watch(expenseCategoriesProvider).value ?? [];
    final suppliers = ref.watch(suppliersListProvider).value ?? [];
    final dynamicBottomPadding = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Expense'),
      ),
      body: KeyboardDismissible(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 16, 16, dynamicBottomPadding),
            children: [
              // Amount with numeric keypad & autofocus
              ShadAmountInput(
                controller: _amountController,
                focusNode: _amountFocusNode,
                label: 'Expense Amount *',
                autofocus: true,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _descFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Project Selector
              ShadSelect<String>(
                label: 'Project *',
                placeholder: 'Select a project',
                value: _selectedProjectId,
                enableSearch: true,
                items: projects
                    .map((p) => ShadSelectItem(value: p.id, label: p.name, subtitle: p.location))
                    .toList(),
                onChanged: (val) => setState(() => _selectedProjectId = val),
                validator: (v) => v == null ? 'Project is required' : null,
              ),
              const SizedBox(height: 16),

              // Category Selector
              ShadSelect<String>(
                label: 'Expense Category *',
                placeholder: 'Select an expense category',
                value: _selectedCategoryId,
                enableSearch: true,
                items: categories
                    .map((c) => ShadSelectItem(value: c.id, label: c.name, subtitle: c.groupName))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
                validator: (v) => v == null ? 'Category is required' : null,
              ),
              const SizedBox(height: 16),

              // Payment Method
              ShadSelect<PaymentMethod>(
                label: 'Payment Method *',
                value: _paymentMethod,
                items: PaymentMethod.values
                    .map((m) => ShadSelectItem(value: m, label: m.displayName))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),
              const SizedBox(height: 16),

              // Supplier / Vendor (Mandatory if Credit)
              ShadSelect<String?>(
                label: _paymentMethod == PaymentMethod.credit
                    ? 'Supplier / Vendor * (Required for Credit)'
                    : 'Supplier / Vendor (Optional)',
                placeholder: 'None / General Site Vendor',
                value: _selectedSupplierId,
                enableSearch: true,
                items: [
                  const ShadSelectItem<String?>(value: null, label: 'None / General Site Vendor'),
                  ...suppliers.map((s) => ShadSelectItem<String?>(value: s.id, label: s.name, subtitle: s.phone)),
                ],
                onChanged: (val) => setState(() => _selectedSupplierId = val),
                validator: (v) {
                  if (_paymentMethod == PaymentMethod.credit && (v == null || v.isEmpty)) {
                    return 'Supplier is required for credit purchases';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Harmonized Expense Date Picker
              ShadDateInput(
                label: 'Expense Date *',
                selectedDate: _expenseDate,
                onDateChanged: (picked) => setState(() => _expenseDate = picked),
              ),
              const SizedBox(height: 16),

              // Description
              ShadInput(
                controller: _descController,
                focusNode: _descFocusNode,
                label: 'Description / Item Details',
                hint: 'e.g. 50 bags Lucky Cement, 1000 bricks',
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _notesFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Receipt Attachment Pipeline
              ReceiptPickerWidget(
                onReceiptChanged: (path) => setState(() => _stagedReceiptPath = path),
              ),
              const SizedBox(height: 16),

              // Internal Notes
              ShadInput(
                controller: _notesController,
                focusNode: _notesFocusNode,
                label: 'Internal Site Notes (Optional)',
                hint: 'Gate pass #, truck license plate, remarks...',
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ShadButton(
                label: 'Save Expense',
                isLoading: _isSaving,
                variant: ShadButtonVariant.primary,
                size: ShadButtonSize.lg,
                fullWidth: true,
                onPressed: _isSaving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

