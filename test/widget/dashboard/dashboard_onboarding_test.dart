import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:build_ledger/core/design_system/theme.dart';
import 'package:build_ledger/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/welcome_contractor_sheet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'buildledger_seen_profile_onboarding': true, // Avoid auto-popup in static view test
    });
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        projectsListProvider.overrideWith((ref) => Future.value(<Project>[])),
      ],
      child: MaterialApp(
        theme: ShadTheme.darkTheme,
        home: const DashboardScreen(),
      ),
    );
  }

  testWidgets('Dashboard empty state displays professional Getting Started onboarding flow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Welcome header
    expect(find.text('Welcome to BuildLedger'), findsOneWidget);

    // Verify Onboarding Steps
    expect(find.text('1. Contractor Profile'), findsOneWidget);
    expect(find.text('2. Base Currency'), findsOneWidget);
    expect(find.text('3. First Construction Project'), findsOneWidget);

    // Verify Buttons & Badges
    expect(find.text('REQUIRED'), findsOneWidget);
    expect(find.text('PKR (RS)'), findsOneWidget);
    expect(find.text('Create Project'), findsOneWidget);

    // Tapping Contractor Profile opens WelcomeContractorSheet
    await tester.tap(find.text('1. Contractor Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeContractorSheet), findsOneWidget);
    expect(find.text('Business / Contractor Name'), findsOneWidget);
  });
}
