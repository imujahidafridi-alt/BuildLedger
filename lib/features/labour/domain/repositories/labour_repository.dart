import 'package:build_ledger/core/domain/result.dart';
import 'package:build_ledger/features/labour/domain/entities/labour_entry.dart';

abstract class LabourRepository {
  Future<Result<LabourEntry>> recordLabourShift(LabourEntry entry, {bool autoCreateProjectExpense = false});
  Future<Result<void>> voidLabourShift({
    required String labourId,
    required String reason,
    required String actor,
  });
  Future<Result<List<LabourEntry>>> getLabourEntries({
    String? projectId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeVoided = false,
  });
}
