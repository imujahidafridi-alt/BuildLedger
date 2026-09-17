import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:build_ledger/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/projects/presentation/widgets/project_selector_sheet.dart';
import 'package:build_ledger/features/reports/data/pdf_report_generator.dart';
import 'package:build_ledger/features/reports/data/csv_report_generator.dart';
import 'package:build_ledger/features/settings/presentation/controllers/settings_controller.dart';
import 'package:build_ledger/shared/ui/shad_ui.dart';

class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen> {
  bool _isGenerating = false;

  Future<void> _generateProjectSummaryPdf() async {
    setState(() => _isGenerating = true);
    try {
      final summary = await ref.read(projectSummaryProvider.future);
      final profile = ref.read(contractorProfileProvider);
      final pdfBytes = await PdfReportGenerator.generateProjectSummaryReport(
        summary: summary,
        contractorProfile: profile,
      );

      await Printing.layoutPdf(
        name: '${summary.projectName}_Financial_Summary.pdf',
        onLayout: (_) => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _shareProjectSummaryPdf() async {
    setState(() => _isGenerating = true);
    try {
      final summary = await ref.read(projectSummaryProvider.future);
      final profile = ref.read(contractorProfileProvider);
      final pdfBytes = await PdfReportGenerator.generateProjectSummaryReport(
        summary: summary,
        contractorProfile: profile,
      );

      final tempDir = await getTemporaryDirectory();
      final sanitizedName = summary.projectName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final filePath = p.join(tempDir.path, '${sanitizedName}_Financial_Summary.pdf');
      await File(filePath).writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'BuildLedger Report: ${summary.projectName} Financial Summary',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateExpenseLedgerPdf() async {
    setState(() => _isGenerating = true);
    try {
      final activeProject = ref.read(selectedProjectProvider);
      final expenses = await ref.read(filteredExpensesProvider.future);
      final profile = ref.read(contractorProfileProvider);

      final pdfBytes = await PdfReportGenerator.generateExpenseReport(
        projectName: activeProject?.name ?? 'All Projects',
        expenses: expenses,
        contractorProfile: profile,
      );

      await Printing.layoutPdf(
        name: '${activeProject?.name ?? "Expenses"}_Ledger.pdf',
        onLayout: (_) => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate expense ledger: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isGenerating = true);
    try {
      final expenses = await ref.read(filteredExpensesProvider.future);
      final csvString = CsvReportGenerator.generateExpenseCsv(expenses);

      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, 'BuildLedger_Expenses.csv');
      await File(filePath).writeAsString(csvString);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'BuildLedger Expenses CSV Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProject = ref.watch(selectedProjectProvider);
    final tokens = context.shad;
    final dynamicBottomPadding = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Statements'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, dynamicBottomPadding),
        children: [
          // Project Switcher Banner
          ShadCard(
            onTap: () async {
              final picked = await ProjectSelectorSheet.show(context, ref);
              if (picked != null) {
                ref.read(selectedProjectProvider.notifier).state = picked;
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.apartment, color: tokens.primary, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE REPORTING PROJECT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: tokens.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeProject?.name ?? 'Select Project',
                          style: tokens.typography.p.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(Icons.swap_horiz, color: tokens.primary),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Report Option 1: Project Financial Summary (Executive Overview / Info -> Blue)
          _buildReportCard(
            title: 'Project Financial Summary',
            tag: 'EXECUTIVE OVERVIEW • PDF',
            badgeVariant: ShadBadgeVariant.info,
            description: 'Executive overview with total budget, actual incurred spend, cash outflow, supplier payables, and category breakdown.',
            icon: Icons.pie_chart_outline,
            iconColor: tokens.info,
            iconBgColor: tokens.infoContainer,
            actionButtonText: 'Share PDF',
            onPreview: _isGenerating ? null : _generateProjectSummaryPdf,
            onAction: _isGenerating ? null : _shareProjectSummaryPdf,
          ),
          const SizedBox(height: 14),

          // Report Option 2: Detailed Expense Ledger (Purchases / Expenses -> Amber Primary)
          _buildReportCard(
            title: 'Detailed Expense Ledger',
            tag: 'PURCHASE LEDGER • PDF',
            badgeVariant: ShadBadgeVariant.warning,
            description: 'Chronological statement of all active site purchases, vendor bills, and transactions with subtotals.',
            icon: Icons.receipt_long,
            iconColor: tokens.primary,
            iconBgColor: tokens.primary.withValues(alpha: 0.15),
            actionButtonText: 'Share PDF',
            onPreview: _isGenerating ? null : _generateExpenseLedgerPdf,
            onAction: _isGenerating ? null : _generateExpenseLedgerPdf,
          ),
          const SizedBox(height: 14),

          // Report Option 3: Spreadsheet CSV Export (Export / Reconciled -> Emerald)
          _buildReportCard(
            title: 'Spreadsheet CSV Data Export',
            tag: 'DATA RECONCILIATION • CSV',
            badgeVariant: ShadBadgeVariant.success,
            description: 'Full transaction data exported in CSV format for Excel, Google Sheets, or accountant reconciliation.',
            icon: Icons.table_view_outlined,
            iconColor: tokens.success,
            iconBgColor: tokens.successContainer,
            actionButtonText: 'Export CSV',
            onAction: _isGenerating ? null : _exportCsv,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String tag,
    required ShadBadgeVariant badgeVariant,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String actionButtonText,
    VoidCallback? onPreview,
    VoidCallback? onAction,
  }) {
    final tokens = context.shad;
    final hasPreview = onPreview != null;

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tokens.typography.p.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ShadBadge(
                      label: tag,
                      variant: badgeVariant,
                      isSmall: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: tokens.typography.small.copyWith(
              color: tokens.mutedForeground,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: tokens.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasPreview) ...[
                ShadButton.outline(
                  onPressed: onPreview,
                  icon: Icons.print,
                  label: 'View / Print',
                  size: ShadButtonSize.small,
                ),
                const SizedBox(width: 8),
              ],
              ShadButton(
                onPressed: onAction,
                icon: hasPreview ? Icons.share : Icons.download,
                label: actionButtonText,
                variant: ShadButtonVariant.primary,
                size: ShadButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

