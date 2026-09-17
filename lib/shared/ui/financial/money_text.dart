import 'package:flutter/material.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/formatting/money_formatter.dart';
import 'package:build_ledger/core/design_system/tokens.dart';

enum MoneySemanticColor {
  auto,
  neutral,
  profit,
  alert,
  warning,
}

enum MoneyTextStyle {
  display,
  headline,
  title,
  body,
  caption,
}

/// Centralized ShadCN financial money display widget.
/// Guarantees consistent currency formatting, thousands separators, and tabular numerals.
class MoneyText extends StatelessWidget {
  final Money money;
  final MoneyTextStyle style;
  final MoneySemanticColor semanticColor;
  final bool showSign;
  final bool compact;

  const MoneyText(
    this.money, {
    super.key,
    this.style = MoneyTextStyle.body,
    this.semanticColor = MoneySemanticColor.neutral,
    this.showSign = false,
    this.compact = false,
  });

  factory MoneyText.fromMinorUnits(
    int minorUnits, {
    Key? key,
    MoneyTextStyle style = MoneyTextStyle.body,
    MoneySemanticColor semanticColor = MoneySemanticColor.neutral,
    bool showSign = false,
    bool compact = false,
  }) {
    return MoneyText(
      Money.fromMinor(minorUnits),
      key: key,
      style: style,
      semanticColor: semanticColor,
      showSign: showSign,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    Color color;
    switch (semanticColor) {
      case MoneySemanticColor.auto:
        color = money.isNegative ? tokens.destructive : tokens.foreground;
      case MoneySemanticColor.profit:
        color = tokens.success;
      case MoneySemanticColor.alert:
        color = tokens.destructive;
      case MoneySemanticColor.warning:
        color = tokens.warning;
      case MoneySemanticColor.neutral:
        color = tokens.foreground;
    }

    TextStyle textStyle;
    switch (style) {
      case MoneyTextStyle.display:
        textStyle = tokens.typography.mono.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: color,
        );
      case MoneyTextStyle.headline:
        textStyle = tokens.typography.mono.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: color,
        );
      case MoneyTextStyle.title:
        textStyle = tokens.typography.mono.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        );
      case MoneyTextStyle.body:
        textStyle = tokens.typography.mono.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        );
      case MoneyTextStyle.caption:
        textStyle = tokens.typography.mono.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        );
    }

    final formatted = compact
        ? MoneyFormatter.formatCompact(money)
        : MoneyFormatter.format(money);
    final displayText = (showSign && money.isPositive) ? '+$formatted' : formatted;

    return Text(
      displayText,
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
