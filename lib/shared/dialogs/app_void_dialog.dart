import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/shared/ui/components/dialog/shad_dialog.dart';
import 'package:build_ledger/shared/ui/components/button/shad_button.dart';
import 'package:build_ledger/shared/ui/forms/shad_input.dart';

/// Explicit financial voiding dialog requiring a documented reason for audit logging.
class AppVoidDialog extends StatefulWidget {
  final String entityName; // e.g. "Expense" or "Labour Shift"

  const AppVoidDialog({super.key, required this.entityName});

  static Future<String?> show(BuildContext context, {required String entityName}) {
    return ShadDialog.show<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppVoidDialog(entityName: entityName),
    );
  }

  @override
  State<AppVoidDialog> createState() => _AppVoidDialogState();
}

class _AppVoidDialogState extends State<AppVoidDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _commonReasons = [
    'Duplicate entry',
    'Incorrect amount entered',
    'Wrong project selected',
    'Cancelled supplier transaction',
    'Entered under wrong category',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return ShadDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: tokens.destructive, size: 22),
          const SizedBox(width: 8),
          Text('Void ${widget.entityName}'),
        ],
      ),
      description: const Text(
        'This transaction will remain preserved in audit history but will be permanently excluded from all financial totals and budget calculations.',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'COMMON REASONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: tokens.mutedForeground,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _commonReasons.map((reason) {
                return Material(
                  color: tokens.muted,
                  borderRadius: ShadRadii.roundedMd,
                  child: InkWell(
                    borderRadius: ShadRadii.roundedMd,
                    onTap: () => setState(() => _reasonController.text = reason),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        reason,
                        style: TextStyle(fontSize: 11, color: tokens.foreground),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: _reasonController,
              label: 'Reason for Voiding *',
              hint: 'Describe reason for voiding...',
              maxLines: 2,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'A valid void reason is strictly required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        ShadButton.outline(
          label: 'Cancel',
          size: ShadButtonSize.small,
          onPressed: () => Navigator.of(context).pop(null),
        ),
        ShadButton(
          label: 'Void Record',
          variant: ShadButtonVariant.destructive,
          size: ShadButtonSize.small,
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_reasonController.text.trim());
            }
          },
        ),
      ],
    );
  }
}
