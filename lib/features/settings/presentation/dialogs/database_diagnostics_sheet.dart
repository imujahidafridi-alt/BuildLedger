import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/settings/presentation/controllers/settings_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

/// Interactive modal sheet displaying SQLite telemetry, table counts, and VACUUM maintenance.
class DatabaseDiagnosticsSheet extends ConsumerWidget {
  const DatabaseDiagnosticsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return ShadSheet.show(
      context: context,
      builder: (context) => const ShadSheet(
        child: DatabaseDiagnosticsSheet(),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, BuildContext context, {Widget? action}) {
    final tokens = context.shad;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: tokens.typography.muted),
          const SizedBox(width: 8),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: tokens.typography.mono.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 6),
                  action,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOptimize(BuildContext context, WidgetRef ref) async {
    final confirmed = await ShadConfirmDialog.show(
      context,
      title: 'Optimize Database?',
      message:
          'This will execute a SQLite VACUUM operation to defragment storage, reclaim unused space, and rebuild search indexes. The database may lock briefly.',
      confirmLabel: 'Run VACUUM',
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(databaseOptimizationControllerProvider.notifier)
        .optimize();

    if (context.mounted) {
      if (success) {
        ShadToast.show(
          context,
          title: 'Optimization Complete',
          message: 'SQLite VACUUM succeeded. Storage compacted and indexes rebuilt.',
          variant: ShadToastVariant.success,
        );
      } else {
        ShadToast.show(
          context,
          title: 'Optimization Failed',
          message: 'Unable to execute database optimization.',
          variant: ShadToastVariant.destructive,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.shad;
    final diagAsync = ref.watch(databaseDiagnosticsProvider);
    final optState = ref.watch(databaseOptimizationControllerProvider);
    final isOptimizing = optState.isLoading;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.infoContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(Icons.storage_outlined, color: tokens.info, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Storage & Database Diagnostics', style: tokens.typography.h4),
                    const SizedBox(height: 2),
                    Text(
                      'Local SQLite zero-latency offline engine',
                      style: tokens.typography.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          diagAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => ShadCard(
              backgroundColor: tokens.destructive.withValues(alpha: 0.1),
              borderColor: tokens.destructive,
              child: Text(
                'Failed to read database statistics: $err',
                style: TextStyle(color: tokens.destructive),
              ),
            ),
            data: (diag) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section 1: Engine Details
                  Text('DATABASE ENGINE', style: tokens.typography.small.copyWith(color: tokens.mutedForeground, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ShadCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      children: [
                        _buildMetricRow('Database File Size', diag.formattedSize, context),
                        Divider(color: tokens.border, height: 1),
                        _buildMetricRow('SQLite Version', diag.sqliteVersion, context),
                        Divider(color: tokens.border, height: 1),
                        _buildMetricRow('Journal Mode', diag.journalMode, context),
                        Divider(color: tokens.border, height: 1),
                        _buildMetricRow(
                          'File Path',
                          diag.databasePath.length > 25
                              ? '...${diag.databasePath.substring(diag.databasePath.length - 22)}'
                              : diag.databasePath,
                          context,
                          action: IconButton(
                            icon: const Icon(Icons.copy, size: 15),
                            tooltip: 'Copy Database Path',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: diag.databasePath));
                              ShadToast.show(
                                context,
                                title: 'Path Copied',
                                message: 'Database path copied to clipboard.',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 2: Ledger Table Counts
                  Text('ACTIVE LEDGER RECORDS', style: tokens.typography.small.copyWith(color: tokens.mutedForeground, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ShadCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      children: [
                        _buildMetricRow('Construction Projects', '${diag.projectCount}', context),
                        Divider(color: tokens.border, height: 1),
                        _buildMetricRow('Expense Ledger Entries', '${diag.expenseCount}', context),
                        Divider(color: tokens.border, height: 1),
                        _buildMetricRow('Suppliers & Vendors', '${diag.supplierCount}', context),
                        Divider(color: tokens.border, height: 1),
                        _buildMetricRow('Labour Shifts Logged', '${diag.labourCount}', context),
                        Divider(color: tokens.border, height: 1),
                        _buildMetricRow('Total Local Records', '${diag.totalRecords}', context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Optimization action
                  ShadButton.outline(
                    label: isOptimizing ? 'Optimizing Database...' : 'Optimize Database (VACUUM)',
                    icon: Icons.cleaning_services_outlined,
                    isLoading: isOptimizing,
                    onPressed: isOptimizing ? null : () => _handleOptimize(context, ref),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
