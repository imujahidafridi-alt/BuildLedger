import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:build_ledger/core/design_system/theme.dart';
import 'package:build_ledger/features/settings/presentation/screens/settings_screen.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/contractor_profile_sheet.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/database_diagnostics_sheet.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/about_system_dialog.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:build_ledger/features/labour/presentation/controllers/labour_controller.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/labour/domain/entities/labour_entry.dart';
import 'package:build_ledger/features/settings/domain/entities/database_diagnostics.dart';
import 'package:build_ledger/features/settings/presentation/controllers/settings_controller.dart';
import 'package:build_ledger/shared/ui/components/theme_toggle_button.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const testDiagnostics = DatabaseDiagnostics(
    fileSizeBytes: 204800,
    sqliteVersion: '3.39.2',
    journalMode: 'wal',
    databasePath: '/data/user/0/com.buildledger/databases/build_ledger.db',
    projectCount: 3,
    expenseCount: 25,
    supplierCount: 8,
    labourCount: 12,
    categoryCount: 6,
  );

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        suppliersListProvider.overrideWith((ref) => Future.value(<Supplier>[])),
        labourEntriesProvider.overrideWith((ref) => Future.value(<LabourEntry>[])),
        databaseDiagnosticsProvider.overrideWith((ref) => Future.value(testDiagnostics)),
      ],
      child: MaterialApp(
        theme: ShadTheme.darkTheme,
        home: const SettingsScreen(),
      ),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('SettingsScreen UX Remediation Tests', () {
    testWidgets('Renders unified More title and removes duplicate AppBar theme toggle', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Title is "More"
      expect(find.text('More'), findsOneWidget);

      // Verify NO ThemeToggleButton in AppBar
      expect(find.descendant(of: find.byType(AppBar), matching: find.byType(ThemeToggleButton)), findsNothing);

      // Verify NO duplicate Reports row
      expect(find.text('Reports & Export'), findsNothing);
    });

    testWidgets('Renders all 4 grouped sections and contractor profile card', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Profile card
      expect(find.text('Set Up Contractor Profile'), findsOneWidget);

      // 2. Operational Section
      expect(find.text('OPERATIONAL'), findsOneWidget);
      expect(find.text('Suppliers & Vendor Ledgers'), findsOneWidget);
      expect(find.text('Site Labour & Shift Wage Payouts'), findsOneWidget);

      // 3. Preferences Section
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Base Currency'), findsOneWidget);
      expect(find.text('Standard Labour Shift'), findsOneWidget);

      // 4. Data & Security Section
      expect(find.text('DATA & SECURITY'), findsOneWidget);
      expect(find.text('Encrypted Backup & Restore'), findsOneWidget);
      expect(find.text('Storage & Local Database'), findsOneWidget);

      // 5. About & System Section
      expect(find.text('ABOUT & SYSTEM'), findsOneWidget);
      expect(find.text('Design System Gallery'), findsOneWidget);
      expect(find.text('BuildLedger'), findsOneWidget);
    });

    testWidgets('Tapping Contractor Profile card opens ContractorProfileSheet', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set Up Contractor Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(ContractorProfileSheet), findsOneWidget);
      expect(find.text('Contractor & Business Profile'), findsOneWidget);
      expect(find.text('Business / Contractor Name'), findsOneWidget);
    });

    testWidgets('Tapping Storage & Local Database opens DatabaseDiagnosticsSheet', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Storage & Local Database'));
      await tester.pumpAndSettle();

      expect(find.byType(DatabaseDiagnosticsSheet), findsOneWidget);
      expect(find.text('Storage & Database Diagnostics'), findsOneWidget);
    });

    testWidgets('Tapping BuildLedger opens AboutSystemDialog', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('BuildLedger'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutSystemDialog), findsOneWidget);
      expect(find.text('About BuildLedger'), findsOneWidget);
      expect(find.text('Copy System Info'), findsOneWidget);
    });
  });
}
