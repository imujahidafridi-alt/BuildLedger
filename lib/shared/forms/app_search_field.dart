import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/forms/shad_search_input.dart';
export 'package:build_ledger/shared/ui/forms/shad_search_input.dart';

/// Compatibility wrapper delegating directly to [ShadSearchInput].
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShadSearchInput(
      controller: controller,
      hintText: hint,
      onChanged: onChanged,
      onClear: onClear,
      autofocus: autofocus,
    );
  }
}
