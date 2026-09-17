import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';

/// Grouped section container with subtle borders and inset dividers.
/// Solves "card soup" by consolidating related configuration, metrics, or rows.
class ShadSection extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? trailing;
  final List<Widget> children;
  final bool showDividers;

  const ShadSection({
    super.key,
    this.title,
    this.description,
    this.trailing,
    required this.children,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || trailing != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: ShadSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: tokens.mutedForeground,
                        ),
                      ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: tokens.typography.muted,
                      ),
                    ],
                  ],
                ),
                ?trailing,
              ],
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: ShadRadii.roundedLg,
            border: Border.all(color: tokens.border, width: 1.0),
          ),
          child: ClipRRect(
            borderRadius: ShadRadii.roundedLg,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (showDividers && i < children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: ShadSpacing.lg,
                      color: tokens.border,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A standardized row item for use inside a [ShadSection].
class ShadSectionItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ShadSectionItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ShadSpacing.lg, vertical: ShadSpacing.md),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: ShadSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: tokens.typography.p.copyWith(fontWeight: FontWeight.w500),
                        child: title,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        DefaultTextStyle(
                          style: tokens.typography.muted,
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: ShadSpacing.sm),
                  trailing!,
                ] else if (onTap != null) ...[
                  const SizedBox(width: ShadSpacing.sm),
                  Icon(Icons.chevron_right, size: 18, color: tokens.mutedForeground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
