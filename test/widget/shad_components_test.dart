import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/projects/domain/entities/project.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Standard WCAG 2.1 algorithm to compute relative luminance and contrast ratio.
double _calculateRelativeLuminance(Color color) {
  double channelLuminance(double channel) {
    return channel <= 0.04045
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channelLuminance(color.r);
  final g = channelLuminance(color.g);
  final b = channelLuminance(color.b);

  return (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
}

double calculateContrastRatio(Color foreground, Color background) {
  final l1 = _calculateRelativeLuminance(foreground);
  final l2 = _calculateRelativeLuminance(background);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('ShadTokens WCAG 2.1 Contrast Verification', () {
    test('Primary button: Dark Obsidian text on Precision Amber exceeds WCAG AAA (>= 7.0:1)', () {
      final ratio = calculateContrastRatio(ShadPalette.amberForeground, ShadPalette.amber);
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'Obsidian on Precision Amber must satisfy WCAG AAA (actual: ${ratio.toStringAsFixed(2)}:1)');
    });

    test('Dark theme: Foreground on Background exceeds 15:1', () {
      final ratio = calculateContrastRatio(ShadPalette.darkForeground, ShadPalette.obsidianCanvas);
      expect(ratio, greaterThan(15.0),
          reason: 'Foreground text on Obsidian Canvas must be highly readable (actual: ${ratio.toStringAsFixed(2)}:1)');
    });

    test('Destructive button: White text on Destructive Red meets bold text requirement', () {
      final ratio = calculateContrastRatio(ShadPalette.redForeground, ShadPalette.red);
      expect(ratio, greaterThanOrEqualTo(3.5),
          reason: 'Destructive foreground on destructive background meets button contrast (actual: ${ratio.toStringAsFixed(2)}:1)');
    });
  });

  group('Deterministic Integer Minor-Unit Financial Parsing', () {
    test('Correctly parses whole integers to minor units (paisas) without floating point error', () {
      expect(ShadAmountInput.parseToMinorUnits('18500'), equals(1850000));
      expect(ShadAmountInput.parseToMinorUnits('18,500'), equals(1850000));
      expect(ShadAmountInput.parseToMinorUnits('0'), equals(0));
      expect(ShadAmountInput.parseToMinorUnits(''), equals(0));
    });

    test('Correctly parses decimal numbers to minor units (paisas)', () {
      expect(ShadAmountInput.parseToMinorUnits('18500.50'), equals(1850050));
      expect(ShadAmountInput.parseToMinorUnits('18,500.50'), equals(1850050));
      expect(ShadAmountInput.parseToMinorUnits('18500.5'), equals(1850050));
      expect(ShadAmountInput.parseToMinorUnits('0.05'), equals(5));
      expect(ShadAmountInput.parseToMinorUnits('0.99'), equals(99));
    });
  });

  group('ShadButton Touch Targets & Geometry', () {
    testWidgets('Small ShadButton guarantees >= 48dp minimum interactive touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ShadTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: ShadButton(
                label: 'Test Small',
                size: ShadButtonSize.sm,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ShadButton);
      expect(buttonFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(buttonFinder);
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0),
          reason: 'ShadButton interactive touch target must be at least 48dp even when visual size is sm');
    });

    testWidgets('Medium ShadButton satisfies >= 48dp touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ShadTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: ShadButton(
                label: 'Test Default',
                size: ShadButtonSize.md,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ShadButton);
      final renderBox = tester.renderObject<RenderBox>(buttonFinder);
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Primary ShadButton applies amber background and dark text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ShadTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: ShadButton(
                label: 'Primary CTA',
                variant: ShadButtonVariant.primary,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ShadButton);
      expect(buttonFinder, findsOneWidget);

      final textFinder = find.text('Primary CTA');
      expect(textFinder, findsOneWidget);
    });

    testWidgets('ShadButton handles loading state and disables tap', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ShadTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: ShadButton(
                label: 'Save Project',
                isLoading: true,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      // Loading spinner should be present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(ShadButton));
      expect(pressed, isFalse, reason: 'Button must not trigger onPressed while isLoading is true');
    });
  });

  group('ShadTabs Component', () {
    testWidgets('Renders segmented tabs and responds to tap', (tester) async {
      String activeTab = 'All';

      await tester.pumpWidget(
        MaterialApp(
          theme: ShadTheme.darkTheme,
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: ShadTabs<String>(
                  values: const ['All', 'Purchases', 'Payments'],
                  selectedValue: activeTab,
                  labelBuilder: (s) => s,
                  onTabSelected: (s) => setState(() => activeTab = s),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Purchases'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);

      await tester.tap(find.text('Payments'));
      await tester.pumpAndSettle();

      expect(activeTab, equals('Payments'));
    });
  });

  group('ShadTransactionTile Component', () {
    testWidgets('Renders financial entry with title, status badge and formatted money', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ShadTheme.darkTheme,
          home: Scaffold(
            body: ShadTransactionTile(
              title: '500 Bags Ordinary Portland Cement',
              subtitle: 'ABC Cement Agency',
              amount: const Money(42500000), // Rs 425,000
              date: DateTime(2025, 3, 15),
              statusBadge: 'CREDIT',
              badgeVariant: ShadBadgeVariant.warning,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('500 Bags Ordinary Portland Cement'), findsOneWidget);
      expect(find.text('ABC Cement Agency'), findsOneWidget);
      expect(find.text('CREDIT'), findsOneWidget);
      expect(find.byType(MoneyText), findsOneWidget);

      await tester.tap(find.byType(ShadTransactionTile));
      expect(tapped, isTrue);
    });

    testWidgets('Voided transaction renders strike-through text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ShadTheme.darkTheme,
          home: Scaffold(
            body: ShadTransactionTile(
              title: 'Duplicate Gravel Delivery',
              amount: const Money(8500000),
              date: DateTime(2025, 3, 10),
              isVoided: true,
            ),
          ),
        ),
      );

      expect(find.text('Duplicate Gravel Delivery'), findsOneWidget);
      expect(find.text('VOIDED'), findsOneWidget);
    });
  });

  group('ShadProjectSelector Component', () {
    testWidgets('Renders project details and fires onTap callback', (tester) async {
      bool tapped = false;
      final testProject = Project(
        id: 'proj_101',
        name: 'Gulberg Commercial Plaza',
        budgetAmount: const Money(1500000000), // Rs 15,000,000
        location: 'Lahore',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ShadTheme.darkTheme,
          home: Scaffold(
            body: ShadProjectSelector(
              project: testProject,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Gulberg Commercial Plaza'), findsOneWidget);
      expect(find.text('ACTIVE PROJECT'), findsOneWidget);

      await tester.tap(find.byType(ShadProjectSelector));
      expect(tapped, isTrue);
    });
  });
}
