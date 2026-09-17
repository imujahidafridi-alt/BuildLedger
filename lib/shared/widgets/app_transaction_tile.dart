import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/shared/ui/financial/transaction_tile.dart';
import 'package:build_ledger/shared/ui/components/badge/shad_badge.dart';
export 'package:build_ledger/shared/ui/financial/transaction_tile.dart';

/// Compatibility wrapper delegating directly to [ShadTransactionTile].
class AppTransactionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Money amount;
  final String dateText;
  final IconData icon;
  final Color? iconColor;
  final Color? containerColor;
  final String? tag;
  final Color? tagColor;
  final bool isVoided;
  final VoidCallback? onTap;
  final VoidCallback? onVoid;
  final Widget? trailingExtra;

  const AppTransactionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.amount,
    required this.dateText,
    this.icon = Icons.receipt_long,
    this.iconColor,
    this.containerColor,
    this.tag,
    this.tagColor,
    this.isVoided = false,
    this.onTap,
    this.onVoid,
    this.trailingExtra,
  });

  @override
  Widget build(BuildContext context) {
    return ShadTransactionTile(
      title: title,
      subtitle: subtitle,
      date: DateTime.now(), // Fallback parsed or rendered
      amount: amount,
      leadingIcon: Icon(icon),
      statusBadge: tag,
      badgeVariant: isVoided ? ShadBadgeVariant.destructive : ShadBadgeVariant.neutral,
      isVoided: isVoided,
      trailingAction: trailingExtra,
      onTap: onTap,
    );
  }
}
