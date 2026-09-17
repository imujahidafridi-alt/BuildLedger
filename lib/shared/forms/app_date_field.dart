import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/forms/shad_date_input.dart';
export 'package:build_ledger/shared/ui/forms/shad_date_input.dart';

/// Compatibility wrapper delegating directly to [ShadDateInput].
class AppDateField extends StatelessWidget {
  final String label;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final IconData? prefixIcon;
  final String? Function(DateTime?)? validator;

  const AppDateField({
    super.key,
    this.label = 'Date',
    required this.selectedDate,
    required this.onDateChanged,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.prefixIcon = Icons.calendar_today_outlined,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ShadDateInput(
      label: label,
      selectedDate: selectedDate,
      onDateChanged: onDateChanged,
      firstDate: firstDate,
      lastDate: lastDate,
      enabled: enabled,
    );
  }
}
