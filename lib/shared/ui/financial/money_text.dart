import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        textStyle = GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: color,
        );
      case MoneyTextStyle.headline:
        textStyle = GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: color,
        );
      case MoneyTextStyle.title:
        textStyle = GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: color,
        );
      case MoneyTextStyle.body:
        textStyle = GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        );
      case MoneyTextStyle.caption:
        textStyle = GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        );
    }

    final formatted = compact
        ? MoneyFormatter.formatCompact(money)
        : MoneyFormatter.format(money);
    final displayText = (showSign && money.isPositive) ? '+$formatted' : formatted;

    String sign = '';
    String remainder = displayText;
    if (remainder.startsWith('+')) {
      sign = '+';
      remainder = remainder.substring(1);
    } else if (remainder.startsWith('-')) {
      sign = '-';
      remainder = remainder.substring(1);
    }

    final prefix = '${MoneyFormatter.currencySymbol} ';
    final hasPrefix = remainder.startsWith(prefix);
    final numberPart = hasPrefix ? remainder.substring(prefix.length) : remainder;

    return Text.rich(
      TextSpan(
        style: textStyle,
        children: [
          if (sign.isNotEmpty)
            TextSpan(
              text: sign,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          if (hasPrefix)
            TextSpan(
              text: prefix,
              style: TextStyle(
                fontSize: textStyle.fontSize != null ? textStyle.fontSize! * 0.88 : null,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.82),
                letterSpacing: -0.2,
              ),
            ),
          TextSpan(
            text: numberPart,
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
