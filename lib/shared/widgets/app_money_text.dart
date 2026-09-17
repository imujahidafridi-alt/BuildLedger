import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/shared/ui/financial/money_text.dart';
export 'package:build_ledger/shared/ui/financial/money_text.dart';

/// Compatibility wrapper delegating directly to [MoneyText].
class AppMoneyText extends StatelessWidget {
  final Money money;
  final MoneyTextStyle style;
  final MoneySemanticColor semanticColor;
  final bool isCompact;
  final bool showPrefix;
  final bool forceDecimals;

  const AppMoneyText(
    this.money, {
    super.key,
    this.style = MoneyTextStyle.body,
    this.semanticColor = MoneySemanticColor.neutral,
    this.isCompact = false,
    this.showPrefix = true,
    this.forceDecimals = false,
  });

  @override
  Widget build(BuildContext context) {
    return MoneyText(
      money,
      style: style,
      semanticColor: semanticColor,
      compact: isCompact,
    );
  }
}
