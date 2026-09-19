import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:build_ledger/features/settings/domain/entities/contractor_profile.dart';
import 'package:build_ledger/features/settings/data/app_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ContractorProfile Entity Tests', () {
    test('Empty profile is not configured', () {
      final profile = ContractorProfile.empty();
      expect(profile.isConfigured, isFalse);
      expect(profile.name, isEmpty);
      expect(profile.taxId, isEmpty);
    });

    test('Configured profile with name is marked configured', () {
      const profile = ContractorProfile(
        name: 'Apex Builders (Pvt) Ltd',
        taxId: '1234567-8',
        phone: '0300-1112223',
        address: 'Blue Area, Islamabad',
      );
      expect(profile.isConfigured, isTrue);
      expect(profile.name, equals('Apex Builders (Pvt) Ltd'));
    });

    test('Serializes to and from Map correctly', () {
      const original = ContractorProfile(
        name: 'BuildLedger Construction',
        taxId: '7492019-3',
        phone: '042-3571234',
        email: 'site@buildledger.com',
        address: 'Plot 42, Commercial Zone, Lahore',
      );

      final map = original.toMap();
      final restored = ContractorProfile.fromMap(map);

      expect(restored, equals(original));
      expect(restored.name, equals('BuildLedger Construction'));
      expect(restored.taxId, equals('7492019-3'));
      expect(restored.phone, equals('042-3571234'));
      expect(restored.email, equals('site@buildledger.com'));
      expect(restored.address, equals('Plot 42, Commercial Zone, Lahore'));
    });
  });

  group('SharedPrefsAppSettingsRepository Tests', () {
    test('Default values are correct', () async {
      final repo = SharedPrefsAppSettingsRepository();

      final profile = await repo.getContractorProfile();
      expect(profile.isConfigured, isFalse);

      final shiftHoursX100 = await repo.getStandardLabourShiftHoursX100();
      expect(shiftHoursX100, equals(800)); // 8.0 hours

      final backupTimestamp = await repo.getLastBackupTimestamp();
      expect(backupTimestamp, isNull);

      expect(await repo.getBaseCurrencyCode(), equals('PKR'));
      expect(await repo.getBaseCurrencySymbol(), equals('Rs'));
      expect(await repo.hasSeenProfileOnboarding(), isFalse);
    });

    test('Persists and restores base currency standard', () async {
      final repo = SharedPrefsAppSettingsRepository();

      await repo.setBaseCurrencyCode('AED');
      await repo.setBaseCurrencySymbol('AED');

      expect(await repo.getBaseCurrencyCode(), equals('AED'));
      expect(await repo.getBaseCurrencySymbol(), equals('AED'));
    });

    test('Persists onboarding seen state', () async {
      final repo = SharedPrefsAppSettingsRepository();

      expect(await repo.hasSeenProfileOnboarding(), isFalse);
      await repo.setSeenProfileOnboarding(true);
      expect(await repo.hasSeenProfileOnboarding(), isTrue);
    });

    test('Persists and restores contractor profile', () async {
      final repo = SharedPrefsAppSettingsRepository();

      const profile = ContractorProfile(
        name: 'Indus Construction Corp',
        taxId: '9876543-2',
        phone: '0321-9988776',
        address: 'Gulberg III, Lahore',
      );

      await repo.saveContractorProfile(profile);

      final restored = await repo.getContractorProfile();
      expect(restored.isConfigured, isTrue);
      expect(restored.name, equals('Indus Construction Corp'));
      expect(restored.taxId, equals('9876543-2'));
      expect(restored.phone, equals('0321-9988776'));
      expect(restored.address, equals('Gulberg III, Lahore'));
    });

    test('Persists and restores standard labour shift hours', () async {
      final repo = SharedPrefsAppSettingsRepository();

      await repo.setStandardLabourShiftHoursX100(1000); // 10.0 hours
      final hours = await repo.getStandardLabourShiftHoursX100();
      expect(hours, equals(1000));

      await repo.setStandardLabourShiftHoursX100(600); // 6.0 hours
      final updated = await repo.getStandardLabourShiftHoursX100();
      expect(updated, equals(600));
    });

    test('Persists and restores last backup timestamp', () async {
      final repo = SharedPrefsAppSettingsRepository();
      final now = DateTime(2025, 6, 15, 14, 30);

      await repo.setLastBackupTimestamp(now);
      final restored = await repo.getLastBackupTimestamp();
      expect(restored, equals(now));
    });
  });
}
