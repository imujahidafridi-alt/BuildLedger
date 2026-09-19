import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/settings/domain/entities/contractor_profile.dart';
import 'package:build_ledger/features/settings/presentation/controllers/settings_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Professional first-time onboarding sheet for new contractors.
/// Prompts newly installed clients to enter their business name, NTN, and contact info
/// so generated PDF statements, payment vouchers, and expense sheets are official and branded.
class WelcomeContractorSheet extends ConsumerStatefulWidget {
  const WelcomeContractorSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return ShadSheet.show<bool>(
      context: context,
      builder: (context) => const ShadSheet(
        child: WelcomeContractorSheet(),
      ),
    );
  }

  @override
  ConsumerState<WelcomeContractorSheet> createState() => _WelcomeContractorSheetState();
}

class _WelcomeContractorSheetState extends ConsumerState<WelcomeContractorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _taxIdFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    _nameFocusNode.dispose();
    _taxIdFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final profile = ContractorProfile(
        name: _nameController.text.trim(),
        taxId: _taxIdController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      await ref.read(contractorProfileProvider.notifier).saveProfile(profile);
      await ref.read(appSettingsRepositoryProvider).setSeenProfileOnboarding(true);

      if (mounted) {
        Navigator.of(context).pop(true);
        ShadToast.show(
          context,
          title: 'Welcome to BuildLedger!',
          message: 'Profile registered. Exported PDF reports are now branded with your firm name.',
          variant: ShadToastVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToast.show(
          context,
          title: 'Save Failed',
          message: 'Could not save profile: $e',
          variant: ShadToastVariant.destructive,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSkip() async {
    await ref.read(appSettingsRepositoryProvider).setSeenProfileOnboarding(true);
    if (mounted) {
      Navigator.of(context).pop(false);
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
              // Header Badge & Intro
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tokens.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tokens.primary.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Icon(Icons.apartment, color: tokens.primary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Welcome to BuildLedger',
                                style: tokens.typography.h3.copyWith(fontSize: 18),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const ShadBadge(
                              label: 'INITIAL SETUP',
                              variant: ShadBadgeVariant.warning,
                              isSmall: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure contractor profile for official PDF reports',
                          style: tokens.typography.small.copyWith(color: tokens.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: tokens.border, height: 1),
              const SizedBox(height: 16),

              // Form Inputs
              ShadInput(
                controller: _nameController,
                focusNode: _nameFocusNode,
                label: 'Business / Contractor Name',
                hint: 'e.g. BuildLedger Construction (Pvt) Ltd',
                prefixIcon: Icon(Icons.domain, size: 18, color: tokens.mutedForeground),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Company or contractor name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ShadInput(
                controller: _taxIdController,
                focusNode: _taxIdFocusNode,
                label: 'NTN / Tax ID (Optional)',
                hint: 'e.g. 7492019-3',
                prefixIcon: Icon(Icons.badge_outlined, size: 18, color: tokens.mutedForeground),
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              ShadInput(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                label: 'Contact Phone (Optional)',
                hint: 'e.g. 0300-1234567',
                prefixIcon: Icon(Icons.phone_outlined, size: 18, color: tokens.mutedForeground),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              ShadInput(
                controller: _addressController,
                focusNode: _addressFocusNode,
                label: 'Site Office / Billing Address (Optional)',
                hint: 'e.g. Plot 42, Sector G-11, Islamabad',
                prefixIcon: Icon(Icons.location_on_outlined, size: 18, color: tokens.mutedForeground),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSave(),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ShadButton.ghost(
                      label: 'Skip',
                      onPressed: _isSaving ? null : _handleSkip,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: ShadButton(
                      label: _isSaving ? 'Saving...' : 'Save Profile',
                      icon: _isSaving ? const Icon(Icons.hourglass_empty, size: 18) : const Icon(Icons.check, size: 18),
                      variant: ShadButtonVariant.primary,
                      onPressed: _isSaving ? null : _handleSave,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
