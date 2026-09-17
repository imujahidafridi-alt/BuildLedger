import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier_ledger_entry.dart';

abstract class SupplierRepository {
  Future<Result<Supplier>> createSupplier(Supplier supplier, {Money? openingBalance});
  Future<Result<List<Supplier>>> getSuppliers({bool includeArchived = false});
  Future<Result<Supplier?>> getSupplierById(String id);
  Future<Result<List<SupplierLedgerEntry>>> getSupplierLedger(String supplierId);
  Future<Result<SupplierLedgerEntry>> recordPayment({
    required String supplierId,
    String? projectId,
    required Money amount,
    required String description,
    required DateTime date,
    String? referenceId,
  });
  Future<Result<void>> archiveSupplier(String id);
}
