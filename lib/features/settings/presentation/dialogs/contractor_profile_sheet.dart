import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/settings/domain/entities/contractor_profile.dart';
import 'package:build_ledger/features/settings/presentation/controllers/settings_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Modal sheet allowing the contractor to customize company name, tax ID, and contact info.
/// Changes persist to local preferences and immediately populate PDF reports.
class ContractorProfileSheet extends ConsumerStatefulWidget {
  const ContractorProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return ShadSheet.show(
      context: context,
      builder: (context) => const ShadSheet(
        child: ContractorProfileSheet(),
      ),
    );
  }

  @override
  ConsumerState<ContractorProfileSheet> createState() => _ContractorProfileSheetState();
}

class _ContractorProfileSheetState extends ConsumerState<ContractorProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  final _nameFocusNode = FocusNode();
  final _taxIdFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(contractorProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _taxIdController = TextEditingController(text: profile.taxId);
    _phoneController = TextEditingController(text: profile.phone);
    _emailController = TextEditingController(text: profile.email);
    _addressController = TextEditingController(text: profile.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();

    _nameFocusNode.dispose();
    _taxIdFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updated = ContractorProfile(
        name: _nameController.text.trim(),
        taxId: _taxIdController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      );

      await ref.read(contractorProfileProvider.notifier).saveProfile(updated);

      if (mounted) {
        Navigator.of(context).pop();
        ShadToast.show(
          context,
          title: 'Profile Updated',
          message: 'Contractor details saved and applied to PDF report headers.',
          variant: ShadToastVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToast.show(
          context,
          title: 'Save Failed',
          message: 'Unable to save profile: $e',
          variant: ShadToastVariant.destructive,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return KeyboardDismissible(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tokens.muted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.business_outlined, color: tokens.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contractor & Business Profile', style: tokens.typography.h4),
                        const SizedBox(height: 2),
                        Text(
                          'Displayed on exported PDF statements and reports',
                          style: tokens.typography.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Business Name
              ShadInput(
                label: 'Business / Contractor Name',
                hint: 'e.g. BuildLedger Construction (Pvt) Ltd',
                controller: _nameController,
                focusNode: _nameFocusNode,
                prefixIcon: const Icon(Icons.apartment),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.organizationName],
                onFieldSubmitted: (_) => _taxIdFocusNode.requestFocus(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Company or contractor name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // NTN / Tax ID
              ShadInput(
                label: 'NTN / Tax ID',
                hint: 'e.g. 7492019-3',
                controller: _taxIdController,
                focusNode: _taxIdFocusNode,
                prefixIcon: const Icon(Icons.badge_outlined),
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
              ),
              const SizedBox(height: 14),

              // Contact Phone
              ShadInput(
                label: 'Contact Phone',
                hint: '0300-1234567',
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
              ),
              const SizedBox(height: 14),

              // Email
              ShadInput(
                label: 'Email',
                hint: 'info@site.com',
                controller: _emailController,
                focusNode: _emailFocusNode,
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onFieldSubmitted: (_) => _addressFocusNode.requestFocus(),
              ),
              const SizedBox(height: 14),

              // Address
              ShadInput(
                label: 'Site Office / Billing Address',
                hint: 'e.g. Plot 42, Sector G-11, Islamabad',
                controller: _addressController,
                focusNode: _addressFocusNode,
                prefixIcon: const Icon(Icons.place_outlined),
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.postalAddress],
                onFieldSubmitted: (_) => _handleSave(),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      label: 'Cancel',
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadButton(
                      label: 'Save Profile',
                      isLoading: _isSaving,
                      onPressed: _handleSave,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
