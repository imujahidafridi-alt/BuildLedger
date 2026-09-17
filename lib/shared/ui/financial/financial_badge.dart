import 'package:flutter/material.dart';
import 'package:build_ledger/shared/ui/components/badge/shad_badge.dart';

/// Pre-configured financial status badge helper.
class FinancialBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const FinancialBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  ShadBadgeVariant get _variant {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'SETTLED':
      case 'COMPLETED':
        return ShadBadgeVariant.success;
      case 'OUTSTANDING':
      case 'OVERDUE':
      case 'VOIDED':
        return ShadBadgeVariant.destructive;
      case 'PENDING':
      case 'PARTIAL':
        return ShadBadgeVariant.warning;
      case 'ACTIVE':
        return ShadBadgeVariant.info;
      default:
        return ShadBadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadBadge(
      label: status,
      variant: _variant,
      isSmall: isSmall,
    );
  }
}
