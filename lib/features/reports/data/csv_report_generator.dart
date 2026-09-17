import 'package:csv/csv.dart';
import 'package:build_ledger/core/formatting/date_formatter.dart';
import 'package:build_ledger/features/expenses/domain/entities/expense.dart';

class CsvReportGenerator {
  static String generateExpenseCsv(List<Expense> expenses) {
    final rows = <List<dynamic>>[
      [
        'Expense ID',
        'Date',
        'Project',
        'Category',
        'Group',
        'Supplier / Vendor',
        'Payment Method',
        'Amount (PKR Minor)',
        'Amount (PKR Major)',
        'Status',
        'Void Reason',
        'Description',
        'Notes',
      ],
      ...expenses.map((e) => [
            e.id,
            DateFormatter.formatIso(e.expenseDate),
            e.projectName ?? '',
            e.categoryName ?? '',
            e.categoryGroupName ?? '',
            e.supplierName ?? '',
            e.paymentMethod.displayName,
            e.amount.minorUnits,
            (e.amount.minorUnits / 100.0).toStringAsFixed(2),
            e.status.name.toUpperCase(),
            e.voidReason ?? '',
            e.description ?? '',
            e.notes ?? '',
          ]),
    ];

    return const ListToCsvConverter().convert(rows);
  }
}
