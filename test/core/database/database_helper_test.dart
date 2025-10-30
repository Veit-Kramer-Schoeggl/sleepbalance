import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/database/database_helper.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Unit tests for DatabaseHelper
///
/// Tests:
/// - Singleton pattern works correctly
/// - Database initialization creates all tables
/// - Pre-populated modules exist
/// - Indexes are created
void main() {
  // Initialize FFI for testing on non-mobile platforms
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Setup method channel mock for path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall? methodCall) async {
        if (methodCall?.method == 'getApplicationDocumentsDirectory') {
          return '/tmp/test_db';
        }
        return null;
      },
    );

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper', () {
    test('instance returns singleton', () {
      final instance1 = DatabaseHelper.instance;
      final instance2 = DatabaseHelper.instance;
      expect(instance1, equals(instance2));
    });

    test('database initialization creates all tables', () async {
      final db = await DatabaseHelper.instance.database;

      // Query all table names
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      final tableNames = tables.map((row) => row['name'] as String).toList();

      // Verify all 6 tables exist
      expect(tableNames, contains(TABLE_USERS));
      expect(tableNames, contains(TABLE_SLEEP_RECORDS));
      expect(tableNames, contains(TABLE_MODULES));
      expect(tableNames, contains(TABLE_USER_MODULE_CONFIGURATIONS));
      expect(tableNames, contains(TABLE_INTERVENTION_ACTIVITIES));
      expect(tableNames, contains(TABLE_USER_SLEEP_BASELINES));
    });

    test('modules table is pre-populated with 9 modules', () async {
      final db = await DatabaseHelper.instance.database;

      final modules = await db.query(TABLE_MODULES);

      // Should have exactly 9 modules
      expect(modules.length, equals(9));

      // Verify expected module names exist
      final moduleNames =
          modules.map((m) => m[MODULES_NAME] as String).toList();
      expect(moduleNames, contains('light'));
      expect(moduleNames, contains('sport'));
      expect(moduleNames, contains('temperature'));
      expect(moduleNames, contains('nutrition'));
      expect(moduleNames, contains('mealtime'));
      expect(moduleNames, contains('sleep_hygiene'));
      expect(moduleNames, contains('meditation'));
      expect(moduleNames, contains('journaling'));
      expect(moduleNames, contains('medication'));
    });

    test('performance indexes are created', () async {
      final db = await DatabaseHelper.instance.database;

      // Query all index names
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'",
      );

      final indexNames = indexes.map((row) => row['name'] as String).toList();

      // Verify all 6 indexes exist
      expect(indexNames, contains('idx_sleep_records_user_date'));
      expect(indexNames, contains('idx_sleep_records_quality'));
      expect(indexNames, contains('idx_intervention_activities_user_date'));
      expect(indexNames, contains('idx_intervention_activities_module'));
      expect(indexNames, contains('idx_baselines_user'));
      expect(indexNames, contains('idx_user_modules_user'));
    });

    test('users table has correct columns', () async {
      final db = await DatabaseHelper.instance.database;

      // Get table info
      final columns = await db.rawQuery('PRAGMA table_info($TABLE_USERS)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      // Verify key columns exist
      expect(columnNames, contains(USERS_ID));
      expect(columnNames, contains(USERS_EMAIL));
      expect(columnNames, contains(USERS_FIRST_NAME));
      expect(columnNames, contains(USERS_LAST_NAME));
      expect(columnNames, contains(USERS_BIRTH_DATE));
      expect(columnNames, contains(USERS_TIMEZONE));
      expect(columnNames, contains(USERS_CREATED_AT));
      expect(columnNames, contains(USERS_UPDATED_AT));
    });

    tearDownAll(() async {
      // Clean up database after tests
      await DatabaseHelper.instance.deleteDatabase();
    });
  });
}
