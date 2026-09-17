import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/states/empty_state.dart';
export 'package:build_ledger/shared/ui/states/empty_state.dart';

/// Compatibility wrapper delegating directly to [ShadEmptyState].
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    return ShadEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      customAction: customAction,
    );
  }
}
