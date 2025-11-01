import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/settings/domain/models/user.dart';

void main() {
  group('User Age Calculation', () {
    test('calculates age correctly for birthday already passed this year', () {
      final now = DateTime.now();
      // Create birthdate 30 years and 6 months ago (birthday already passed)
      final birthDate = DateTime(
        now.year - 30,
        now.month > 6 ? now.month - 6 : now.month + 6,
        15,
      );

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

      // Birthday was 6 months ago, so age should be 30
      expect(user.age, 30);
    });

    test('calculates age correctly for birthday not yet this year', () {
      final now = DateTime.now();
      // Create birthdate 30 years ago but in a future month (birthday not yet)
      final futureMonth = now.month < 12 ? now.month + 1 : 1;
      final birthYear = futureMonth == 1 ? now.year - 29 : now.year - 30;
      final birthDate = DateTime(birthYear, futureMonth, 15);

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

      // Birthday is next month, so age should be 29
      expect(user.age, 29);
    });

    test('calculates age correctly on birthday', () {
      final now = DateTime.now();
      // Create birthdate exactly 25 years ago today
      final birthDate = DateTime(now.year - 25, now.month, now.day);

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

      // Today is their birthday
      expect(user.age, 25);
    });

    test('calculates age correctly for someone born 18 years ago', () {
      final now = DateTime.now();
      // Create birthdate exactly 18 years and 1 day ago (birthday just passed)
      final birthDate = DateTime(now.year - 18, now.month, now.day)
          .subtract(const Duration(days: 1));

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

      // Birthday was yesterday
      expect(user.age, 18);
    });
  });
}