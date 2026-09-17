import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/features/settings/domain/entities/contractor_profile.dart';
import 'package:build_ledger/features/settings/domain/entities/database_diagnostics.dart';
import 'package:build_ledger/features/settings/data/app_settings_repository.dart';
import 'package:build_ledger/features/settings/data/database_diagnostics_service.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return SharedPrefsAppSettingsRepository();
});

class ContractorProfileNotifier extends StateNotifier<ContractorProfile> {
  final AppSettingsRepository _repository;

  ContractorProfileNotifier(this._repository) : super(ContractorProfile.empty()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final profile = await _repository.getContractorProfile();
    state = profile;
  }

  Future<void> saveProfile(ContractorProfile profile) async {
    state = profile;
    await _repository.saveContractorProfile(profile);
  }
}

final contractorProfileProvider =
    StateNotifierProvider<ContractorProfileNotifier, ContractorProfile>((ref) {
  final repo = ref.watch(appSettingsRepositoryProvider);
  return ContractorProfileNotifier(repo);
});

class StandardShiftHoursNotifier extends StateNotifier<int> {
  final AppSettingsRepository _repository;

  StandardShiftHoursNotifier(this._repository) : super(800) {
    loadHours();
  }

  Future<void> loadHours() async {
    final val = await _repository.getStandardLabourShiftHoursX100();
    state = val;
  }

  Future<void> setShiftHoursX100(int hoursX100) async {
    state = hoursX100;
    await _repository.setStandardLabourShiftHoursX100(hoursX100);
  }
}

final standardShiftHoursProvider =
    StateNotifierProvider<StandardShiftHoursNotifier, int>((ref) {
  final repo = ref.watch(appSettingsRepositoryProvider);
  return StandardShiftHoursNotifier(repo);
});

final lastBackupTimestampProvider = FutureProvider<DateTime?>((ref) async {
  final repo = ref.watch(appSettingsRepositoryProvider);
  return await repo.getLastBackupTimestamp();
});

final databaseDiagnosticsServiceProvider =
    Provider<DatabaseDiagnosticsService>((ref) {
  return DatabaseDiagnosticsService();
});

final databaseDiagnosticsProvider =
    FutureProvider<DatabaseDiagnostics>((ref) async {
  final service = ref.watch(databaseDiagnosticsServiceProvider);
  return await service.getDiagnostics();
});

class DatabaseOptimizationController extends StateNotifier<AsyncValue<void>> {
  final DatabaseDiagnosticsService _service;
  final Ref _ref;

  DatabaseOptimizationController(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> optimize() async {
    state = const AsyncValue.loading();
    try {
      await _service.optimizeDatabase();
      state = const AsyncValue.data(null);
      // Refresh diagnostics after vacuum
      _ref.invalidate(databaseDiagnosticsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final databaseOptimizationControllerProvider =
    StateNotifierProvider<DatabaseOptimizationController, AsyncValue<void>>((ref) {
  final service = ref.watch(databaseDiagnosticsServiceProvider);
  return DatabaseOptimizationController(service, ref);
});
