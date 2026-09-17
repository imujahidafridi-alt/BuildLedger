import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';

/// Canonical ShadCN outlined text input field.
class ShadInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? suffix;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final EdgeInsets scrollPadding;

  const ShadInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.scrollPadding = const EdgeInsets.only(top: 20, bottom: 96),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final effectiveTextInputAction = textInputAction ??
        (maxLines > 1 ? TextInputAction.newline : TextInputAction.next);

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
          initialValue: initialValue,
          validator: validator,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          autofocus: autofocus,
          focusNode: focusNode,
          textInputAction: effectiveTextInputAction,
          onFieldSubmitted: onFieldSubmitted,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          scrollPadding: scrollPadding,
          style: tokens.typography.p.copyWith(
            color: enabled ? tokens.foreground : tokens.mutedForeground,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            suffix: suffix,
            filled: true,
            fillColor: tokens.input,
            contentPadding: maxLines > 1
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
