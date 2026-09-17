import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/labour/domain/entities/labour_entry.dart';
import 'package:build_ledger/features/labour/presentation/controllers/labour_controller.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class LabourShiftFormScreen extends ConsumerStatefulWidget {
  const LabourShiftFormScreen({super.key});

  @override
  ConsumerState<LabourShiftFormScreen> createState() => _LabourShiftFormScreenState();
}

class _LabourShiftFormScreenState extends ConsumerState<LabourShiftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workerNameController = TextEditingController();
  final _rateController = TextEditingController(text: '2500');
  final _advanceController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  final _workerNameFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();
  final _advanceFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  String _selectedRole = 'Mason (Mistri)';
  int _daysX100 = 100; // 1.0 day default
  DateTime _entryDate = DateTime.now();
  bool _autoRecordExpense = true;
  bool _isSaving = false;

  final List<String> _tradeRoles = [
    'Mason (Mistri)',
    'General Labour (Mazdoor)',
    'Plumber',
    'Electrician',
    'Carpenter',
    'Painter',
    'Welder',
    'Steel Fixer',
    'Tile Mason',
  ];

  @override
  void dispose() {
    _workerNameController.dispose();
    _rateController.dispose();
    _advanceController.dispose();
    _notesController.dispose();

    _workerNameFocusNode.dispose();
    _rateFocusNode.dispose();
    _advanceFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  Money _computeCalculatedNet() {
    final rate = Money.parse(_rateController.text);
    final advance = Money.parse(_advanceController.text);
    return LabourEntry.calculateNetWage(
      rate: rate,
      daysX100: _daysX100,
      advance: advance,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final activeProject = ref.read(selectedProjectProvider);
    if (activeProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active project first')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final rate = Money.parse(_rateController.text);
      final advance = Money.parse(_advanceController.text);
      final netWage = LabourEntry.calculateNetWage(
        rate: rate,
        daysX100: _daysX100,
        advance: advance,
      );

      final entry = LabourEntry(
        id: const Uuid().v4(),
        projectId: activeProject.id,
        workerName: _workerNameController.text.trim(),
        role: _selectedRole,
        rate: rate,
        daysX100: _daysX100,
        advance: advance,
        netAmount: netWage,
        entryDate: _entryDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );

      final success = await ref.read(labourControllerProvider.notifier).recordLabourShift(
            entry,
            autoCreateProjectExpense: _autoRecordExpense,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Labour shift recorded successfully')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final netWage = _computeCalculatedNet();
    final tokens = context.shad;
    final dynamicBottomPadding = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Labour Shift'),
      ),
      body: KeyboardDismissible(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 16, 16, dynamicBottomPadding),
            children: [
              // Worker Name
              ShadInput(
                controller: _workerNameController,
                focusNode: _workerNameFocusNode,
                label: 'Worker Name *',
                hint: 'e.g. Ustad Aslam, Rashid Mazdoor',
                prefixIcon: const Icon(Icons.person, size: 18),
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _rateFocusNode.requestFocus(),
                validator: (v) => v == null || v.trim().isEmpty ? 'Worker name is required' : null,
              ),
              const SizedBox(height: 16),

              // Trade Role Selector
              ShadSelect<String>(
                label: 'Trade / Role *',
                value: _selectedRole,
                items: _tradeRoles.map((r) => ShadSelectItem(value: r, label: r)).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 16),

              // Daily Wage Rate
              ShadAmountInput(
                controller: _rateController,
                focusNode: _rateFocusNode,
                label: 'Daily Wage Rate *',
                hint: '2500',
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _advanceFocusNode.requestFocus(),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Days Worked Selector
              Text(
                'DAYS WORKED *',
                style: tokens.typography.small.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: tokens.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              ShadTabs<int>(
                values: const [50, 100, 150, 200],
                selectedValue: _daysX100,
                labelBuilder: (v) {
                  switch (v) {
                    case 50:
                      return '0.5 Day';
                    case 100:
                      return '1.0 Day';
                    case 150:
                      return '1.5 Days';
                    case 200:
                      return '2.0 Days';
                    default:
                      return '$v';
                  }
                },
                onTabSelected: (val) => setState(() => _daysX100 = val),
              ),
              const SizedBox(height: 16),

              // Advance Paid on Site
              ShadAmountInput(
                controller: _advanceController,
                focusNode: _advanceFocusNode,
                label: 'Advance Paid on Site (Optional)',
                hint: '0',
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _notesFocusNode.requestFocus(),
                validator: (_) => null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Dynamic Net Wage Calculation Banner
              ShadCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NET PAYOUT CALCULATED',
                          style: tokens.typography.small.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: tokens.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(Rate × Days) − Advance',
                          style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
                        ),
                      ],
                    ),
                    MoneyText(
                      netWage,
                      style: MoneyTextStyle.headline,
                      semanticColor: MoneySemanticColor.profit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Harmonized Shift Date Picker
              ShadDateInput(
                label: 'Shift Date *',
                selectedDate: _entryDate,
                onDateChanged: (picked) => setState(() => _entryDate = picked),
              ),
              const SizedBox(height: 12),

              // Auto-record as cash expense checkbox
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _autoRecordExpense,
                activeColor: tokens.primary,
                checkColor: tokens.primaryForeground,
                title: Text('Record net wage in project expenses', style: tokens.typography.p),
                subtitle: Text(
                  'Automatically logs this payout into project expenses under Labour',
                  style: tokens.typography.small.copyWith(color: tokens.mutedForeground),
                ),
                onChanged: (val) => setState(() => _autoRecordExpense = val ?? true),
              ),
              const SizedBox(height: 12),

              // Notes
              ShadInput(
                controller: _notesController,
                focusNode: _notesFocusNode,
                label: 'Site Notes (Optional)',
                hint: 'Overtime, specific task completed...',
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              ShadButton(
                label: 'Save Labour Shift',
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

