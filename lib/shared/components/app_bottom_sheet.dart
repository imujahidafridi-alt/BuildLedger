import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/components/sheet/shad_sheet.dart';
export 'package:build_ledger/shared/ui/components/sheet/shad_sheet.dart';

/// Compatibility wrapper delegating directly to [ShadSheet].
class AppBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AppBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget Function(BuildContext context) builder,
    Widget? trailing,
    bool isScrollControlled = true,
  }) {
    return ShadSheet.show<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      builder: (ctx) => ShadSheet(
        title: Text(title),
        description: subtitle != null ? Text(subtitle) : null,
        child: builder(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadSheet(
      title: Text(title),
      description: subtitle != null ? Text(subtitle!) : null,
      child: child,
    );
  }
}
