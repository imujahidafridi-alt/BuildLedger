import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/formatting/date_formatter.dart';
import 'package:build_ledger/core/formatting/money_formatter.dart';
import 'package:build_ledger/features/dashboard/domain/models/project_financial_summary.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier_ledger_entry.dart';
import 'package:build_ledger/features/settings/domain/entities/contractor_profile.dart';

class PdfReportGenerator {
  /// Generates Project Financial Summary PDF Report
  static Future<Uint8List> generateProjectSummaryReport({
    required ProjectFinancialSummary summary,
    ContractorProfile? contractorProfile,
    String companyName = 'BUILDLEDGER CONSTRUCTION',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          'PROJECT FINANCIAL SUMMARY REPORT',
          contractorProfile: contractorProfile,
          fallbackCompanyName: companyName,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PROJECT NAME:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text(summary.projectName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('UTILIZATION:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text('${summary.utilizationPercent}% of budget spent', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: summary.isOverBudget ? PdfColors.red800 : PdfColors.green800)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Financial KPIs Grid
          pw.Row(
            children: [
              _buildKpiBox('TOTAL BUDGET', MoneyFormatter.format(summary.budget), PdfColors.grey900),
              pw.SizedBox(width: 8),
              _buildKpiBox('INCURRED COST', MoneyFormatter.format(summary.actualCost), summary.isOverBudget ? PdfColors.red800 : PdfColors.grey900),
              pw.SizedBox(width: 8),
              _buildKpiBox('CASH OUTFLOW', MoneyFormatter.format(summary.cashOutflow), PdfColors.blue800),
              pw.SizedBox(width: 8),
              _buildKpiBox('SUPPLIER PAYABLE', MoneyFormatter.format(summary.supplierPayables), PdfColors.orange800),
            ],
          ),
          pw.SizedBox(height: 24),

          // Category Breakdown Section
          pw.Text('CATEGORY SPENDING BREAKDOWN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Category Group', 'Total Spent (PKR)', 'Share %'],
            data: summary.categoryBreakdown.entries.map((e) {
              final share = summary.actualCost.minorUnits > 0
                  ? ((e.value.minorUnits / summary.actualCost.minorUnits) * 100).toStringAsFixed(1)
                  : '0';
              return [e.key, MoneyFormatter.format(e.value), '$share%'];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E2F40)),
            cellHeight: 24,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 24),

          // Recent Transactions Table
          pw.Text('RECENT FINANCIAL TRANSACTIONS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Category', 'Vendor / Description', 'Method', 'Amount (PKR)'],
            data: summary.recentExpenses.map((e) {
              return [
                DateFormatter.format(e.expenseDate),
                e.categoryName ?? 'General',
                e.supplierName ?? e.description ?? '-',
                e.paymentMethod.displayName,
                MoneyFormatter.format(e.amount),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E2F40)),
            cellHeight: 22,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates Filtered Detailed Project Expense Report
  static Future<Uint8List> generateExpenseReport({
    required String projectName,
    required List<Expense> expenses,
    ContractorProfile? contractorProfile,
    String companyName = 'BUILDLEDGER CONSTRUCTION',
  }) async {
    final pdf = pw.Document();

    int totalMinor = 0;
    for (final exp in expenses) {
      if (exp.isActive) totalMinor += exp.amount.minorUnits;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          'PROJECT EXPENSE LEDGER REPORT',
          contractorProfile: contractorProfile,
          fallbackCompanyName: companyName,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('PROJECT: $projectName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('TOTAL EXPENSES: ${MoneyFormatter.format(fromMinorUnits(totalMinor))}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Category', 'Description / Vendor', 'Payment', 'Amount (PKR)', 'Status'],
            data: expenses.map((e) {
              return [
                DateFormatter.format(e.expenseDate),
                e.categoryName ?? '-',
                e.description ?? e.supplierName ?? '-',
                e.paymentMethod.displayName,
                MoneyFormatter.format(e.amount),
                e.isVoided ? 'VOIDED' : 'ACTIVE',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E2F40)),
            cellHeight: 22,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates Supplier Statement of Account PDF Report
  static Future<Uint8List> generateSupplierLedgerReport({
    required Supplier supplier,
    required List<SupplierLedgerEntry> ledgerEntries,
    ContractorProfile? contractorProfile,
    String companyName = 'BUILDLEDGER CONSTRUCTION',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          'SUPPLIER STATEMENT OF ACCOUNT',
          contractorProfile: contractorProfile,
          fallbackCompanyName: companyName,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SUPPLIER / VENDOR:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text(supplier.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    if (supplier.phone != null) pw.Text('Phone: ${supplier.phone}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('OUTSTANDING BALANCE:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      MoneyFormatter.format(supplier.currentBalance),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: supplier.currentBalance.isPositive ? PdfColors.red800 : PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Transaction Type', 'Description / Bill Ref', 'Debit (Paid)', 'Credit (Purchases)'],
            data: ledgerEntries.map((l) {
              return [
                DateFormatter.format(l.entryDate),
                l.entryType.displayName,
                l.description,
                l.isDebit ? MoneyFormatter.format(l.amount) : '-',
                l.isCredit ? MoneyFormatter.format(l.amount) : '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E2F40)),
            cellHeight: 22,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    String reportTitle, {
    ContractorProfile? contractorProfile,
    String? fallbackCompanyName,
  }) {
    final name = (contractorProfile != null && contractorProfile.name.trim().isNotEmpty)
        ? contractorProfile.name.trim()
        : (fallbackCompanyName?.trim().isNotEmpty == true
            ? fallbackCompanyName!.trim()
            : 'BUILDLEDGER CONSTRUCTION');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    name,
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF1E2F40),
                    ),
                  ),
                  if (contractorProfile != null && contractorProfile.taxId.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'NTN / Tax ID: ${contractorProfile.taxId}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                    ),
                  ],
                  if (contractorProfile != null &&
                      (contractorProfile.address.trim().isNotEmpty || contractorProfile.phone.trim().isNotEmpty)) ...[
                    pw.SizedBox(height: 1),
                    pw.Text(
                      [
                        if (contractorProfile.address.trim().isNotEmpty) contractorProfile.address,
                        if (contractorProfile.phone.trim().isNotEmpty) 'Tel: ${contractorProfile.phone}',
                      ].join(' • '),
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ],
              ),
            ),
            pw.Text(
              'Date: ${DateFormatter.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          reportTitle,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFFE67E00),
          ),
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Generated by BuildLedger - Construction Expense Control Engine', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ],
    );
  }

  static pw.Widget _buildKpiBox(String title, String value, PdfColor textColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  static Money fromMinorUnits(int minor) => Money.fromMinor(minor);
}
