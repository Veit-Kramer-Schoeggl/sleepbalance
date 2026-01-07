import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sleepbalance/core/database/database_helper.dart';
import 'package:sleepbalance/core/database/migrations/migration_v8.dart';
import 'package:sleepbalance/features/auth/data/datasources/email_verification_local_datasource.dart';
import 'package:sleepbalance/features/auth/data/repositories/email_verification_repository_impl.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';

void main() {
  late Database db;
  late DatabaseHelper databaseHelper;
  late EmailVerificationLocalDataSource dataSource;
  late EmailVerificationRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create in-memory database with minimal schema
    db = await openDatabase(inMemoryDatabasePath);

    // Create only the tables we need for testing
    await db.execute('''
      CREATE TABLE $TABLE_USERS (
        $USERS_ID TEXT PRIMARY KEY,
        $USERS_EMAIL TEXT UNIQUE NOT NULL
      )
    ''');

    // Execute Migration V8 (all 4 parts)
    await db.execute(MIGRATION_V8_CREATE_TABLE);
    await db.execute(MIGRATION_V8_INDEX_EMAIL);
    await db.execute(MIGRATION_V8_INDEX_EXPIRES);
    await db.execute(MIGRATION_V8_ALTER_USERS);

    // Create test database helper that returns our test database
    databaseHelper = _TestDatabaseHelper(db);
    dataSource = EmailVerificationLocalDataSource(databaseHelper);
    repository = EmailVerificationRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await db.close();
  });

  group('createVerificationCode', () {
    test('Creates a 6-digit verification code', () async {
      final email = 'test@example.com';

      final code = await repository.createVerificationCode(email);

      expect(code, isA<String>());
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
      expect(int.parse(code), greaterThanOrEqualTo(100000));
      expect(int.parse(code), lessThanOrEqualTo(999999));
    });

    test('Invalidates previous codes for same email', () async {
      final email = 'test@example.com';

      // Create first code
      final code1 = await repository.createVerificationCode(email);

      // Create second code
      final code2 = await repository.createVerificationCode(email);

      // First code should be invalidated
      final verification1 = await repository.getActiveVerification(email);
      expect(verification1, isNotNull);
      expect(verification1!.code, code2);
      expect(verification1.code, isNot(equals(code1)));
    });

    test('Different emails get different codes', () async {
      final email1 = 'user1@example.com';
      final email2 = 'user2@example.com';

      final code1 = await repository.createVerificationCode(email1);
      final code2 = await repository.createVerificationCode(email2);

      // Codes should be different (statistically very unlikely to be same)
      expect(code1, isNot(equals(code2)));
    });

    test('Verification record is stored in database', () async {
      final email = 'test@example.com';

      await repository.createVerificationCode(email);

      final verification = await repository.getActiveVerification(email);
      expect(verification, isNotNull);
      expect(verification!.email, email);
      expect(verification.isUsed, false);
    });

    test('Expiration is set to 15 minutes', () async {
      final email = 'test@example.com';

      await repository.createVerificationCode(email);

      final verification = await repository.getActiveVerification(email);
      expect(verification, isNotNull);

      final expirationDuration = verification!.expiresAt.difference(verification.createdAt);
      expect(expirationDuration.inMinutes, 15);
    });
  });

  group('verifyCode', () {
    test('Correct code returns true', () async {
      final email = 'test@example.com';
      final code = await repository.createVerificationCode(email);

      final isValid = await repository.verifyCode(email, code);

      expect(isValid, true);
    });

    test('Incorrect code returns false', () async {
      final email = 'test@example.com';
      await repository.createVerificationCode(email);

      final isValid = await repository.verifyCode(email, '999999');

      expect(isValid, false);
    });

    test('Code for different email returns false', () async {
      final email1 = 'user1@example.com';
      final email2 = 'user2@example.com';

      final code = await repository.createVerificationCode(email1);

      final isValid = await repository.verifyCode(email2, code);

      expect(isValid, false);
    });

    test('Marks code as used after successful verification', () async {
      final email = 'test@example.com';
      final code = await repository.createVerificationCode(email);

      await repository.verifyCode(email, code);

      // Try to verify again - should fail because code is now used
      final isValidSecondTime = await repository.verifyCode(email, code);
      expect(isValidSecondTime, false);
    });

    test('Expired code returns false', () async {
      final email = 'test@example.com';
      final code = await repository.createVerificationCode(email);

      // Manually expire the code by updating database
      final verification = await repository.getActiveVerification(email);
      final expiredAt = DateTime.now().subtract(const Duration(minutes: 20));

      await db.update(
        TABLE_EMAIL_VERIFICATION_TOKENS,
        {'expires_at': expiredAt.toIso8601String()},
        where: 'id = ?',
        whereArgs: [verification!.id],
      );

      final isValid = await repository.verifyCode(email, code);

      expect(isValid, false);
    });

    test('No verification record returns false', () async {
      final email = 'nonexistent@example.com';

      final isValid = await repository.verifyCode(email, '123456');

      expect(isValid, false);
    });
  });

  group('getActiveVerification', () {
    test('Returns verification for existing code', () async {
      final email = 'test@example.com';
      final code = await repository.createVerificationCode(email);

      final verification = await repository.getActiveVerification(email);

      expect(verification, isNotNull);
      expect(verification!.email, email);
      expect(verification.code, code);
      expect(verification.isUsed, false);
    });

    test('Returns null for nonexistent email', () async {
      final verification = await repository.getActiveVerification('nonexistent@example.com');

      expect(verification, isNull);
    });

    test('Returns null for expired code', () async {
      final email = 'test@example.com';
      await repository.createVerificationCode(email);

      // Manually expire the code
      final verification = await repository.getActiveVerification(email);
      final expiredAt = DateTime.now().subtract(const Duration(minutes: 20));

      await db.update(
        TABLE_EMAIL_VERIFICATION_TOKENS,
        {'expires_at': expiredAt.toIso8601String()},
        where: 'id = ?',
        whereArgs: [verification!.id],
      );

      final activeVerification = await repository.getActiveVerification(email);

      expect(activeVerification, isNull);
    });

    test('Returns null for used code', () async {
      final email = 'test@example.com';
      final code = await repository.createVerificationCode(email);

      // Use the code
      await repository.verifyCode(email, code);

      final verification = await repository.getActiveVerification(email);

      expect(verification, isNull);
    });

    test('Returns most recent code when multiple exist', () async {
      final email = 'test@example.com';

      await repository.createVerificationCode(email);
      await Future.delayed(const Duration(milliseconds: 100));
      final latestCode = await repository.createVerificationCode(email);

      final verification = await repository.getActiveVerification(email);

      expect(verification, isNotNull);
      expect(verification!.code, latestCode);
    });
  });

  group('markAsUsed', () {
    test('Marks verification as used', () async {
      final email = 'test@example.com';
      await repository.createVerificationCode(email);

      final verification = await repository.getActiveVerification(email);
      await repository.markAsUsed(verification!.id);

      // Should no longer be active
      final activeVerification = await repository.getActiveVerification(email);
      expect(activeVerification, isNull);
    });

    test('Sets verified_at timestamp', () async {
      final email = 'test@example.com';
      await repository.createVerificationCode(email);

      final verification = await repository.getActiveVerification(email);
      final beforeMark = DateTime.now();

      await repository.markAsUsed(verification!.id);

      // Read directly from database
      final results = await db.query(
        TABLE_EMAIL_VERIFICATION_TOKENS,
        where: 'id = ?',
        whereArgs: [verification.id],
      );

      expect(results.first['verified_at'], isNotNull);
      final verifiedAt = DateTime.parse(results.first['verified_at'] as String);
      expect(verifiedAt.isAfter(beforeMark.subtract(const Duration(seconds: 1))), true);
    });
  });

  group('cleanupExpiredTokens', () {
    test('Deletes tokens expired more than 24 hours ago', () async {
      final email = 'test@example.com';
      await repository.createVerificationCode(email);

      // Manually set expiration to 25 hours ago
      final verification = await repository.getActiveVerification(email);
      final expiredAt = DateTime.now().subtract(const Duration(hours: 25));

      await db.update(
        TABLE_EMAIL_VERIFICATION_TOKENS,
        {'expires_at': expiredAt.toIso8601String()},
        where: 'id = ?',
        whereArgs: [verification!.id],
      );

      await repository.cleanupExpiredTokens();

      // Verification should be deleted
      final results = await db.query(
        TABLE_EMAIL_VERIFICATION_TOKENS,
        where: 'id = ?',
        whereArgs: [verification.id],
      );

      expect(results, isEmpty);
    });

    test('Keeps tokens expired less than 24 hours ago', () async {
      final email = 'test@example.com';
      await repository.createVerificationCode(email);

      // Set expiration to 23 hours ago
      final verification = await repository.getActiveVerification(email);
      final expiredAt = DateTime.now().subtract(const Duration(hours: 23));

      await db.update(
        TABLE_EMAIL_VERIFICATION_TOKENS,
        {'expires_at': expiredAt.toIso8601String()},
        where: 'id = ?',
        whereArgs: [verification!.id],
      );

      await repository.cleanupExpiredTokens();

      // Verification should still exist
      final results = await db.query(
        TABLE_EMAIL_VERIFICATION_TOKENS,
        where: 'id = ?',
        whereArgs: [verification.id],
      );

      expect(results, isNotEmpty);
    });

    test('Keeps active (non-expired) tokens', () async {
      final email = 'test@example.com';
      await repository.createVerificationCode(email);

      await repository.cleanupExpiredTokens();

      final verification = await repository.getActiveVerification(email);
      expect(verification, isNotNull);
    });
  });
}

/// Test implementation of DatabaseHelper that uses provided database
class _TestDatabaseHelper implements DatabaseHelper {
  final Database _db;

  _TestDatabaseHelper(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  Future<void> close() async {
    await _db.close();
  }

  @override
  Future<void> deleteDatabase() async {
    // No-op for test
  }
}
