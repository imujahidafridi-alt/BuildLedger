import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:build_ledger/app/theme/app_theme.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/core/database/transaction_runner.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/dashboard/data/datasources/dashboard_query_dao.dart';
import 'package:build_ledger/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:build_ledger/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/labour/data/repositories/labour_repository_impl.dart';
import 'package:build_ledger/features/labour/domain/entities/labour_entry.dart';
import 'package:build_ledger/features/projects/data/repositories/project_repository_impl.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/projects/presentation/screens/archived_projects_screen.dart';
import 'package:build_ledger/features/projects/presentation/screens/project_detail_screen.dart';
import 'package:build_ledger/features/projects/presentation/screens/project_list_screen.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

void main() {
  late Database db;
  late ProjectRepositoryImpl projectRepo;
  late ExpenseRepositoryImpl expenseRepo;
  late LabourRepositoryImpl labourRepo;
  late DashboardQueryDao dashboardDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await DatabaseHelper.createSchema(db, version);
          await DatabaseHelper.seedCategories(db);
        },
      ),
    );

    DatabaseHelper.setMockDatabase(db);
    final runner = TransactionRunner(DatabaseHelper());
    projectRepo = ProjectRepositoryImpl(dbHelper: DatabaseHelper(), transactionRunner: runner);
    expenseRepo = ExpenseRepositoryImpl(dbHelper: DatabaseHelper(), transactionRunner: runner);
    labourRepo = LabourRepositoryImpl(dbHelper: DatabaseHelper(), transactionRunner: runner);
    dashboardDao = DashboardQueryDao(DatabaseHelper());
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.setMockDatabase(null);
  });

  group('A. ProjectRepository Archive & Restore Queries', () {
    test('archiveProject updates status to archived, sets archived_at, and preserves ID', () async {
      final now = DateTime.now();
      final project = Project(
        id: 'proj-1',
        name: 'Villa Heights',
        clientName: 'Ahmed Khan',
        location: 'Hayatabad',
        budgetAmount: Money.fromMinor(10000000),
        createdAt: now,
        updatedAt: now,
      );

      await projectRepo.createProject(project);

      // Verify active query
      final activeInitial = (await projectRepo.getActiveProjects()).dataOrNull!;
      expect(activeInitial.length, 1);
      expect(activeInitial.first.id, 'proj-1');

      // Archive project
      final archiveResult = await projectRepo.archiveProject('proj-1');
      expect(archiveResult.isSuccess, true);

      // Verify active projects excludes archived
      final activeAfterArchive = (await projectRepo.getActiveProjects()).dataOrNull!;
      expect(activeAfterArchive, isEmpty);

      // Verify archived query includes project
      final archivedList = (await projectRepo.getArchivedProjects()).dataOrNull!;
      expect(archivedList.length, 1);
      final archivedProj = archivedList.first;
      expect(archivedProj.id, 'proj-1');
      expect(archivedProj.name, 'Villa Heights');
      expect(archivedProj.status, ProjectStatus.archived);
      expect(archivedProj.isArchived, true);
      expect(archivedProj.archivedAt, isNotNull);

      // Restore project
      final restoreResult = await projectRepo.restoreProject('proj-1');
      expect(restoreResult.isSuccess, true);

      // Verify active query includes restored project
      final activeAfterRestore = (await projectRepo.getActiveProjects()).dataOrNull!;
      expect(activeAfterRestore.length, 1);
      final restoredProj = activeAfterRestore.first;
      expect(restoredProj.id, 'proj-1');
      expect(restoredProj.status, ProjectStatus.active);
      expect(restoredProj.isArchived, false);
      expect(restoredProj.archivedAt, isNull);

      // Verify archived list is now empty
      final archivedAfterRestore = (await projectRepo.getArchivedProjects()).dataOrNull!;
      expect(archivedAfterRestore, isEmpty);
    });

    test('Audit log records PROJECT_ARCHIVED and PROJECT_RESTORED events', () async {
      final now = DateTime.now();
      final project = Project(
        id: 'proj-audit',
        name: 'Commercial Plaza',
        budgetAmount: Money.fromMinor(5000000),
        createdAt: now,
        updatedAt: now,
      );

      await projectRepo.createProject(project);
      await projectRepo.archiveProject('proj-audit');
      await projectRepo.restoreProject('proj-audit');

      final logs = await db.query(
        'audit_logs',
        where: 'entity_id = ?',
        whereArgs: ['proj-audit'],
        orderBy: 'timestamp ASC',
      );

      expect(logs.any((l) => l['action'] == 'archive'), true);
      expect(logs.any((l) => l['action'] == 'restore'), true);
    });

    test('Regression & Integrity: Child expenses and labour entries are 100% preserved through archive and restore', () async {
      final now = DateTime.now();
      final project = Project(
        id: 'proj-fin',
        name: 'Residency 101',
        budgetAmount: Money.fromMinor(2000000),
        createdAt: now,
        updatedAt: now,
      );
      await projectRepo.createProject(project);

      // Create an expense
      final expense = Expense(
        id: 'exp-1',
        projectId: 'proj-fin',
        categoryId: 'cat_top_site_earthwork',
        amount: Money.fromMinor(7500000), // 75,000 PKR
        paymentMethod: PaymentMethod.cash,
        expenseDate: now,
        description: 'Cement Bags',
        createdAt: now,
        updatedAt: now,
      );
      await expenseRepo.recordExpense(expense);

      // Create a labour entry
      final labour = LabourEntry(
        id: 'lab-1',
        projectId: 'proj-fin',
        workerName: 'Tariq Mehmood',
        role: 'Mason',
        rate: Money.fromMinor(250000),
        daysX100: 200, // 2 days = 5,000 PKR
        advance: Money.fromMinor(100000),
        netAmount: Money.fromMinor(400000),
        entryDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await labourRepo.recordLabourShift(labour);

      // Verify financial summary before archive
      final summaryBefore = await dashboardDao.getProjectFinancialSummary('proj-fin');
      expect(summaryBefore.actualCost.minorUnits, 7500000 + 400000);

      // Archive project
      await projectRepo.archiveProject('proj-fin');

      // Verify expenses and labour still exist and reference 'proj-fin'
      final expenseRows = await db.query('expenses', where: 'project_id = ?', whereArgs: ['proj-fin']);
      expect(expenseRows.length, 1);
      expect(expenseRows.first['id'], 'exp-1');

      final labourRows = await db.query('labour_entries', where: 'project_id = ?', whereArgs: ['proj-fin']);
      expect(labourRows.length, 1);
      expect(labourRows.first['id'], 'lab-1');

      // Summary remains identical even while archived!
      final summaryArchived = await dashboardDao.getProjectFinancialSummary('proj-fin');
      expect(summaryArchived.actualCost.minorUnits, summaryBefore.actualCost.minorUnits);

      // Restore project
      await projectRepo.restoreProject('proj-fin');

      // Summary remains identical after restore!
      final summaryRestored = await dashboardDao.getProjectFinancialSummary('proj-fin');
      expect(summaryRestored.actualCost.minorUnits, summaryBefore.actualCost.minorUnits);
      expect(summaryRestored.projectId, 'proj-fin');
    });
  });

  group('B. Provider & State Management (Riverpod)', () {
    testWidgets('Selected project gracefully switches away when active project is archived', (tester) async {
      final now = DateTime.now();
      final p1 = Project(
        id: 'proj-a',
        name: 'Project Alpha',
        budgetAmount: Money.fromMinor(1000000),
        createdAt: now,
        updatedAt: now,
      );
      final p2 = Project(
        id: 'proj-b',
        name: 'Project Beta',
        budgetAmount: Money.fromMinor(2000000),
        createdAt: now.add(const Duration(minutes: 1)),
        updatedAt: now.add(const Duration(minutes: 1)),
      );

      await projectRepo.createProject(p1);
      await projectRepo.createProject(p2);

      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepo),
        ],
      );
      addTearDown(container.dispose);

      // Load initial active projects
      final initialList = await container.read(projectsListProvider.future);
      expect(initialList.length, 2);

      // Selected project explicitly set to p1
      container.read(selectedProjectProvider.notifier).state = p1;
      expect(container.read(selectedProjectProvider)?.id, 'proj-a');

      // Archive Project Alpha
      final success = await container.read(projectControllerProvider.notifier).archiveProject('proj-a');
      expect(success, true);

      // Selected project automatically switched to Project Beta (the remaining active project)
      final activeListAfter = await container.read(projectsListProvider.future);
      expect(activeListAfter.length, 1);
      expect(activeListAfter.first.id, 'proj-b');

      final selectedAfter = container.read(selectedProjectProvider);
      expect(selectedAfter?.id, 'proj-b');
      expect(selectedAfter?.isArchived, false);

      // Archive Project Beta as well
      await container.read(projectControllerProvider.notifier).archiveProject('proj-b');

      final activeListEmpty = await container.read(projectsListProvider.future);
      expect(activeListEmpty, isEmpty);

      final selectedEmpty = container.read(selectedProjectProvider);
      expect(selectedEmpty, isNull);
    });
  });

  group('C. UI Screens: ArchivedProjectsScreen, ProjectDetailScreen & ProjectListScreen', () {
    testWidgets('ArchivedProjectsScreen renders empty state when no projects are archived', (tester) async {
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ArchivedProjectsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Archived Projects'), findsOneWidget);
      expect(find.text('No Archived Projects'), findsOneWidget);
      expect(find.textContaining('Projects you archive will appear here'), findsOneWidget);
    });

    testWidgets('ArchivedProjectsScreen renders archived project cards with details and restore action', (tester) async {
      final now = DateTime.now();
      final project = Project(
        id: 'proj-arch-ui',
        name: 'Hilltop Mansion',
        clientName: 'Suleman Dawood',
        location: 'Sector F-7',
        budgetAmount: Money.fromMinor(120000000), // 1.2M PKR
        createdAt: now,
        updatedAt: now,
      );
      await projectRepo.createProject(project);
      await projectRepo.archiveProject('proj-arch-ui');

      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepo),
          dashboardQueryDaoProvider.overrideWithValue(dashboardDao),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ArchivedProjectsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hilltop Mansion'), findsOneWidget);
      expect(find.text('Suleman Dawood'), findsOneWidget);
      expect(find.text('Sector F-7'), findsOneWidget);
      expect(find.text('ARCHIVED'), findsOneWidget);
      expect(find.text('BUDGET'), findsOneWidget);
      expect(find.text('RECORDED COST'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);

      // Tap Restore -> Should show ShadConfirmDialog
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(find.text('Restore Project'), findsOneWidget);
      expect(find.textContaining('It will become available again in the active project list'), findsOneWidget);

      // Confirm Restore
      final confirmButton = find.widgetWithText(ShadButton, 'Restore');
      await tester.tap(confirmButton.last);
      await tester.pumpAndSettle();

      // Project restored feedback
      expect(find.text('Project restored'), findsOneWidget);

      // Screen now shows empty state
      expect(find.text('No Archived Projects'), findsOneWidget);
    });

    testWidgets('ProjectDetailScreen shows ARCHIVED badge, restore action, and hides Add Expense when archived', (tester) async {
      final now = DateTime.now();
      final project = Project(
        id: 'proj-detail-test',
        name: 'Greenwood Plaza',
        budgetAmount: Money.fromMinor(5000000),
        createdAt: now,
        updatedAt: now,
      );
      await projectRepo.createProject(project);
      await projectRepo.archiveProject('proj-detail-test');

      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepo),
          dashboardQueryDaoProvider.overrideWithValue(dashboardDao),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProjectDetailScreen(projectId: 'proj-detail-test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ARCHIVED badge is visible
      expect(find.text('ARCHIVED'), findsOneWidget);

      // Add Expense button must be hidden for archived projects
      expect(find.text('Add Expense'), findsNothing);

      // Restore action is present in AppBar
      expect(find.byIcon(Icons.unarchive_outlined), findsOneWidget);
      expect(find.byIcon(Icons.archive_outlined), findsNothing);
    });

    testWidgets('ProjectListScreen renders AppBar archive icon and footer link to archived projects', (tester) async {
      final now = DateTime.now();
      final project = Project(
        id: 'proj-active-1',
        name: 'Active Tower',
        budgetAmount: Money.fromMinor(10000000),
        createdAt: now,
        updatedAt: now,
      );
      await projectRepo.createProject(project);

      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepo),
          dashboardQueryDaoProvider.overrideWithValue(dashboardDao),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ProjectListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // AppBar archive button
      expect(find.byIcon(Icons.archive_outlined), findsWidgets);

      // Project card rendered
      expect(find.text('Active Tower'), findsOneWidget);

      // Footer link rendered
      expect(find.text('View Archived Projects'), findsOneWidget);
    });
  });
}
