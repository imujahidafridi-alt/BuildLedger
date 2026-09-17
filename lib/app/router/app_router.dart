import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/shared/components/app_scaffold.dart';
import 'package:build_ledger/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:build_ledger/features/projects/presentation/screens/project_list_screen.dart';
import 'package:build_ledger/features/projects/presentation/screens/project_form_screen.dart';
import 'package:build_ledger/features/projects/presentation/screens/project_detail_screen.dart';
import 'package:build_ledger/features/projects/presentation/screens/archived_projects_screen.dart';
import 'package:build_ledger/features/expenses/presentation/screens/expense_list_screen.dart';
import 'package:build_ledger/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:build_ledger/features/expenses/presentation/screens/quick_expense_screen.dart';
import 'package:build_ledger/features/expenses/presentation/screens/category_management_screen.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/suppliers/presentation/screens/supplier_list_screen.dart';
import 'package:build_ledger/features/suppliers/presentation/screens/supplier_detail_ledger_screen.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/labour/presentation/screens/labour_list_screen.dart';
import 'package:build_ledger/features/labour/presentation/screens/labour_shift_form_screen.dart';
import 'package:build_ledger/features/reports/presentation/screens/reports_hub_screen.dart';
import 'package:build_ledger/features/settings/presentation/screens/settings_screen.dart';
import 'package:build_ledger/features/settings/presentation/screens/backup_restore_screen.dart';

import 'package:build_ledger/shared/design_system/design_system_gallery_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        // 1. Dashboard Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),

        // 2. Projects Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/projects',
              builder: (context, state) => const ProjectListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const ProjectFormScreen(),
                ),
                GoRoute(
                  path: 'archived',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const ArchivedProjectsScreen(),
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return ProjectDetailScreen(projectId: id);
                  },
                ),
              ],
            ),
          ],
        ),

        // 3. Expenses Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              builder: (context, state) => const ExpenseListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const ExpenseFormScreen(),
                ),
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final expense = state.extra as Expense?;
                    return ExpenseFormScreen(initialExpense: expense);
                  },
                ),
                GoRoute(
                  path: 'quick',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const QuickExpenseScreen(),
                ),
              ],
            ),
          ],
        ),

        // 4. Reports Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsHubScreen(),
            ),
          ],
        ),

        // 5. More / Settings Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/more',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Sub-module Full Screen Routes
    GoRoute(
      path: '/suppliers',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SupplierListScreen(),
      routes: [
        GoRoute(
          path: ':id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final supplier = state.extra as Supplier?;
            return SupplierDetailLedgerScreen(supplierId: id, initialSupplier: supplier);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/labour',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LabourListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const LabourShiftFormScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/backup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BackupRestoreScreen(),
    ),
    GoRoute(
      path: '/categories',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CategoryManagementScreen(),
    ),
    GoRoute(
      path: '/design-system',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DesignSystemGalleryScreen(),
    ),
  ],
);
