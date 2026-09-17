import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/components/button/shad_button.dart';
export 'package:build_ledger/shared/ui/components/button/shad_button.dart';

enum AppButtonVariant {
  primary,
  secondary,
  tonal,
  destructive,
  ghost,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

/// Compatibility wrapper delegating directly to [ShadButton].
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLeadingIcon;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLeadingIcon = true,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = false,
  });

  ShadButtonVariant get _shadVariant {
    switch (variant) {
      case AppButtonVariant.primary:
        return ShadButtonVariant.primary;
      case AppButtonVariant.secondary:
        return ShadButtonVariant.secondary;
      case AppButtonVariant.tonal:
        return ShadButtonVariant.tonal;
      case AppButtonVariant.destructive:
        return ShadButtonVariant.destructive;
      case AppButtonVariant.ghost:
        return ShadButtonVariant.ghost;
    }
  }

  ShadButtonSize get _shadSize {
    switch (size) {
      case AppButtonSize.small:
        return ShadButtonSize.small;
      case AppButtonSize.medium:
        return ShadButtonSize.medium;
      case AppButtonSize.large:
        return ShadButtonSize.large;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadButton(
      label: label,
      onPressed: isDisabled ? null : onPressed,
      variant: _shadVariant,
      size: _shadSize,
      leadingIcon: isLeadingIcon && icon != null ? Icon(icon) : null,
      trailingIcon: !isLeadingIcon && icon != null ? Icon(icon) : null,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }
}
