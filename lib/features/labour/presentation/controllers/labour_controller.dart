import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/labour/domain/entities/labour_entry.dart';
import 'package:build_ledger/features/labour/domain/repositories/labour_repository.dart';
import 'package:build_ledger/features/labour/data/repositories/labour_repository_impl.dart';
import 'package:build_ledger/features/projects/presentation/controllers/project_controller.dart';
import 'package:build_ledger/features/expenses/presentation/controllers/expense_controller.dart';

final labourRepositoryProvider = Provider<LabourRepository>((ref) {
  return LabourRepositoryImpl();
});

final labourEntriesProvider = FutureProvider<List<LabourEntry>>((ref) async {
  final repo = ref.watch(labourRepositoryProvider);
  final activeProject = ref.watch(selectedProjectProvider);
  final result = await repo.getLabourEntries(projectId: activeProject?.id);
  return result.fold(
    onSuccess: (entries) => entries,
    onFailure: (failure) => throw failure,
  );
});

class LabourController extends StateNotifier<AsyncValue<void>> {
  final LabourRepository _repository;
  final Ref _ref;

  LabourController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> recordLabourShift(LabourEntry entry, {bool autoCreateProjectExpense = false}) async {
    state = const AsyncValue.loading();
    final result = await _repository.recordLabourShift(
      entry,
      autoCreateProjectExpense: autoCreateProjectExpense,
    );
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(labourEntriesProvider);
        _ref.invalidate(filteredExpensesProvider);
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> voidLabourShift({required String labourId, required String reason}) async {
    state = const AsyncValue.loading();
    final result = await _repository.voidLabourShift(
      labourId: labourId,
      reason: reason,
      actor: 'local_supervisor',
    );
    return result.fold(
      onSuccess: (_) {
        state = const AsyncValue.data(null);
        _ref.invalidate(labourEntriesProvider);
        _ref.invalidate(filteredExpensesProvider);
        return true;
      },
      onFailure: (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
    );
  }
}

final labourControllerProvider = StateNotifierProvider<LabourController, AsyncValue<void>>((ref) {
  return LabourController(ref.watch(labourRepositoryProvider), ref);
});
