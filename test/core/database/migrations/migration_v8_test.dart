import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sleepbalance/core/database/migrations/migration_v8.dart';
import 'package:sleepbalance/core/utils/database_date_utils.dart';
import 'package:sleepbalance/core/utils/uuid_generator.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';

void main() {
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Migration V8 Tests', () {
    test('Migration V8 SQL is valid and executes successfully', () async {
      final db = await openDatabase(inMemoryDatabasePath);

      // Create prerequisite tables (users table needed for foreign key in future)
      await db.execute('''
        CREATE TABLE $TABLE_USERS (
          $USERS_ID TEXT PRIMARY KEY,
          $USERS_EMAIL TEXT UNIQUE NOT NULL,
          $USERS_FIRST_NAME TEXT NOT NULL,
          $USERS_LAST_NAME TEXT NOT NULL
        )
      ''');

      // Execute Migration V8
      expect(() async => await db.execute(MIGRATION_V8), returnsNormally);

      await db.close();
    });

    test('V8 creates email_verification_tokens table with correct schema', () async {
      final db = await openDatabase(inMemoryDatabasePath);

      // Create prerequisite
      await db.execute('''
        CREATE TABLE $TABLE_USERS (
          $USERS_ID TEXT PRIMARY KEY,
          $USERS_EMAIL TEXT UNIQUE NOT NULL
        )
      ''');

      // Execute Migration V8
      await db.execute(MIGRATION_V8);

      // Verify table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [TABLE_EMAIL_VERIFICATION_TOKENS],
      );
      expect(tables.length, 1);
      expect(tables.first['name'], TABLE_EMAIL_VERIFICATION_TOKENS);

      // Verify columns
      final columns = await db.rawQuery(
        'PRAGMA table_info($TABLE_EMAIL_VERIFICATION_TOKENS)',
      );

      final columnNames = columns.map((col) => col['name']).toList();
      expect(columnNames, contains(EMAIL_VERIFICATION_ID));
      expect(columnNames, contains(EMAIL_VERIFICATION_EMAIL));
      expect(columnNames, contains(EMAIL_VERIFICATION_CODE));
      expect(columnNames, contains(EMAIL_VERIFICATION_CREATED_AT));
      expect(columnNames, contains(EMAIL_VERIFICATION_EXPIRES_AT));
      expect(columnNames, contains(EMAIL_VERIFICATION_VERIFIED_AT));
      expect(columnNames, contains(EMAIL_VERIFICATION_IS_USED));

      // Verify column types
      final idColumn = columns.firstWhere((col) => col['name'] == EMAIL_VERIFICATION_ID);
      expect(idColumn['type'], 'TEXT');
      expect(idColumn['pk'], 1); // Primary key

      final isUsedColumn = columns.firstWhere((col) => col['name'] == EMAIL_VERIFICATION_IS_USED);
      expect(isUsedColumn['type'], 'INTEGER');
      expect(isUsedColumn['dflt_value'], '0'); // Default value

      await db.close();
    });

    test('V8 adds email_verified column to users table', () async {
      final db = await openDatabase(inMemoryDatabasePath);

      // Create users table without email_verified
      await db.execute('''
        CREATE TABLE $TABLE_USERS (
          $USERS_ID TEXT PRIMARY KEY,
          $USERS_EMAIL TEXT UNIQUE NOT NULL,
          $USERS_FIRST_NAME TEXT NOT NULL,
          $USERS_LAST_NAME TEXT NOT NULL
        )
      ''');

      // Execute Migration V8
      await db.execute(MIGRATION_V8);

      // Verify email_verified column exists
      final columns = await db.rawQuery('PRAGMA table_info($TABLE_USERS)');
      final columnNames = columns.map((col) => col['name']).toList();

      expect(columnNames, contains(USERS_EMAIL_VERIFIED));

      // Verify default value is 0
      final emailVerifiedColumn = columns.firstWhere(
        (col) => col['name'] == USERS_EMAIL_VERIFIED,
      );
      expect(emailVerifiedColumn['type'], 'INTEGER');
      expect(emailVerifiedColumn['dflt_value'], '0');

      await db.close();
    });

    test('V8 creates email verification indexes', () async {
      final db = await openDatabase(inMemoryDatabasePath);

      await db.execute('''
        CREATE TABLE $TABLE_USERS (
          $USERS_ID TEXT PRIMARY KEY,
          $USERS_EMAIL TEXT UNIQUE NOT NULL
        )
      ''');

      await db.execute(MIGRATION_V8);

      // Verify indexes exist
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=?",
        [TABLE_EMAIL_VERIFICATION_TOKENS],
      );

      final indexNames = indexes.map((idx) => idx['name']).toList();
      expect(indexNames, contains('idx_email_verification_email'));
      expect(indexNames, contains('idx_email_verification_expires'));

      await db.close();
    });

    test('Can insert and retrieve email verification tokens', () async {
      final db = await openDatabase(inMemoryDatabasePath);

      await db.execute('''
        CREATE TABLE $TABLE_USERS (
          $USERS_ID TEXT PRIMARY KEY,
          $USERS_EMAIL TEXT UNIQUE NOT NULL
        )
      ''');

      await db.execute(MIGRATION_V8);

      // Insert a verification token
      final verificationId = UuidGenerator.generate();
      final email = 'test@example.com';
      final code = '123456';
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(minutes: 15));

      await db.insert(TABLE_EMAIL_VERIFICATION_TOKENS, {
        EMAIL_VERIFICATION_ID: verificationId,
        EMAIL_VERIFICATION_EMAIL: email,
        EMAIL_VERIFICATION_CODE: code,
        EMAIL_VERIFICATION_CREATED_AT: DatabaseDateUtils.toTimestamp(createdAt),
        EMAIL_VERIFICATION_EXPIRES_AT: DatabaseDateUtils.toTimestamp(expiresAt),
        EMAIL_VERIFICATION_VERIFIED_AT: null,
        EMAIL_VERIFICATION_IS_USED: 0,
      });

      // Retrieve the token
      final result = await db.query(
        TABLE_EMAIL_VERIFICATION_TOKENS,
        where: '$EMAIL_VERIFICATION_EMAIL = ?',
        whereArgs: [email],
      );

      expect(result.length, 1);
      expect(result.first[EMAIL_VERIFICATION_ID], verificationId);
      expect(result.first[EMAIL_VERIFICATION_EMAIL], email);
      expect(result.first[EMAIL_VERIFICATION_CODE], code);
      expect(result.first[EMAIL_VERIFICATION_IS_USED], 0);

      // Verify DateTime round-trip
      final retrievedCreatedAt = DatabaseDateUtils.fromString(
        result.first[EMAIL_VERIFICATION_CREATED_AT] as String,
      );
      expect(retrievedCreatedAt.difference(createdAt).inSeconds, lessThan(2));

      await db.close();
    });

    test('Can update email_verified status in users table', () async {
      final db = await openDatabase(inMemoryDatabasePath);

      await db.execute('''
        CREATE TABLE $TABLE_USERS (
          $USERS_ID TEXT PRIMARY KEY,
          $USERS_EMAIL TEXT UNIQUE NOT NULL,
          $USERS_FIRST_NAME TEXT NOT NULL,
          $USERS_LAST_NAME TEXT NOT NULL
        )
      ''');

      await db.execute(MIGRATION_V8);

      // Insert a user
      final userId = UuidGenerator.generate();
      await db.insert(TABLE_USERS, {
        USERS_ID: userId,
        USERS_EMAIL: 'test@example.com',
        USERS_FIRST_NAME: 'Test',
        USERS_LAST_NAME: 'User',
        USERS_EMAIL_VERIFIED: 0,
      });

      // Verify initial state
      var user = await db.query(TABLE_USERS, where: '$USERS_ID = ?', whereArgs: [userId]);
      expect(user.first[USERS_EMAIL_VERIFIED], 0);

      // Update email_verified to true
      await db.update(
        TABLE_USERS,
        {USERS_EMAIL_VERIFIED: 1},
        where: '$USERS_ID = ?',
        whereArgs: [userId],
      );

      // Verify updated state
      user = await db.query(TABLE_USERS, where: '$USERS_ID = ?', whereArgs: [userId]);
      expect(user.first[USERS_EMAIL_VERIFIED], 1);

      await db.close();
    });

    test('Email verification code expires correctly', () async {
      final db = await openDatabase(inMemoryDatabasePath);

      await db.execute('''
        CREATE TABLE $TABLE_USERS (
          $USERS_ID TEXT PRIMARY KEY,
          $USERS_EMAIL TEXT UNIQUE NOT NULL
        )
      ''');

      await db.execute(MIGRATION_V8);

      // Insert an expired verification token
      final expiredId = UuidGenerator.generate();
      final expiredAt = DateTime.now().subtract(const Duration(minutes: 20));
      final createdAt = expiredAt.subtract(const Duration(minutes: 15));

      await db.insert(TABLE_EMAIL_VERIFICATION_TOKENS, {
        EMAIL_VERIFICATION_ID: expiredId,
        EMAIL_VERIFICATION_EMAIL: 'expired@example.com',
        EMAIL_VERIFICATION_CODE: '111111',
        EMAIL_VERIFICATION_CREATED_AT: DatabaseDateUtils.toTimestamp(createdAt),
        EMAIL_VERIFICATION_EXPIRES_AT: DatabaseDateUtils.toTimestamp(expiredAt),
        EMAIL_VERIFICATION_VERIFIED_AT: null,
        EMAIL_VERIFICATION_IS_USED: 0,
      });

      // Query for non-expired tokens
      final now = DateTime.now();
      final nonExpiredTokens = await db.query(
        TABLE_EMAIL_VERIFICATION_TOKENS,
        where: '$EMAIL_VERIFICATION_EXPIRES_AT > ? AND $EMAIL_VERIFICATION_IS_USED = 0',
        whereArgs: [DatabaseDateUtils.toTimestamp(now)],
      );

      // Should be empty since token is expired
      expect(nonExpiredTokens.length, 0);

      await db.close();
    });
  });
}
