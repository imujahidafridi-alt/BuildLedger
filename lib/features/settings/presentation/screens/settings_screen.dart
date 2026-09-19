import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/formatting/date_formatter.dart';
import 'package:build_ledger/core/formatting/money_formatter.dart';
import 'package:build_ledger/features/suppliers/presentation/controllers/supplier_controller.dart';
import 'package:build_ledger/features/labour/presentation/controllers/labour_controller.dart';
import 'package:build_ledger/features/settings/presentation/controllers/settings_controller.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/contractor_profile_sheet.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/currency_selector_sheet.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/shift_hours_selector_sheet.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/database_diagnostics_sheet.dart';
import 'package:build_ledger/features/settings/presentation/dialogs/about_system_dialog.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// More & Settings screen:
/// Cleanly separates Daily Operational Workflows (Suppliers, Labour) from
/// System Configuration (Theme, Currency, Shift Defaults, Diagnostics, About).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.shad;
    final currentThemeMode = ref.watch(themeModeProvider);
    final profile = ref.watch(contractorProfileProvider);
    final currentCurrency = ref.watch(baseCurrencyProvider);
    final shiftHoursX100 = ref.watch(standardShiftHoursProvider);
    final suppliersAsync = ref.watch(suppliersListProvider);
    final labourAsync = ref.watch(labourEntriesProvider);
    final lastBackupAsync = ref.watch(lastBackupTimestampProvider);
    final diagnosticsAsync = ref.watch(databaseDiagnosticsProvider);

    final dynamicBottomPadding =
        MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    // Operational Subtitles
    final supplierSubtitle = suppliersAsync.when(
      data: (suppliers) {
        if (suppliers.isEmpty) return 'No suppliers registered';
        final totalPayable = suppliers.fold<int>(
          0,
          (sum, s) => sum + (s.currentBalance.minorUnits > 0 ? s.currentBalance.minorUnits : 0),
        );
        if (totalPayable > 0) {
          return '${suppliers.length} active suppliers • ${MoneyFormatter.format(Money(totalPayable))} payable';
        }
        return '${suppliers.length} active suppliers • All accounts settled';
      },
      loading: () => 'Loading supplier accounts...',
      error: (error, stack) => 'Manage credit balances and ledger statements',
    );

    final labourSubtitle = labourAsync.when(
      data: (entries) {
        if (entries.isEmpty) return 'No shifts logged';
        final uniqueWorkers = entries.map((e) => e.workerName).toSet().length;
        return '$uniqueWorkers workers • ${entries.length} shifts recorded';
      },
      loading: () => 'Loading worker records...',
      error: (error, stack) => 'Log daily shifts, advances, and net wage payouts',
    );

    // Backup Subtitle
    final backupSubtitle = lastBackupAsync.when(
      data: (timestamp) {
        if (timestamp == null) return 'No backups yet • AES-256-GCM package';
        return 'Last backup: ${DateFormatter.format(timestamp)}';
      },
      loading: () => 'Checking backup metadata...',
      error: (error, stack) => 'AES-256-GCM package with SHA-256 integrity check',
    );

    // Database Subtitle
    final databaseSubtitle = diagnosticsAsync.when(
      data: (diag) => '${diag.formattedSize} • SQLite ${diag.journalMode} mode',
      loading: () => 'SQLite WAL mode • Local Zero-Latency Engine',
      error: (error, stack) => 'SQLite WAL mode • Local Zero-Latency Engine',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, dynamicBottomPadding),
        children: [
          // 1. Actionable Contractor / Business Profile Card
          ShadCard(
            onTap: () => ContractorProfileSheet.show(context),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: tokens.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.apartment, color: tokens.primary, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.isConfigured ? profile.name : 'Set Up Contractor Profile',
                              style: tokens.typography.p.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ShadBadge(
                            label: profile.isConfigured ? 'PROFILE' : 'SET UP',
                            variant: profile.isConfigured
                                ? ShadBadgeVariant.warning
                                : ShadBadgeVariant.neutral,
                            isSmall: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (profile.isConfigured) ...[
                        Text(
                          [
                            if (profile.taxId.isNotEmpty) 'NTN: ${profile.taxId}',
                            if (profile.phone.isNotEmpty) profile.phone,
                            if (profile.address.isNotEmpty) profile.address,
                          ].join(' • '),
                          style: tokens.typography.small.copyWith(
                            color: tokens.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          'Configure company name, NTN, and address for PDF reports',
                          style: tokens.typography.small.copyWith(
                            color: tokens.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined, size: 18, color: tokens.mutedForeground),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Operational Modules Section
          ShadSection(
            title: 'Operational',
            children: [
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.storefront_outlined, color: tokens.primary, size: 20)),
                ),
                title: const Text('Suppliers & Vendor Ledgers'),
                subtitle: Text(supplierSubtitle),
                onTap: () => context.push('/suppliers'),
              ),
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.groups_outlined, color: tokens.primary, size: 20)),
                ),
                title: const Text('Site Labour & Shift Wage Payouts'),
                subtitle: Text(labourSubtitle),
                onTap: () => context.push('/labour'),
              ),
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.category_outlined, color: tokens.primary, size: 20)),
                ),
                title: const Text('Expense Taxonomies & Categories'),
                subtitle: const Text('23 construction cost phases, subcategories & custom items'),
                onTap: () => context.push('/categories'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Preferences Section
          ShadSection(
            title: 'Preferences',
            children: [
              // Theme Selector Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Theme Mode',
                          style: tokens.typography.p.copyWith(fontWeight: FontWeight.w600),
                        ),
                        ShadBadge(
                          label: currentThemeMode == ThemeMode.system
                              ? 'SYSTEM DEFAULT'
                              : (currentThemeMode == ThemeMode.dark ? 'DARK' : 'LIGHT'),
                          variant: currentThemeMode == ThemeMode.system
                              ? ShadBadgeVariant.neutral
                              : ShadBadgeVariant.info,
                          isSmall: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Default follows device OS setting. Select to override.',
                      style: tokens.typography.muted,
                    ),
                    const SizedBox(height: 10),
                    ShadTabs<ThemeMode>(
                      values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
                      selectedValue: currentThemeMode,
                      labelBuilder: (mode) {
                        switch (mode) {
                          case ThemeMode.system:
                            return 'System';
                          case ThemeMode.light:
                            return 'Light';
                          case ThemeMode.dark:
                            return 'Dark';
                        }
                      },
                      iconBuilder: (mode) {
                        switch (mode) {
                          case ThemeMode.system:
                            return const Icon(Icons.brightness_auto, size: 16);
                          case ThemeMode.light:
                            return const Icon(Icons.light_mode_outlined, size: 16);
                          case ThemeMode.dark:
                            return const Icon(Icons.dark_mode_outlined, size: 16);
                        }
                      },
                      onTabSelected: (mode) {
                        ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      },
                    ),
                  ],
                ),
              ),
              // Base Currency (Dynamic Selector)
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      currentCurrency.flag,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                title: const Text('Base Currency'),
                subtitle: Text('${currentCurrency.code} (${currentCurrency.name}) • Formatting standard'),
                trailing: ShadBadge(
                  label: '${currentCurrency.code} (${currentCurrency.symbol})',
                  variant: ShadBadgeVariant.warning,
                  isSmall: true,
                ),
                onTap: () => CurrencySelectorSheet.show(context),
              ),
              // Standard Shift Duration
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.schedule, color: tokens.mutedForeground, size: 20)),
                ),
                title: const Text('Standard Labour Shift'),
                subtitle: const Text('Base duration for daily wage calculations'),
                trailing: ShadBadge(
                  label: '${(shiftHoursX100 / 100).toStringAsFixed(1)} Hours',
                  variant: ShadBadgeVariant.warning,
                  isSmall: true,
                ),
                onTap: () => ShiftHoursSelectorSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4. Data & Security Section
          ShadSection(
            title: 'Data & Security',
            children: [
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.infoContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.shield_outlined, color: tokens.info, size: 20)),
                ),
                title: const Text('Encrypted Backup & Restore'),
                subtitle: Text(backupSubtitle),
                onTap: () => context.push('/backup'),
              ),
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.infoContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.storage_outlined, color: tokens.info, size: 20)),
                ),
                title: const Text('Storage & Local Database'),
                subtitle: Text(databaseSubtitle),
                onTap: () => DatabaseDiagnosticsSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 5. About & System Section
          ShadSection(
            title: 'About & System',
            children: [
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.palette_outlined, color: tokens.mutedForeground, size: 20)),
                ),
                title: const Text('Design System Gallery'),
                subtitle: const Text('Interactive canonical ShadCN UI playground (Dev Tools)'),
                onTap: () => context.push('/design-system'),
              ),
              ShadSectionItem(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.info_outline, color: tokens.mutedForeground, size: 20)),
                ),
                title: const Text('BuildLedger'),
                subtitle: const Text('Version 1.0.0 (Build 1) • Production Grade'),
                trailing: Text(
                  'v1.0.0',
                  style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
                ),
                onTap: () => AboutSystemDialog.show(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
