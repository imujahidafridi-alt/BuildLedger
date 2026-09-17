import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/forms/shad_select.dart';
export 'package:build_ledger/shared/ui/forms/shad_select.dart';

/// Compatibility wrapper delegating directly to [ShadSelect].
class AppDropdown<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  const AppDropdown({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final shadItems = items.map((item) {
      String labelStr = item.value?.toString() ?? '';
      if (item.child is Text) {
        labelStr = (item.child as Text).data ?? labelStr;
      }
      return ShadSelectItem<T>(
        value: item.value as T,
        label: labelStr,
      );
    }).toList();

    return ShadSelect<T>(
      label: label,
      placeholder: hint ?? 'Select an option',
      value: value,
      items: shadItems,
      onChanged: onChanged,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
      validator: validator,
      enabled: enabled,
    );
  }
}
