import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';

/// Canonical ShadCN financial amount input field.
///
/// Features:
/// - Distinct, non-colliding 'Rs' currency prefix
/// - Number keyboard with decimal precision
/// - Directly converts string input into deterministic integer minor units (paisas)
/// - Never introduces IEEE-754 floating-point drift
class ShadAmountInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final ValueChanged<int>? onChangedMinorUnits;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final EdgeInsets scrollPadding;

  const ShadAmountInput({
    super.key,
    this.controller,
    this.label = 'Amount',
    this.hint = '0.00',
    this.helperText,
    this.onChangedMinorUnits,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.scrollPadding = const EdgeInsets.only(top: 20, bottom: 96),
  });

  /// Deterministically parses user amount string into integer minor units (paisas).
  ///
  /// Examples:
  /// - "18500" -> 1850000
  /// - "18,500.50" -> 1850050
  /// - "0.05" -> 5
  static int parseToMinorUnits(String input) {
    final sanitized = input.replaceAll(',', '').trim();
    if (sanitized.isEmpty) return 0;

    final parts = sanitized.split('.');
    final wholeStr = parts[0];
    final whole = int.tryParse(wholeStr) ?? 0;

    int fraction = 0;
    if (parts.length > 1) {
      final fracStr = parts[1];
      if (fracStr.length == 1) {
        fraction = (int.tryParse(fracStr) ?? 0) * 10;
      } else if (fracStr.length >= 2) {
        fraction = int.tryParse(fracStr.substring(0, 2)) ?? 0;
      }
    }

    return (whole * 100) + fraction;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

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
        TextFormField(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          scrollPadding: scrollPadding,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\,?\d*\.?\d{0,2}')),
          ],
          style: tokens.typography.mono.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: enabled ? tokens.foreground : tokens.mutedForeground,
          ),
          onChanged: (val) {
            onChanged?.call(val);
            if (onChangedMinorUnits != null) {
              onChangedMinorUnits!(parseToMinorUnits(val));
            }
          },
          validator: validator ??
              (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Amount is required';
                }
                final minor = parseToMinorUnits(val);
                if (minor <= 0) {
                  return 'Amount must be greater than zero';
                }
                return null;
              },
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            filled: true,
            fillColor: tokens.input,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                'Rs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tokens.primary,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            hintStyle: tokens.typography.muted,
            helperStyle: tokens.typography.small.copyWith(color: tokens.mutedForeground),
            errorStyle: TextStyle(fontSize: 11, color: tokens.destructive),
            border: OutlineInputBorder(
              borderRadius: ShadRadii.roundedMd,
              borderSide: BorderSide(color: tokens.border, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: ShadRadii.roundedMd,
              borderSide: BorderSide(color: tokens.border, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: ShadRadii.roundedMd,
              borderSide: BorderSide(color: tokens.ring, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: ShadRadii.roundedMd,
              borderSide: BorderSide(color: tokens.destructive, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: ShadRadii.roundedMd,
              borderSide: BorderSide(color: tokens.destructive, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: ShadRadii.roundedMd,
              borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.5), width: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}
