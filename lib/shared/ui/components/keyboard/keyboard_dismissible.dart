import 'package:flutter/material.dart';

/// Lightweight wrapper that dismisses the keyboard when the user taps outside
/// an active text input.
///
/// Uses [HitTestBehavior.translucent] to ensure that child buttons, dropdowns,
/// and interactive elements continue receiving their gestures without interference.
class KeyboardDismissible extends StatelessWidget {
  final Widget child;

  const KeyboardDismissible({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }
}
