import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/states/error_state.dart';
export 'package:build_ledger/shared/ui/states/error_state.dart';

/// Compatibility wrapper delegating directly to [ShadErrorState].
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String title;
  final String retryLabel;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Unable to Load Data',
    this.retryLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return ShadErrorState(
      title: title,
      message: message,
      onRetry: onRetry,
      retryLabel: retryLabel,
    );
  }
}
