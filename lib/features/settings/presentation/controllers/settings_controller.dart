import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:build_ledger/core/formatting/money_formatter.dart';
import 'package:build_ledger/features/settings/domain/entities/contractor_profile.dart';
import 'package:build_ledger/features/settings/domain/entities/database_diagnostics.dart';
import 'package:build_ledger/features/settings/data/app_settings_repository.dart';
import 'package:build_ledger/features/settings/data/database_diagnostics_service.dart';

class CurrencyConfig {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const CurrencyConfig({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });
}

const List<CurrencyConfig> kSupportedCurrencies = [
  CurrencyConfig(code: 'PKR', symbol: 'Rs', name: 'Pakistani Rupee', flag: '🇵🇰'),
  CurrencyConfig(code: 'AED', symbol: 'AED', name: 'UAE Dirham', flag: '🇦🇪'),
  CurrencyConfig(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal', flag: '🇸🇦'),
  CurrencyConfig(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '🇺🇸'),
  CurrencyConfig(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧'),
  CurrencyConfig(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
  CurrencyConfig(code: 'QAR', symbol: 'QAR', name: 'Qatari Riyal', flag: '🇶🇦'),
  CurrencyConfig(code: 'OMR', symbol: 'OMR', name: 'Omani Rial', flag: '🇴🇲'),
  CurrencyConfig(code: 'KWD', symbol: 'KWD', name: 'Kuwaiti Dinar', flag: '🇰🇼'),
  CurrencyConfig(code: 'BHD', symbol: 'BHD', name: 'Bahraini Dinar', flag: '🇧🇭'),
  CurrencyConfig(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳'),
  CurrencyConfig(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka', flag: '🇧🇩'),
  CurrencyConfig(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', flag: '🇨🇦'),
  CurrencyConfig(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: '🇦🇺'),
];

class BaseCurrencyNotifier extends StateNotifier<CurrencyConfig> {
  final AppSettingsRepository _repository;

  BaseCurrencyNotifier(this._repository)
      : super(const CurrencyConfig(code: 'PKR', symbol: 'Rs', name: 'Pakistani Rupee', flag: '🇵🇰')) {
    loadCurrency();
  }

  Future<void> loadCurrency() async {
    final code = await _repository.getBaseCurrencyCode();
    final symbol = await _repository.getBaseCurrencySymbol();
    final match = kSupportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => CurrencyConfig(code: code, symbol: symbol, name: code, flag: '🌐'),
    );
    state = match;
    MoneyFormatter.setCurrency(code: match.code, symbol: match.symbol);
  }

  Future<void> setCurrency(CurrencyConfig config) async {
    state = config;
    MoneyFormatter.setCurrency(code: config.code, symbol: config.symbol);
    await _repository.setBaseCurrencyCode(config.code);
    await _repository.setBaseCurrencySymbol(config.symbol);
  }
}

final baseCurrencyProvider =
    StateNotifierProvider<BaseCurrencyNotifier, CurrencyConfig>((ref) {
  final repo = ref.watch(appSettingsRepositoryProvider);
  return BaseCurrencyNotifier(repo);
});

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
