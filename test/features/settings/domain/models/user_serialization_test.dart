import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/settings/domain/models/user.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';

void main() {
  group('User Serialization', () {
    group('JSON serialization (toJson/fromJson)', () {
      test('toJson converts model to JSON map', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          birthDate: birthDate,
          timezone: 'UTC',
          targetSleepDuration: 480,
          createdAt: now,
          updatedAt: now,
        );

        final json = user.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], 'user-123');
        expect(json['email'], 'test@example.com');
        expect(json['firstName'], 'John');
        expect(json['lastName'], 'Doe');
        expect(json['targetSleepDuration'], 480);
        expect(json['timezone'], 'UTC');
      });

      test('fromJson creates model from JSON map', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'firstName': 'John',
          'lastName': 'Doe',
          'birthDate': '1990-05-15T00:00:00.000',
          'timezone': 'UTC',
          'targetSleepDuration': 480,
          'preferredUnitSystem': 'metric',
          'language': 'en',
          'hasSleepDisorder': false,
          'takesSleepMedication': false,
          'createdAt': '2025-11-01T10:00:00.000',
          'updatedAt': '2025-11-01T10:00:00.000',
        };

        final user = User.fromJson(json);

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.firstName, 'John');
        expect(user.lastName, 'Doe');
        expect(user.targetSleepDuration, 480);
        expect(user.timezone, 'UTC');
      });

      test('JSON round-trip preserves data', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final original = User(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          birthDate: birthDate,
          timezone: 'Europe/Berlin',
          targetSleepDuration: 480,
          createdAt: now,
          updatedAt: now,
        );

        final json = original.toJson();
        final restored = User.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.email, original.email);
        expect(restored.firstName, original.firstName);
        expect(restored.lastName, original.lastName);
        expect(restored.targetSleepDuration, original.targetSleepDuration);
        expect(restored.timezone, original.timezone);
      });
    });

    group('Database serialization (toDatabase/fromDatabase)', () {
      test('toDatabase converts DateTime to ISO 8601 strings', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          birthDate: birthDate,
          timezone: 'UTC',
          createdAt: now,
          updatedAt: now,
        );

        final dbMap = user.toDatabase();

        // Verify uses DatabaseConstants
        expect(dbMap.containsKey(USERS_ID), isTrue);
        expect(dbMap.containsKey(USERS_EMAIL), isTrue);
        expect(dbMap.containsKey(USERS_FIRST_NAME), isTrue);
        expect(dbMap.containsKey(USERS_BIRTH_DATE), isTrue);

        // Verify date string format (date-only)
        expect(dbMap[USERS_BIRTH_DATE], '1990-05-15');

        // Verify timestamp format (includes time)
        expect(dbMap[USERS_CREATED_AT], contains('T'));
        expect(dbMap[USERS_UPDATED_AT], contains('T'));
      });

      test('toDatabase converts boolean to INTEGER (0/1)', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final userWithDisorder = User(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          birthDate: birthDate,
          timezone: 'UTC',
          hasSleepDisorder: true,
          takesSleepMedication: true,
          createdAt: now,
          updatedAt: now,
        );

        final dbMap = userWithDisorder.toDatabase();

        expect(dbMap[USERS_HAS_SLEEP_DISORDER], 1);
        expect(dbMap[USERS_TAKES_SLEEP_MEDICATION], 1);

        final userWithoutDisorder = User(
          id: 'user-456',
          email: 'test2@example.com',
          firstName: 'Jane',
          lastName: 'Smith',
          birthDate: birthDate,
          timezone: 'UTC',
          hasSleepDisorder: false,
          takesSleepMedication: false,
          createdAt: now,
          updatedAt: now,
        );

        final dbMap2 = userWithoutDisorder.toDatabase();

        expect(dbMap2[USERS_HAS_SLEEP_DISORDER], 0);
        expect(dbMap2[USERS_TAKES_SLEEP_MEDICATION], 0);
      });

      test('toDatabase handles nullable fields', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          birthDate: birthDate,
          timezone: 'UTC',
          createdAt: now,
          updatedAt: now,
          // All nullable fields omitted
        );

        final dbMap = user.toDatabase();

        expect(dbMap[USERS_PASSWORD_HASH], isNull);
        expect(dbMap[USERS_TARGET_SLEEP_DURATION], isNull);
        expect(dbMap[USERS_TARGET_BED_TIME], isNull);
        expect(dbMap[USERS_TARGET_WAKE_TIME], isNull);
        expect(dbMap[USERS_SLEEP_DISORDER_TYPE], isNull);
      });

      test('toDatabase always sets is_deleted to 0', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          birthDate: birthDate,
          timezone: 'UTC',
          createdAt: now,
          updatedAt: now,
        );

        final dbMap = user.toDatabase();

        expect(dbMap[USERS_IS_DELETED], 0);
      });

      test('fromDatabase converts strings to DateTime', () {
        final dbMap = {
          USERS_ID: 'user-123',
          USERS_EMAIL: 'test@example.com',
          USERS_FIRST_NAME: 'John',
          USERS_LAST_NAME: 'Doe',
          USERS_BIRTH_DATE: '1990-05-15',
          USERS_TIMEZONE: 'UTC',
          USERS_HAS_SLEEP_DISORDER: 0,
          USERS_TAKES_SLEEP_MEDICATION: 0,
          USERS_PREFERRED_UNIT_SYSTEM: 'metric',
          USERS_LANGUAGE: 'en',
          USERS_CREATED_AT: '2025-11-01T10:00:00.000',
          USERS_UPDATED_AT: '2025-11-01T10:00:00.000',
        };

        final user = User.fromDatabase(dbMap);

        expect(user.birthDate, isA<DateTime>());
        expect(user.createdAt, isA<DateTime>());
        expect(user.updatedAt, isA<DateTime>());

        // Verify specific values
        expect(user.birthDate.year, 1990);
        expect(user.birthDate.month, 5);
        expect(user.birthDate.day, 15);
      });

      test('fromDatabase converts INTEGER to boolean', () {
        final dbMap = {
          USERS_ID: 'user-123',
          USERS_EMAIL: 'test@example.com',
          USERS_FIRST_NAME: 'John',
          USERS_LAST_NAME: 'Doe',
          USERS_BIRTH_DATE: '1990-05-15',
          USERS_TIMEZONE: 'UTC',
          USERS_HAS_SLEEP_DISORDER: 1,
          USERS_TAKES_SLEEP_MEDICATION: 1,
          USERS_PREFERRED_UNIT_SYSTEM: 'metric',
          USERS_LANGUAGE: 'en',
          USERS_CREATED_AT: '2025-11-01T10:00:00.000',
          USERS_UPDATED_AT: '2025-11-01T10:00:00.000',
        };

        final user = User.fromDatabase(dbMap);

        expect(user.hasSleepDisorder, true);
        expect(user.takesSleepMedication, true);

        final dbMap2 = {
          USERS_ID: 'user-456',
          USERS_EMAIL: 'test2@example.com',
          USERS_FIRST_NAME: 'Jane',
          USERS_LAST_NAME: 'Smith',
          USERS_BIRTH_DATE: '1990-05-15',
          USERS_TIMEZONE: 'UTC',
          USERS_HAS_SLEEP_DISORDER: 0,
          USERS_TAKES_SLEEP_MEDICATION: 0,
          USERS_PREFERRED_UNIT_SYSTEM: 'metric',
          USERS_LANGUAGE: 'en',
          USERS_CREATED_AT: '2025-11-01T10:00:00.000',
          USERS_UPDATED_AT: '2025-11-01T10:00:00.000',
        };

        final user2 = User.fromDatabase(dbMap2);

        expect(user2.hasSleepDisorder, false);
        expect(user2.takesSleepMedication, false);
      });

      test('fromDatabase handles nullable fields correctly', () {
        final dbMap = {
          USERS_ID: 'user-123',
          USERS_EMAIL: 'test@example.com',
          USERS_FIRST_NAME: 'John',
          USERS_LAST_NAME: 'Doe',
          USERS_BIRTH_DATE: '1990-05-15',
          USERS_TIMEZONE: 'UTC',
          USERS_HAS_SLEEP_DISORDER: 0,
          USERS_TAKES_SLEEP_MEDICATION: 0,
          USERS_PREFERRED_UNIT_SYSTEM: 'metric',
          USERS_LANGUAGE: 'en',
          USERS_CREATED_AT: '2025-11-01T10:00:00.000',
          USERS_UPDATED_AT: '2025-11-01T10:00:00.000',
          // Nullable fields explicitly null
          USERS_PASSWORD_HASH: null,
          USERS_TARGET_SLEEP_DURATION: null,
          USERS_TARGET_BED_TIME: null,
          USERS_TARGET_WAKE_TIME: null,
          USERS_SLEEP_DISORDER_TYPE: null,
        };

        final user = User.fromDatabase(dbMap);

        expect(user.passwordHash, isNull);
        expect(user.targetSleepDuration, isNull);
        expect(user.targetBedTime, isNull);
        expect(user.targetWakeTime, isNull);
        expect(user.sleepDisorderType, isNull);
      });

      test('database round-trip preserves all data', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final original = User(
          id: 'user-123',
          email: 'john.doe@example.com',
          passwordHash: 'hashed',
          firstName: 'John',
          lastName: 'Doe',
          birthDate: birthDate,
          timezone: 'Europe/Berlin',
          targetSleepDuration: 480,
          targetBedTime: '22:00',
          targetWakeTime: '06:00',
          hasSleepDisorder: true,
          sleepDisorderType: 'insomnia',
          takesSleepMedication: true,
          preferredUnitSystem: 'imperial',
          language: 'de',
          createdAt: now,
          updatedAt: now,
        );

        final dbMap = original.toDatabase();
        final restored = User.fromDatabase(dbMap);

        // Compare all fields
        expect(restored.id, original.id);
        expect(restored.email, original.email);
        expect(restored.passwordHash, original.passwordHash);
        expect(restored.firstName, original.firstName);
        expect(restored.lastName, original.lastName);
        expect(
          restored.birthDate.toIso8601String(),
          original.birthDate.toIso8601String(),
        );
        expect(restored.timezone, original.timezone);
        expect(restored.targetSleepDuration, original.targetSleepDuration);
        expect(restored.targetBedTime, original.targetBedTime);
        expect(restored.targetWakeTime, original.targetWakeTime);
        expect(restored.hasSleepDisorder, original.hasSleepDisorder);
        expect(restored.sleepDisorderType, original.sleepDisorderType);
        expect(restored.takesSleepMedication, original.takesSleepMedication);
        expect(restored.preferredUnitSystem, original.preferredUnitSystem);
        expect(restored.language, original.language);
      });
    });
  });
}