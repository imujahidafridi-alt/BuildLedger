import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:build_ledger/features/settings/domain/entities/contractor_profile.dart';

abstract class AppSettingsRepository {
  Future<ContractorProfile> getContractorProfile();
  Future<void> saveContractorProfile(ContractorProfile profile);

  Future<int> getStandardLabourShiftHoursX100();
  Future<void> setStandardLabourShiftHoursX100(int hoursX100);

  Future<DateTime?> getLastBackupTimestamp();
  Future<void> setLastBackupTimestamp(DateTime timestamp);

  Future<String> getBaseCurrencyCode();
  Future<void> setBaseCurrencyCode(String code);
  Future<String> getBaseCurrencySymbol();
  Future<void> setBaseCurrencySymbol(String symbol);

  Future<bool> hasSeenProfileOnboarding();
  Future<void> setSeenProfileOnboarding(bool seen);
}

class SharedPrefsAppSettingsRepository implements AppSettingsRepository {
  static const String _kContractorProfileKey = 'buildledger_contractor_profile';
  static const String _kShiftHoursKey = 'buildledger_shift_hours_x100';
  static const String _kLastBackupTimestampKey = 'buildledger_last_backup_timestamp';
  static const String _kBaseCurrencyCodeKey = 'buildledger_base_currency_code';
  static const String _kBaseCurrencySymbolKey = 'buildledger_base_currency_symbol';
  static const String _kSeenProfileOnboardingKey = 'buildledger_seen_profile_onboarding';

  final SharedPreferences? _prefs;

  SharedPrefsAppSettingsRepository([this._prefs]);

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  @override
  Future<ContractorProfile> getContractorProfile() async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString(_kContractorProfileKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return ContractorProfile.fromMap(map);
      }
    } catch (_) {}
    return ContractorProfile.empty();
  }

  @override
  Future<void> saveContractorProfile(ContractorProfile profile) async {
    final prefs = await _instance;
    final jsonStr = jsonEncode(profile.toMap());
    await prefs.setString(_kContractorProfileKey, jsonStr);
  }

  @override
  Future<int> getStandardLabourShiftHoursX100() async {
    try {
      final prefs = await _instance;
      final val = prefs.getInt(_kShiftHoursKey);
      if (val != null && val > 0) return val;
    } catch (_) {}
    return 800; // Default: 8.0 hours
  }

  @override
  Future<void> setStandardLabourShiftHoursX100(int hoursX100) async {
    final prefs = await _instance;
    await prefs.setInt(_kShiftHoursKey, hoursX100);
  }

  @override
  Future<DateTime?> getLastBackupTimestamp() async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString(_kLastBackupTimestampKey);
      if (raw != null && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> setLastBackupTimestamp(DateTime timestamp) async {
    final prefs = await _instance;
    await prefs.setString(_kLastBackupTimestampKey, timestamp.toIso8601String());
  }

  @override
  Future<String> getBaseCurrencyCode() async {
    try {
      final prefs = await _instance;
      return prefs.getString(_kBaseCurrencyCodeKey) ?? 'PKR';
    } catch (_) {}
    return 'PKR';
  }

  @override
  Future<void> setBaseCurrencyCode(String code) async {
    final prefs = await _instance;
    await prefs.setString(_kBaseCurrencyCodeKey, code);
  }

  @override
  Future<String> getBaseCurrencySymbol() async {
    try {
      final prefs = await _instance;
      return prefs.getString(_kBaseCurrencySymbolKey) ?? 'Rs';
    } catch (_) {}
    return 'Rs';
  }

  @override
  Future<void> setBaseCurrencySymbol(String symbol) async {
    final prefs = await _instance;
    await prefs.setString(_kBaseCurrencySymbolKey, symbol);
  }

  @override
  Future<bool> hasSeenProfileOnboarding() async {
    try {
      final prefs = await _instance;
      return prefs.getBool(_kSeenProfileOnboardingKey) ?? false;
    } catch (_) {}
    return false;
  }

  @override
  Future<void> setSeenProfileOnboarding(bool seen) async {
    final prefs = await _instance;
    await prefs.setBool(_kSeenProfileOnboardingKey, seen);
  }
}
