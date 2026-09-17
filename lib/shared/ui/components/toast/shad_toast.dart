import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';

enum ShadToastVariant {
  info,
  success,
  destructive,
  warning,
}

/// Unified ShadCN toast messenger.
/// Replaces standard floating SnackBar slabs with crisp, elevated toast banners.
class ShadToast {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ShadToastVariant variant = ShadToastVariant.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final scaffold = ScaffoldMessenger.maybeOf(context);
    if (scaffold == null) return;

    scaffold.hideCurrentSnackBar();

    final tokens = context.shad;

    Color borderCol;
    IconData iconData;
    Color iconCol;

    switch (variant) {
      case ShadToastVariant.success:
        borderCol = tokens.success;
        iconData = Icons.check_circle_outline;
        iconCol = tokens.success;
        break;
      case ShadToastVariant.destructive:
        borderCol = tokens.destructive;
        iconData = Icons.error_outline;
        iconCol = tokens.destructive;
        break;
      case ShadToastVariant.warning:
        borderCol = tokens.warning;
        iconData = Icons.warning_amber_rounded;
        iconCol = tokens.warning;
        break;
      case ShadToastVariant.info:
        borderCol = tokens.info;
        iconData = Icons.info_outline;
        iconCol = tokens.info;
        break;
    }

    scaffold.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: ShadSpacing.lg, vertical: ShadSpacing.md),
          decoration: BoxDecoration(
            color: tokens.popover,
            borderRadius: ShadRadii.roundedLg,
            border: Border.all(color: borderCol, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(iconData, size: 20, color: iconCol),
              const SizedBox(width: ShadSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: tokens.typography.h4.copyWith(fontSize: 14),
                      ),
                    Text(
                      message,
                      style: tokens.typography.p.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(width: ShadSpacing.sm),
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: tokens.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
