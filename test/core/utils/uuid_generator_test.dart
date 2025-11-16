import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/utils/uuid_generator.dart';

/// Unit tests for UuidGenerator
///
/// Tests:
/// - Generates valid UUID v4 format
/// - Generates unique UUIDs
void main() {
  group('UuidGenerator', () {
    test('generate returns valid UUID v4 format', () {
      final uuid = UuidGenerator.generate();

      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      // where x is any hexadecimal digit and y is one of 8, 9, A, or B
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      expect(uuid, matches(uuidRegex));
    });

    test('generate returns unique UUIDs', () {
      final uuid1 = UuidGenerator.generate();
      final uuid2 = UuidGenerator.generate();
      final uuid3 = UuidGenerator.generate();

      // All three should be different
      expect(uuid1, isNot(equals(uuid2)));
      expect(uuid2, isNot(equals(uuid3)));
      expect(uuid1, isNot(equals(uuid3)));
    });

    test('generate returns 36 character string', () {
      final uuid = UuidGenerator.generate();

      // UUID format is always 36 characters (32 hex + 4 hyphens)
      expect(uuid.length, equals(36));
    });

    test('generate contains 4 hyphens in correct positions', () {
      final uuid = UuidGenerator.generate();

      // Hyphens should be at positions 8, 13, 18, 23
      expect(uuid[8], equals('-'));
      expect(uuid[13], equals('-'));
      expect(uuid[18], equals('-'));
      expect(uuid[23], equals('-'));
    });
  });
}
