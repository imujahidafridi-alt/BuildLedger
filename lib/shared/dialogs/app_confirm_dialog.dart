import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/components/dialog/shad_dialog.dart';
export 'package:build_ledger/shared/ui/components/dialog/shad_dialog.dart';

/// Compatibility wrapper delegating directly to [ShadConfirmDialog].
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return ShadConfirmDialog.show(
      context,
      title: title,
      consequence: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadConfirmDialog(
      title: title,
      consequence: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    );
  }
}
