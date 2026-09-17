import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class RecordSupplierPaymentDialog extends ConsumerStatefulWidget {
  final Supplier supplier;

  const RecordSupplierPaymentDialog({super.key, required this.supplier});

  static Future<bool?> show(BuildContext context, Supplier supplier) async {
    return await ShadSheet.show<bool>(
      context: context,
      builder: (context) => RecordSupplierPaymentDialog(supplier: supplier),
    );
  }

  @override
  ConsumerState<RecordSupplierPaymentDialog> createState() => _RecordSupplierPaymentDialogState();
}

class _RecordSupplierPaymentDialogState extends ConsumerState<RecordSupplierPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController(text: 'Payment to Supplier');
  final _refController = TextEditingController();

  final _amountFocusNode = FocusNode();
  final _descFocusNode = FocusNode();
  final _refFocusNode = FocusNode();

  DateTime _paymentDate = DateTime.now();
  String? _selectedProjectId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default to active selected project if available
    _selectedProjectId = ref.read(selectedProjectProvider)?.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _refController.dispose();

    _amountFocusNode.dispose();
    _descFocusNode.dispose();
    _refFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final amount = Money.parse(_amountController.text);
      final success = await ref.read(supplierControllerProvider.notifier).recordPayment(
            supplierId: widget.supplier.id,
            projectId: _selectedProjectId,
            amount: amount,
            description: _descController.text.trim(),
            date: _paymentDate,
            referenceId: _refController.text.trim().isNotEmpty ? _refController.text.trim() : null,
          );

      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsListProvider).value ?? [];

    return ShadSheet(
      title: Text('Record Payment to ${widget.supplier.name}'),
      child: KeyboardDismissible(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShadAmountInput(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  label: 'Payment Amount *',
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _descFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                if (projects.isNotEmpty) ...[
                  ShadSelect<String?>(
                    label: 'Attributed Project (Optional)',
                    placeholder: 'General / Non-Project',
                    value: _selectedProjectId,
                    enableSearch: true,
                    items: [
                      const ShadSelectItem<String?>(value: null, label: 'General / Non-Project'),
                      ...projects.map((p) => ShadSelectItem<String?>(value: p.id, label: p.name, subtitle: p.location)),
                    ],
                    onChanged: (val) => setState(() => _selectedProjectId = val),
                  ),
                  const SizedBox(height: 16),
                ],
                ShadDateInput(
                  label: 'Payment Date',
                  selectedDate: _paymentDate,
                  onDateChanged: (picked) => setState(() => _paymentDate = picked),
                ),
                const SizedBox(height: 16),
                ShadInput(
                  controller: _descController,
                  focusNode: _descFocusNode,
                  label: 'Description / Notes',
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _refFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                ShadInput(
                  controller: _refController,
                  focusNode: _refFocusNode,
                  label: 'Reference # (Cheque/Bank Trx/Slip)',
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                ShadButton(
                  label: 'Save Payment',
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
      ),
    );
  }
}

