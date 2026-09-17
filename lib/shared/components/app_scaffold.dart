import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/core/design_system/tokens.dart';
import 'package:build_ledger/shared/ui/navigation/shad_navigation_bar.dart';

/// Adaptive scaffold providing responsive navigation:
/// - Clean ShadNavigationBar on mobile
/// - Unobtrusive desktop/tablet navigation rail
class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.shad;
    final width = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = width >= 768;

    if (isTabletOrDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: tokens.background,
              indicatorColor: tokens.primary.withValues(alpha: 0.15),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _onNavigate(context, index),
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined, color: tokens.mutedForeground),
                  selectedIcon: Icon(Icons.dashboard, color: tokens.primary),
                  label: Text('Dashboard', style: TextStyle(color: tokens.foreground)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.apartment_outlined, color: tokens.mutedForeground),
                  selectedIcon: Icon(Icons.apartment, color: tokens.primary),
                  label: Text('Projects', style: TextStyle(color: tokens.foreground)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined, color: tokens.mutedForeground),
                  selectedIcon: Icon(Icons.receipt_long, color: tokens.primary),
                  label: Text('Expenses', style: TextStyle(color: tokens.foreground)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics_outlined, color: tokens.mutedForeground),
                  selectedIcon: Icon(Icons.analytics, color: tokens.primary),
                  label: Text('Reports', style: TextStyle(color: tokens.foreground)),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.more_horiz_outlined, color: tokens.mutedForeground),
                  selectedIcon: Icon(Icons.more_horiz, color: tokens.primary),
                  label: Text('More', style: TextStyle(color: tokens.foreground)),
                ),
              ],
            ),
            VerticalDivider(thickness: 1, width: 1, color: tokens.border),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ShadNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onNavigate(context, index),
        destinations: const [
          ShadNavDestination(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Dashboard',
          ),
          ShadNavDestination(
            icon: Icons.apartment_outlined,
            selectedIcon: Icons.apartment,
            label: 'Projects',
          ),
          ShadNavDestination(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: 'Expenses',
          ),
          ShadNavDestination(
            icon: Icons.analytics_outlined,
            selectedIcon: Icons.analytics,
            label: 'Reports',
          ),
          ShadNavDestination(
            icon: Icons.more_horiz_outlined,
            selectedIcon: Icons.more_horiz,
            label: 'More',
          ),
        ],
      ),
    );
  }

  void _onNavigate(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
