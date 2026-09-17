import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:build_ledger/app/theme/app_colors.dart';
import 'package:build_ledger/app/theme/app_theme.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/shared/components/app_button.dart';
import 'package:build_ledger/shared/components/app_section.dart';
import 'package:build_ledger/shared/forms/app_amount_field.dart';
import 'package:build_ledger/shared/widgets/app_project_selector.dart';

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
  group('Design System WCAG Contrast Ratio Verification (Directive 1)', () {
    test('Primary button contrast: Deep Obsidian text on Precision Amber exceeds WCAG AAA', () {
      const onAmber = AppColors.onAmber; // #0B0F17
      const precisionAmber = AppColors.precisionAmber; // #F59E0B

      final ratio = calculateContrastRatio(onAmber, precisionAmber);

      // WCAG AA requires >= 4.5:1 for normal text, AAA requires >= 7.0:1
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'Deep Obsidian on Precision Amber must meet or exceed WCAG AAA (7.0:1). Actual ratio: ${ratio.toStringAsFixed(2)}:1');
    });

    test('Canvas text contrast: TextPrimary on Obsidian Canvas exceeds WCAG AAA', () {
      const textPrimary = AppColors.textPrimary; // #F8FAFC
      const canvas = AppColors.obsidianCanvas; // #0B0F17

      final ratio = calculateContrastRatio(textPrimary, canvas);

      expect(ratio, greaterThan(15.0),
          reason: 'TextPrimary on Obsidian Canvas should provide extreme legibility (>15:1). Actual ratio: ${ratio.toStringAsFixed(2)}:1');
    });

    test('Destructive button contrast: White text on Error Red exceeds WCAG AA for buttons', () {
      const white = Colors.white;
      const errorRed = AppColors.errorRed; // #EF4444

      final ratio = calculateContrastRatio(white, errorRed);

      expect(ratio, greaterThanOrEqualTo(4.0),
          reason: 'White text on Error Red should meet bold button contrast requirements. Actual ratio: ${ratio.toStringAsFixed(2)}:1');
    });
  });

  group('Deterministic Integer Minor-Unit Financial Parsing (Directive 6)', () {
    test('Correctly parses whole integers to paisas without floating-point error', () {
      expect(AppAmountField.parseToMinorUnits('18500'), equals(1850000));
      expect(AppAmountField.parseToMinorUnits('18,500'), equals(1850000));
      expect(AppAmountField.parseToMinorUnits('0'), equals(0));
      expect(AppAmountField.parseToMinorUnits(''), equals(0));
    });

    test('Correctly parses decimal amounts to paisas', () {
      expect(AppAmountField.parseToMinorUnits('18500.50'), equals(1850050));
      expect(AppAmountField.parseToMinorUnits('18,500.50'), equals(1850050));
      expect(AppAmountField.parseToMinorUnits('18500.5'), equals(1850050));
      expect(AppAmountField.parseToMinorUnits('0.05'), equals(5));
      expect(AppAmountField.parseToMinorUnits('0.99'), equals(99));
    });
  });

  group('Interactive Touch Target & Geometry Verification (Directive 3 & 5)', () {
    testWidgets('AppButton small size maintains minimum 48dp interactive touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: AppButton(
                label: 'Small Button',
                size: AppButtonSize.small,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(AppButton);
      expect(buttonFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(buttonFinder);
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0),
          reason: 'AppButton interactive touch target must be at least 48dp even when visual height is small');
    });

    testWidgets('AppSectionItem maintains minimum 56dp row touch target height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AppSection(
              title: 'Test Section',
              children: [
                AppSectionItem(
                  icon: Icons.settings,
                  title: 'Settings Row',
                  subtitle: 'Configuration options',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final itemFinder = find.byType(AppSectionItem);
      expect(itemFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(itemFinder);
      expect(renderBox.size.height, greaterThanOrEqualTo(56.0),
          reason: 'AppSectionItem must guarantee >= 48dp (standard 56dp) touch target height');
    });

    testWidgets('AppProjectSelector renders purely without Riverpod dependencies', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AppProjectSelector(
              projectName: 'Commercial Tower A',
              budgetAmount: const Money(500000000),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Commercial Tower A'), findsOneWidget);
      expect(find.text('ACTIVE REPORTING PROJECT'), findsOneWidget);

      await tester.tap(find.byType(AppProjectSelector));
      expect(tapped, isTrue);
    });
  });
}
