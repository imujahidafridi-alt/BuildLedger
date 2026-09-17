import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/dimensions.dart';

enum ShadButtonVariant {
  primary,
  secondary,
  outline,
  tonal,
  destructive,
  ghost,
  link,
}

enum ShadButtonSize {
  small,
  medium,
  large;

  static const sm = ShadButtonSize.small;
  static const md = ShadButtonSize.medium;
  static const lg = ShadButtonSize.large;
  static const defaultSize = ShadButtonSize.medium;
}

/// Canonical ShadCN button component for BuildLedger.
///
/// Features:
/// - 7 variants (primary, secondary, outline, tonal, destructive, ghost, link)
/// - 3 standardized sizes (small, medium, large)
/// - Loading indicator with stroke matching text
/// - Strict 48x48dp interactive touch target on all sizes
/// - Primary variant guarantees high-contrast Amber (#F59E0B) with dark text (#0B0F17)
class ShadButton extends StatelessWidget {
  final String? label;
  final dynamic icon;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final VoidCallback? onPressed;
  final ShadButtonVariant variant;
  final ShadButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final String? tooltip;

  const ShadButton({
    super.key,
    this.label,
    this.icon,
    this.leadingIcon,
    this.trailingIcon,
    required this.onPressed,
    this.variant = ShadButtonVariant.primary,
    this.size = ShadButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.tooltip,
  });

  const ShadButton.destructive({
    super.key,
    this.label,
    this.icon,
    this.leadingIcon,
    this.trailingIcon,
    required this.onPressed,
    this.size = ShadButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.tooltip,
  }) : variant = ShadButtonVariant.destructive;

  const ShadButton.outline({
    super.key,
    this.label,
    this.icon,
    this.leadingIcon,
    this.trailingIcon,
    required this.onPressed,
    this.size = ShadButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.tooltip,
  }) : variant = ShadButtonVariant.outline;

  const ShadButton.ghost({
    super.key,
    this.label,
    this.icon,
    this.leadingIcon,
    this.trailingIcon,
    required this.onPressed,
    this.size = ShadButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.tooltip,
  }) : variant = ShadButtonVariant.ghost;

  double get _height {
    switch (size) {
      case ShadButtonSize.small:
        return ShadDimensions.buttonHeightSm;
      case ShadButtonSize.medium:
        return ShadDimensions.buttonHeightMd;
      case ShadButtonSize.large:
        return ShadDimensions.buttonHeightLg;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case ShadButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 10);
      case ShadButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16);
      case ShadButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 22);
    }
  }

  double get _fontSize {
    switch (size) {
      case ShadButtonSize.small:
        return 12.0;
      case ShadButtonSize.medium:
        return 14.0;
      case ShadButtonSize.large:
        return 15.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case ShadButtonVariant.primary:
        bg = tokens.primary;
        fg = tokens.primaryForeground;
        break;
      case ShadButtonVariant.secondary:
        bg = tokens.secondary;
        fg = tokens.secondaryForeground;
        break;
      case ShadButtonVariant.outline:
        bg = Colors.transparent;
        fg = tokens.foreground;
        borderSide = BorderSide(
          color: tokens.brightness == Brightness.dark
              ? const Color(0xFF374151)
              : tokens.border,
          width: 1,
        );
        break;
      case ShadButtonVariant.tonal:
        bg = tokens.muted;
        fg = tokens.foreground;
        break;
      case ShadButtonVariant.destructive:
        bg = tokens.destructive;
        fg = tokens.destructiveForeground;
        break;
      case ShadButtonVariant.ghost:
        bg = Colors.transparent;
        fg = tokens.foreground;
        break;
      case ShadButtonVariant.link:
        bg = Colors.transparent;
        fg = tokens.primary;
        break;
    }

    if (!isEnabled && variant != ShadButtonVariant.ghost && variant != ShadButtonVariant.link) {
      bg = bg.withValues(alpha: 0.45);
      fg = fg.withValues(alpha: 0.5);
    } else if (!isEnabled) {
      fg = fg.withValues(alpha: 0.4);
    }

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: _fontSize + 2,
            height: _fontSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          if (label != null) const SizedBox(width: 8),
        ] else ...[
          if (leadingIcon != null) ...[
            IconTheme(
              data: IconThemeData(color: fg, size: _fontSize + 2),
              child: leadingIcon!,
            ),
            if (label != null) const SizedBox(width: 8),
          ] else if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: fg, size: label != null ? _fontSize + 2 : _fontSize + 4),
              child: icon is Widget ? (icon as Widget) : (icon is IconData ? Icon(icon as IconData) : const SizedBox.shrink()),
            ),
            if (label != null) const SizedBox(width: 8),
          ],
        ],
        if (label != null)
          Text(
            label!,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: fg,
              decoration: variant == ShadButtonVariant.link ? TextDecoration.underline : null,
            ),
          ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 8),
          IconTheme(
            data: IconThemeData(color: fg, size: _fontSize + 2),
            child: trailingIcon!,
          ),
        ],
      ],
    );

    Widget visualButton = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: _height,
      padding: _padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: ShadRadii.roundedMd,
        border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
      ),
      child: Center(
        widthFactor: fullWidth ? 1.0 : null,
        child: content,
      ),
    );

    // Enforce 48x48dp minimum hit area for accessibility
    Widget interactive = ConstrainedBox(
      constraints: fullWidth
          ? const BoxConstraints(minHeight: ShadDimensions.minTouchTarget)
          : ShadDimensions.minTouchConstraints,
      child: Center(
        widthFactor: fullWidth ? 1.0 : null,
        child: Material(
          color: Colors.transparent,
          borderRadius: ShadRadii.roundedMd,
          child: InkWell(
            borderRadius: ShadRadii.roundedMd,
            onTap: isEnabled ? onPressed : null,
            child: visualButton,
          ),
        ),
      ),
    );

    if (fullWidth) {
      interactive = SizedBox(width: double.infinity, child: interactive);
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: interactive);
    }

    return interactive;
  }
}
