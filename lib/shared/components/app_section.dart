import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/components/section/shad_section.dart';
export 'package:build_ledger/shared/ui/components/section/shad_section.dart';

/// Compatibility wrapper delegating directly to [ShadSection].
class AppSection extends StatelessWidget {
  final String? title;
  final Widget? action;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const AppSection({
    super.key,
    this.title,
    this.action,
    required this.children,
    this.margin = const EdgeInsets.only(bottom: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ShadSection(
        title: title,
        trailing: action,
        children: children,
      ),
    );
  }
}

/// Compatibility wrapper delegating directly to [ShadSectionItem].
class AppSectionItem extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? containerColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const AppSectionItem({
    super.key,
    this.icon,
    this.iconColor,
    this.containerColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget;
    if (icon != null) {
      if (containerColor != null) {
        leadingWidget = Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        );
      } else {
        leadingWidget = Icon(icon, size: 20, color: iconColor);
      }
    }

    return ShadSectionItem(
      leading: leadingWidget,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
