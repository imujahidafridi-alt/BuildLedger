import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/core/domain/money.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:build_ledger/features/suppliers/domain/entities/supplier_ledger_entry.dart';
import 'package:build_ledger/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:build_ledger/features/suppliers/data/repositories/supplier_repository_impl.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepositoryImpl();
});

final suppliersListProvider = FutureProvider<List<Supplier>>((ref) async {
  final repo = ref.watch(supplierRepositoryProvider);
  final result = await repo.getSuppliers();
  return result.fold(
    onSuccess: (suppliers) => suppliers,
    onFailure: (failure) => throw failure,
  );
});

final supplierLedgerProvider = FutureProvider.family<List<SupplierLedgerEntry>, String>((ref, supplierId) async {
  final repo = ref.watch(supplierRepositoryProvider);
  final result = await repo.getSupplierLedger(supplierId);
  return result.fold(
    onSuccess: (entries) => entries,
    onFailure: (failure) => throw failure,
  );
});

class SupplierController extends StateNotifier<AsyncValue<void>> {
  final SupplierRepository _repository;
  final Ref _ref;

  SupplierController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> createSupplier(Supplier supplier, {Money? openingBalance}) async {
    state = const AsyncValue.loading();
    final result = await _repository.createSupplier(supplier, openingBalance: openingBalance);
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(suppliersListProvider);
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> recordPayment({
    required String supplierId,
    String? projectId,
    required Money amount,
    required String description,
    required DateTime date,
    String? referenceId,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.recordPayment(
      supplierId: supplierId,
      projectId: projectId,
      amount: amount,
      description: description,
      date: date,
      referenceId: referenceId,
    );
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(suppliersListProvider);
        _ref.invalidate(supplierLedgerProvider(supplierId));
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }
}

final supplierControllerProvider = StateNotifierProvider<SupplierController, AsyncValue<void>>((ref) {
  return SupplierController(ref.watch(supplierRepositoryProvider), ref);
});
