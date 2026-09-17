import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/radii.dart';
import 'package:build_ledger/core/design_system/dimensions.dart';

/// Segmented tab selector conforming to ShadCN visual language.
class ShadTabs<T> extends StatelessWidget {
  final List<T> values;
  final T selectedValue;
  final ValueChanged<T> onTabSelected;
  final String Function(T) labelBuilder;
  final Widget Function(T)? iconBuilder;
  final bool scrollable;

  const ShadTabs({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.onTabSelected,
    required this.labelBuilder,
    this.iconBuilder,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;

    final children = values.map((val) {
      final isSelected = val == selectedValue;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: ShadRadii.roundedMd,
          onTap: () => onTabSelected(val),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: ShadDimensions.buttonHeightSm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? tokens.card : Colors.transparent,
                borderRadius: ShadRadii.roundedMd,
                border: isSelected ? Border.all(color: tokens.border, width: 1) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconBuilder != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        size: 14,
                        color: isSelected ? tokens.primary : tokens.mutedForeground,
                      ),
                      child: iconBuilder!(val),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    labelBuilder(val),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? tokens.foreground : tokens.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();

    Widget container = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.muted,
        borderRadius: ShadRadii.roundedLg,
        border: Border.all(color: tokens.border, width: 1),
      ),
      child: scrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            )
          : Row(
              children: children.map((c) => Expanded(child: c)).toList(),
            ),
    );

    return container;
  }
}
