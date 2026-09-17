import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:build_ledger/app/theme/theme_mode_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeModeNotifier Tests', () {
    test('Defaults strictly to ThemeMode.system', () {
      final notifier = ThemeModeNotifier();
      expect(notifier.state, equals(ThemeMode.system));
    });

    test('cycleTheme cycles through System -> Light -> Dark -> System', () async {
      final notifier = ThemeModeNotifier();
      expect(notifier.state, equals(ThemeMode.system));

      await notifier.cycleTheme();
      expect(notifier.state, equals(ThemeMode.light));

      await notifier.cycleTheme();
      expect(notifier.state, equals(ThemeMode.dark));

      await notifier.cycleTheme();
      expect(notifier.state, equals(ThemeMode.system));
    });

    test('setThemeMode updates state directly', () async {
      final notifier = ThemeModeNotifier();

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, equals(ThemeMode.dark));

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, equals(ThemeMode.light));

      await notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, equals(ThemeMode.system));
    });
  });
}
