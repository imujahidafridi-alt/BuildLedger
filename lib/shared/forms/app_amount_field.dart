import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/shared/ui/forms/shad_amount_input.dart';
export 'package:build_ledger/shared/ui/forms/shad_amount_input.dart';

/// Compatibility wrapper delegating directly to [ShadAmountInput].
class AppAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<Money>? onChanged;
  final ValueChanged<int>? onMinorUnitsChanged;
  final String? Function(String?)? validator;

  const AppAmountField({
    super.key,
    required this.controller,
    this.label = 'Amount',
    this.hint = '0.00',
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onMinorUnitsChanged,
    this.validator,
  });

  static int parseToMinorUnits(String text) => ShadAmountInput.parseToMinorUnits(text);

  @override
  Widget build(BuildContext context) {
    return ShadAmountInput(
      controller: controller,
      label: label,
      hint: hint,
      autofocus: autofocus,
      validator: validator,
      onChangedMinorUnits: onMinorUnitsChanged,
      onChanged: (val) {
        if (onChanged != null) {
          onChanged!(Money.fromMinor(parseToMinorUnits(val)));
        }
      },
    );
  }
}
