import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';

/// Restrained loading indicator with an optional status message.
class ShadLoadingState extends StatelessWidget {
  final String? message;

  const ShadLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: tokens.typography.muted,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
