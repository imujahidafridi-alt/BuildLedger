import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/formatting/date_formatter.dart';

/// Canonical ShadCN date field with identical geometry to [ShadInput].
class ShadDateInput extends StatelessWidget {
  final String? label;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? helperText;
  final String? errorText;

  const ShadDateInput({
    super.key,
    this.label,
    required this.selectedDate,
    required this.onDateChanged,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.helperText,
    this.errorText,
  });

  Future<void> _pickDate(BuildContext context) async {
    if (!enabled) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2035),
      builder: (context, child) {
        final tokens = context.shad;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: tokens.isDark
                ? ColorScheme.dark(
                    primary: tokens.primary,
                    onPrimary: tokens.primaryForeground,
                    surface: tokens.popover,
                    onSurface: tokens.foreground,
                    error: tokens.destructive,
                    onError: tokens.destructiveForeground,
                  )
                : ColorScheme.light(
                    primary: tokens.primary,
                    onPrimary: tokens.primaryForeground,
                    surface: tokens.popover,
                    onSurface: tokens.foreground,
                    error: tokens.destructive,
                    onError: tokens.destructiveForeground,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled ? tokens.foreground : tokens.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: ShadRadii.roundedMd,
            onTap: enabled ? () => _pickDate(context) : null,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: tokens.input,
                borderRadius: ShadRadii.roundedMd,
                border: Border.all(
                  color: hasError
                      ? tokens.destructive
                      : (enabled ? tokens.border : tokens.border.withValues(alpha: 0.5)),
                  width: hasError ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: enabled ? tokens.mutedForeground : tokens.border,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      DateFormatter.format(selectedDate),
                      style: tokens.typography.p.copyWith(
                        color: enabled ? tokens.foreground : tokens.mutedForeground,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: enabled ? tokens.mutedForeground : tokens.border,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: TextStyle(fontSize: 11, color: tokens.destructive),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: tokens.typography.small.copyWith(color: tokens.mutedForeground),
          ),
        ],
      ],
    );
  }
}
