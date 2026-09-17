import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';

/// Clean hairline separator conforming to ShadCN border tokens.
class ShadSeparator extends StatelessWidget {
  final Axis orientation;
  final double thickness;
  final EdgeInsetsGeometry? margin;

  const ShadSeparator({
    super.key,
    this.orientation = Axis.horizontal,
    this.thickness = 1.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    Widget sep = Container(
      width: orientation == Axis.vertical ? thickness : double.infinity,
      height: orientation == Axis.horizontal ? thickness : double.infinity,
      color: tokens.border,
    );

    if (margin != null) {
      sep = Padding(padding: margin!, child: sep);
    }

    return sep;
  }
}
