import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:build_ledger/core/database/database_helper.dart';
import 'package:build_ledger/features/expenses/data/repositories/expense_repository_impl.dart';

void main() {
  late Database db;
  late ExpenseRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await DatabaseHelper.createSchema(db, 2);
        },
      ),
    );

    DatabaseHelper.setMockDatabase(db);
    repository = ExpenseRepositoryImpl(dbHelper: DatabaseHelper());
  });

  tearDown(() async {
    await db.close();
    DatabaseHelper.setMockDatabase(null);
  });

  group('Category Search Pakistani Aliases Test', () {
    final searchExpectations = <String, String>{
      'saria': 'Steel / Saria',
      'rebar': 'Steel / Saria',
      'rait': 'Sand',
      'ret': 'Sand',
      'bajri': 'Crush / Aggregate',
      'eent': 'Bricks',
      'mistri': 'Mason',
      'mazdoor': 'Helper',
      'dpc': 'Damp Proof Course',
      'sanitary': 'Bathrooms & Sanitary',
      'commode': 'WC / Toilet',
      'basin': 'Wash Basin',
      'shuttering': 'Shuttering / Formwork',
      'sewerage': 'Sewerage',
      'tanki': 'Water Tanks',
      'chokhat': 'Door Frames',
      'darwaza': 'Doors & Windows',
      'pop': 'POP',
      'gypsum': 'Gypsum',
    };

    for (final entry in searchExpectations.entries) {
      test('Search query "${entry.key}" returns category containing "${entry.value}"', () async {
        final result = await repository.searchCategories(entry.key);
        expect(result.isSuccess, isTrue);
        final matches = result.dataOrNull!;
        expect(
          matches.isNotEmpty,
          isTrue,
          reason: 'Expected query "${entry.key}" to return matches, but got empty list.',
        );

        final found = matches.any((c) =>
            c.name.toLowerCase().contains(entry.value.toLowerCase()) ||
            c.aliases.any((a) => a.toLowerCase().contains(entry.value.toLowerCase())));
        expect(
          found,
          isTrue,
          reason: 'Expected query "${entry.key}" to match "${entry.value}". Got: ${matches.map((c) => c.name).take(3).toList()}',
        );
      });
    }

    test('Search handles uppercase, leading whitespace, and punctuation smoothly', () async {
      final result1 = await repository.searchCategories('  SARIA  ');
      expect(result1.isSuccess, isTrue);
      expect(result1.dataOrNull!.first.name, contains('Steel'));

      final result2 = await repository.searchCategories('BaJrI');
      expect(result2.isSuccess, isTrue);
      expect(result2.dataOrNull!.first.name, contains('Crush'));
    });
  });
}
