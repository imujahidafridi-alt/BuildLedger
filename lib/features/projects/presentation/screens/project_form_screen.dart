import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  final Project? existingProject;

  const ProjectFormScreen({super.key, this.existingProject});

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;
  late final TextEditingController _clientController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;

  DateTime? _startDate;
  DateTime? _expectedEndDate;
  bool _isSaving = false;

  final _nameFocusNode = FocusNode();
  final _budgetFocusNode = FocusNode();
  final _clientFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final p = widget.existingProject;
    _nameController = TextEditingController(text: p?.name ?? '');
    _budgetController = TextEditingController(
      text: p != null ? (p.budgetAmount.minorUnits / 100.0).toStringAsFixed(0) : '',
    );
    _clientController = TextEditingController(text: p?.clientName ?? '');
    _locationController = TextEditingController(text: p?.location ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _startDate = p?.startDate ?? DateTime.now();
    _expectedEndDate = p?.expectedEndDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _clientController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();

    _nameFocusNode.dispose();
    _budgetFocusNode.dispose();
    _clientFocusNode.dispose();
    _locationFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final budgetMoney = Money.parse(_budgetController.text);
      final now = DateTime.now();

      final project = Project(
        id: widget.existingProject?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        budgetAmount: budgetMoney,
        clientName: _clientController.text.trim().isNotEmpty ? _clientController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        startDate: _startDate,
        expectedEndDate: _expectedEndDate,
        createdAt: widget.existingProject?.createdAt ?? now,
        updatedAt: now,
      );

      final success = await ref.read(projectControllerProvider.notifier).createProject(project);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProject != null ? 'Edit Project' : 'New Project'),
      ),
      body: KeyboardDismissible(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.paddingOf(context).bottom + 32,
            ),
            children: [
              ShadInput(
                controller: _nameController,
                focusNode: _nameFocusNode,
                label: 'Project Name *',
                hint: 'e.g. Hayatabad House, Plaza Phase 2',
                prefixIcon: const Icon(Icons.apartment, size: 18),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.organizationName],
                onFieldSubmitted: (_) => _budgetFocusNode.requestFocus(),
                validator: (val) => val == null || val.trim().isEmpty ? 'Project name is required' : null,
              ),
              const SizedBox(height: 16),
              ShadAmountInput(
                controller: _budgetController,
                focusNode: _budgetFocusNode,
                label: 'Total Project Budget *',
                hint: '15,000,000',
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _clientFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),
              ShadInput(
                controller: _clientController,
                focusNode: _clientFocusNode,
                label: 'Client / Owner Name (Optional)',
                hint: 'e.g. Mr. Khan',
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                onFieldSubmitted: (_) => _locationFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),
              ShadInput(
                controller: _locationController,
                focusNode: _locationFocusNode,
                label: 'Site Location (Optional)',
                hint: 'e.g. Sector F-4, Peshawar',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.addressCity],
                onFieldSubmitted: (_) => _descriptionFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),
              ShadDateInput(
                label: 'Start Date',
                selectedDate: _startDate ?? DateTime.now(),
                onDateChanged: (picked) => setState(() => _startDate = picked),
              ),
              const SizedBox(height: 16),
              ShadInput(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                label: 'Project Notes (Optional)',
                hint: 'Scope of work, contract details...',
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ShadButton(
                label: 'Save Project',
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
