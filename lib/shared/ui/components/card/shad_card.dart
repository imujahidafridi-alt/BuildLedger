import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/spacing.dart';

/// Canonical ShadCN card component.
/// Provides structured subcomponents: Header, Title, Description, Content, Footer.
class ShadCard extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const ShadCard({
    super.key,
    this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final bg = backgroundColor ?? tokens.card;
    final border = borderColor ?? tokens.border;

    Widget cardBox = Container(
      padding: padding ?? ShadSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: ShadRadii.roundedLg,
        border: Border.all(color: border, width: 1.0),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: ShadRadii.roundedLg,
        child: InkWell(
          borderRadius: ShadRadii.roundedLg,
          onTap: onTap,
          child: cardBox,
        ),
      );
    }

    return cardBox;
  }
}

class ShadCardHeader extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? description;
  final Widget? trailing;

  const ShadCardHeader({
    super.key,
    this.leading,
    this.title,
    this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ShadSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                ?title,
                if (description != null) ...[
                  const SizedBox(height: 2),
                  description!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: ShadSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class ShadCardTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const ShadCardTitle(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    return Text(
      text,
      style: style ?? tokens.typography.h3,
    );
  }
}

class ShadCardDescription extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const ShadCardDescription(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    return Text(
      text,
      style: style ?? tokens.typography.muted,
    );
  }
}

class ShadCardContent extends StatelessWidget {
  final Widget child;

  const ShadCardContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class ShadCardFooter extends StatelessWidget {
  final Widget child;

  const ShadCardFooter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ShadSpacing.md),
      child: child,
    );
  }
}
