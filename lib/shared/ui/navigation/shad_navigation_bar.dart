import 'package:flutter/material.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/core/design_system/dimensions.dart';

class ShadNavDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const ShadNavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// Canonical ShadCN bottom navigation bar.
///
/// Distinct advantages over Material NavigationBar:
/// - No heavy pill/capsule background highlight
/// - Explicit active tinting on icon and label using primary token (Precision Amber)
/// - Strict touch targets (>=48dp)
/// - Subtle hairline top border
/// - Safe area integration
class ShadNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ShadNavDestination> destinations;

  const ShadNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(top: BorderSide(color: tokens.border, width: 1.0)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < destinations.length; i++) ...[
              Expanded(
                child: _ShadNavItem(
                  destination: destinations[i],
                  isSelected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShadNavItem extends StatelessWidget {
  final ShadNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShadNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final color = isSelected ? tokens.primary : tokens.mutedForeground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ShadDimensions.minTouchTarget),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? (destination.selectedIcon ?? destination.icon) : destination.icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  destination.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
