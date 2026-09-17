import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/states/loading_state.dart';
export 'package:build_ledger/shared/ui/states/loading_state.dart';

/// Compatibility wrapper delegating directly to [ShadLoadingState].
class AppLoadingState extends StatelessWidget {
  final String? message;

  const AppLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return ShadLoadingState(message: message);
  }
}
