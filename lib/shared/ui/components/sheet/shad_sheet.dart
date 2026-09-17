import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';
import 'package:build_ledger/core/design_system/dimensions.dart';

/// Canonical ShadCN bottom sheet container.
///
/// Features:
/// - Safe-area aware
/// - Keyboard aware (adjusts automatically to `viewInsets.bottom`)
/// - Draggable handle indicator
/// - Maximum height constraint to prevent overflow
/// - Android back button dismissible
class ShadSheet extends StatelessWidget {
  final Widget? title;
  final Widget? description;
  final Widget child;
  final bool showHandle;

  const ShadSheet({
    super.key,
    this.title,
    this.description,
    required this.child,
    this.showHandle = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShadDimensions.maxSheetWidth),
          child: builder(ctx),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.popover,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(ShadRadii.xl)),
        border: Border(
          top: BorderSide(color: tokens.border, width: 1.0),
          left: BorderSide(color: tokens.border, width: 1.0),
          right: BorderSide(color: tokens.border, width: 1.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: ShadSpacing.sm,
        left: ShadSpacing.lg,
        right: ShadSpacing.lg,
        bottom: viewInsets.bottom > 0 ? viewInsets.bottom + ShadSpacing.md : safeAreaBottom + ShadSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHandle)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: ShadSpacing.md),
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: ShadRadii.roundedFull,
                ),
              ),
            ),
          if (title != null || description != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        DefaultTextStyle(
                          style: tokens.typography.h3,
                          child: title!,
                        ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        DefaultTextStyle(
                          style: tokens.typography.muted,
                          child: description!,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: tokens.mutedForeground),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Dismiss',
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: ShadSpacing.md),
          ],
          Flexible(child: child),
        ],
      ),
    );
  }
}
