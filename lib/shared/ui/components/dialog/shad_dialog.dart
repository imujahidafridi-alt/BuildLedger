import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/core/design_system/dimensions.dart';
import 'package:build_ledger/shared/ui/components/button/shad_button.dart';

/// Base modal dialog container with ShadCN styling.
class ShadDialog extends StatelessWidget {
  final Widget? title;
  final Widget? description;
  final Widget? content;
  final List<Widget>? actions;

  const ShadDialog({
    super.key,
    this.title,
    this.description,
    this.content,
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShadDimensions.maxDialogWidth),
          child: builder(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return Container(
      padding: ShadSpacing.cardPadding,
      decoration: BoxDecoration(
        color: tokens.popover,
        borderRadius: ShadRadii.roundedLg,
        border: Border.all(color: tokens.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            DefaultTextStyle(
              style: tokens.typography.h3,
              child: title!,
            ),
            const SizedBox(height: 6),
          ],
          if (description != null) ...[
            DefaultTextStyle(
              style: tokens.typography.muted,
              child: description!,
            ),
            const SizedBox(height: 16),
          ],
          if (content != null) ...[
            content!,
            const SizedBox(height: 20),
          ],
          if (actions != null && actions!.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (int i = 0; i < actions!.length; i++) ...[
                  actions![i],
                  if (i < actions!.length - 1) const SizedBox(width: ShadSpacing.sm),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// Specialized confirmation dialog communicating consequence and actions.
class ShadConfirmDialog extends StatelessWidget {
  final String title;
  final String consequence;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const ShadConfirmDialog({
    super.key,
    required this.title,
    String? consequence,
    String? message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
  }) : consequence = consequence ?? message ?? '';

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? consequence,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final effectiveConsequence = consequence ?? message ?? '';
    final result = await ShadDialog.show<bool>(
      context: context,
      builder: (ctx) => ShadConfirmDialog(
        title: title,
        consequence: effectiveConsequence,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text(title),
      description: Text(consequence),
      actions: [
        ShadButton.outline(
          label: cancelLabel,
          size: ShadButtonSize.small,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ShadButton(
          label: confirmLabel,
          variant: isDestructive ? ShadButtonVariant.destructive : ShadButtonVariant.primary,
          size: ShadButtonSize.small,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
