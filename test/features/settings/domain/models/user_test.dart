import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/settings/domain/models/user.dart';

void main() {
  group('User', () {
    group('Constructor and basic properties', () {
      test('creates User with required fields only', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 1, 1);

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

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.firstName, 'John');
        expect(user.lastName, 'Doe');
        expect(user.birthDate, birthDate);
        expect(user.timezone, 'UTC');
        expect(user.createdAt, now);
        expect(user.updatedAt, now);

        // Verify nullable fields are null
        expect(user.passwordHash, isNull);
        expect(user.targetSleepDuration, isNull);
        expect(user.targetBedTime, isNull);
        expect(user.targetWakeTime, isNull);
        expect(user.sleepDisorderType, isNull);

        // Verify default values
        expect(user.hasSleepDisorder, false);
        expect(user.takesSleepMedication, false);
        expect(user.preferredUnitSystem, 'metric');
        expect(user.language, 'en');
      });

      test('creates User with all fields', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final user = User(
          id: 'user-123',
          email: 'john.doe@example.com',
          passwordHash: 'hashed_password',
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

        expect(user.id, 'user-123');
        expect(user.email, 'john.doe@example.com');
        expect(user.passwordHash, 'hashed_password');
        expect(user.firstName, 'John');
        expect(user.lastName, 'Doe');
        expect(user.birthDate, birthDate);
        expect(user.timezone, 'Europe/Berlin');
        expect(user.targetSleepDuration, 480);
        expect(user.targetBedTime, '22:00');
        expect(user.targetWakeTime, '06:00');
        expect(user.hasSleepDisorder, true);
        expect(user.sleepDisorderType, 'insomnia');
        expect(user.takesSleepMedication, true);
        expect(user.preferredUnitSystem, 'imperial');
        expect(user.language, 'de');
        expect(user.createdAt, now);
        expect(user.updatedAt, now);
      });
    });

    group('copyWith method', () {
      test('copyWith updates specified fields', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final original = User(
          id: 'user-123',
          email: 'old@example.com',
          firstName: 'John',
          lastName: 'Doe',
          birthDate: birthDate,
          timezone: 'UTC',
          targetSleepDuration: 420,
          language: 'en',
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          email: 'new@example.com',
          targetSleepDuration: 480,
          language: 'de',
        );

        // Changed fields
        expect(updated.email, 'new@example.com');
        expect(updated.targetSleepDuration, 480);
        expect(updated.language, 'de');

        // Unchanged fields
        expect(updated.id, original.id);
        expect(updated.firstName, original.firstName);
        expect(updated.lastName, original.lastName);
        expect(updated.birthDate, original.birthDate);
        expect(updated.timezone, original.timezone);
      });

      test('copyWith with no parameters returns identical copy', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final original = User(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          birthDate: birthDate,
          timezone: 'UTC',
          createdAt: now,
          updatedAt: now,
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.email, original.email);
        expect(copy.firstName, original.firstName);
        expect(copy.lastName, original.lastName);
        expect(copy.birthDate, original.birthDate);
        expect(copy.timezone, original.timezone);
      });

      test('copyWith can update updatedAt timestamp', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final later = DateTime(2025, 11, 1, 12, 0);
        final birthDate = DateTime(1990, 5, 15);

        final original = User(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          birthDate: birthDate,
          timezone: 'UTC',
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          email: 'new@example.com',
          updatedAt: later,
        );

        expect(updated.updatedAt, later);
        expect(updated.createdAt, now); // Should not change
      });
    });

    group('Getter: fullName', () {
      test('combines firstName and lastName', () {
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

        expect(user.fullName, 'John Doe');
      });

      test('works with different names', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final birthDate = DateTime(1990, 5, 15);

        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'Marie',
          lastName: 'Curie',
          birthDate: birthDate,
          timezone: 'UTC',
          createdAt: now,
          updatedAt: now,
        );

        expect(user.fullName, 'Marie Curie');
      });
    });
  });
}