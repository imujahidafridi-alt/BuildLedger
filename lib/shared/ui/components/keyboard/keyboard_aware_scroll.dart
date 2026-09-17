import 'package:flutter/material.dart';

/// A keyboard-aware scroll container that automatically enables drag-to-dismiss
/// and ensures children are not obscured by the soft keyboard or system insets.
class KeyboardAwareScroll extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const KeyboardAwareScroll({
    super.key,
    required this.child,
    this.padding,
    this.physics,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      physics: physics ?? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: padding,
      child: child,
    );
  }
}
