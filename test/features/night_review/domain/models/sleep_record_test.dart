import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/utils/database_date_utils.dart';
import 'package:sleepbalance/features/night_review/domain/models/sleep_record.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';

void main() {
  group('SleepRecord', () {
    group('Constructor and basic properties', () {
      test('creates SleepRecord with required fields only', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final sleepDate = DateTime(2025, 11, 1);

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          dataSource: 'test',
          createdAt: now,
          updatedAt: now,
        );

        expect(record.id, 'test-id');
        expect(record.userId, 'user-123');
        expect(record.sleepDate, sleepDate);
        expect(record.dataSource, 'test');
        expect(record.createdAt, now);
        expect(record.updatedAt, now);

        // Verify nullable fields are null
        expect(record.bedTime, isNull);
        expect(record.sleepStartTime, isNull);
        expect(record.sleepEndTime, isNull);
        expect(record.wakeTime, isNull);
        expect(record.totalSleepTime, isNull);
        expect(record.deepSleepDuration, isNull);
        expect(record.remSleepDuration, isNull);
        expect(record.lightSleepDuration, isNull);
        expect(record.awakeDuration, isNull);
        expect(record.avgHeartRate, isNull);
        expect(record.minHeartRate, isNull);
        expect(record.maxHeartRate, isNull);
        expect(record.avgHrv, isNull);
        expect(record.avgHeartRateVariability, isNull);
        expect(record.avgBreathingRate, isNull);
        expect(record.qualityRating, isNull);
        expect(record.qualityNotes, isNull);
      });

      test('creates SleepRecord with all fields', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final sleepDate = DateTime(2025, 11, 1);
        final bedTime = DateTime(2025, 10, 31, 22, 30);
        final sleepStartTime = DateTime(2025, 10, 31, 22, 45);
        final sleepEndTime = DateTime(2025, 11, 1, 7, 15);
        final wakeTime = DateTime(2025, 11, 1, 7, 30);

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          bedTime: bedTime,
          sleepStartTime: sleepStartTime,
          sleepEndTime: sleepEndTime,
          wakeTime: wakeTime,
          totalSleepTime: 420,
          deepSleepDuration: 90,
          remSleepDuration: 100,
          lightSleepDuration: 210,
          awakeDuration: 20,
          avgHeartRate: 58.5,
          minHeartRate: 45.0,
          maxHeartRate: 72.0,
          avgHrv: 65.5,
          avgHeartRateVariability: 55.5,
          avgBreathingRate: 14.5,
          qualityRating: 'good',
          qualityNotes: 'Slept well',
          dataSource: 'apple_health',
          createdAt: now,
          updatedAt: now,
        );

        expect(record.id, 'test-id');
        expect(record.userId, 'user-123');
        expect(record.sleepDate, sleepDate);
        expect(record.bedTime, bedTime);
        expect(record.sleepStartTime, sleepStartTime);
        expect(record.sleepEndTime, sleepEndTime);
        expect(record.wakeTime, wakeTime);
        expect(record.totalSleepTime, 420);
        expect(record.deepSleepDuration, 90);
        expect(record.remSleepDuration, 100);
        expect(record.lightSleepDuration, 210);
        expect(record.awakeDuration, 20);
        expect(record.avgHeartRate, 58.5);
        expect(record.minHeartRate, 45.0);
        expect(record.maxHeartRate, 72.0);
        expect(record.avgHrv, 65.5);
        expect(record.avgHeartRateVariability, 55.5);
        expect(record.avgBreathingRate, 14.5);
        expect(record.qualityRating, 'good');
        expect(record.qualityNotes, 'Slept well');
        expect(record.dataSource, 'apple_health');
        expect(record.createdAt, now);
        expect(record.updatedAt, now);
      });
    });

    group('JSON serialization (toJson/fromJson)', () {
      test('toJson converts model to JSON map', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final sleepDate = DateTime(2025, 11, 1);

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          totalSleepTime: 420,
          avgHeartRateVariability: 55.5,
          dataSource: 'test',
          createdAt: now,
          updatedAt: now,
        );

        final json = record.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], 'test-id');
        expect(json['userId'], 'user-123');
        expect(json['totalSleepTime'], 420);
        expect(json['avgHeartRateVariability'], 55.5);
        expect(json['dataSource'], 'test');
      });

      test('fromJson creates model from JSON map', () {
        final json = {
          'id': 'test-id',
          'userId': 'user-123',
          'sleepDate': '2025-11-01T00:00:00.000',
          'totalSleepTime': 420,
          'deepSleepDuration': 90,
          'avgHeartRateVariability': 55.5,
          'dataSource': 'test',
          'createdAt': '2025-11-01T10:00:00.000',
          'updatedAt': '2025-11-01T10:00:00.000',
        };

        final record = SleepRecord.fromJson(json);

        expect(record.id, 'test-id');
        expect(record.userId, 'user-123');
        expect(record.totalSleepTime, 420);
        expect(record.deepSleepDuration, 90);
        expect(record.avgHeartRateVariability, 55.5);
        expect(record.dataSource, 'test');
      });

      test('JSON round-trip preserves data', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final sleepDate = DateTime(2025, 11, 1);

        final original = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          totalSleepTime: 420,
          deepSleepDuration: 90,
          avgHeartRateVariability: 55.5,
          dataSource: 'test',
          createdAt: now,
          updatedAt: now,
        );

        final json = original.toJson();
        final restored = SleepRecord.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.totalSleepTime, original.totalSleepTime);
        expect(restored.deepSleepDuration, original.deepSleepDuration);
        expect(restored.avgHeartRateVariability, original.avgHeartRateVariability);
        expect(restored.dataSource, original.dataSource);
      });
    });

    group('Database serialization (toDatabase/fromDatabase)', () {
      test('toDatabase converts DateTime to ISO 8601 strings', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final sleepDate = DateTime(2025, 11, 1);
        final bedTime = DateTime(2025, 10, 31, 22, 30);

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          bedTime: bedTime,
          dataSource: 'test',
          createdAt: now,
          updatedAt: now,
        );

        final dbMap = record.toDatabase();

        // Verify uses DatabaseConstants
        expect(dbMap.containsKey(SLEEP_RECORDS_ID), isTrue);
        expect(dbMap.containsKey(SLEEP_RECORDS_USER_ID), isTrue);
        expect(dbMap.containsKey(SLEEP_RECORDS_SLEEP_DATE), isTrue);

        // Verify date string format (date-only)
        expect(dbMap[SLEEP_RECORDS_SLEEP_DATE], '2025-11-01');

        // Verify timestamp format (includes time)
        expect(dbMap[SLEEP_RECORDS_CREATED_AT], contains('T'));
        expect(dbMap[SLEEP_RECORDS_UPDATED_AT], contains('T'));

        // Verify bedTime is timestamp (nullable)
        expect(dbMap[SLEEP_RECORDS_BED_TIME], contains('T'));
      });

      test('toDatabase handles nullable DateTime fields', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final sleepDate = DateTime(2025, 11, 1);

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          dataSource: 'test',
          createdAt: now,
          updatedAt: now,
          // All nullable DateTime fields omitted
        );

        final dbMap = record.toDatabase();

        expect(dbMap[SLEEP_RECORDS_BED_TIME], isNull);
        expect(dbMap[SLEEP_RECORDS_SLEEP_START_TIME], isNull);
        expect(dbMap[SLEEP_RECORDS_SLEEP_END_TIME], isNull);
        expect(dbMap[SLEEP_RECORDS_WAKE_TIME], isNull);
      });

      test('fromDatabase converts strings to DateTime', () {
        final dbMap = {
          SLEEP_RECORDS_ID: 'test-id',
          SLEEP_RECORDS_USER_ID: 'user-123',
          SLEEP_RECORDS_SLEEP_DATE: '2025-11-01',
          SLEEP_RECORDS_BED_TIME: '2025-10-31T22:30:00.000',
          SLEEP_RECORDS_DATA_SOURCE: 'test',
          SLEEP_RECORDS_CREATED_AT: '2025-11-01T10:00:00.000',
          SLEEP_RECORDS_UPDATED_AT: '2025-11-01T10:00:00.000',
        };

        final record = SleepRecord.fromDatabase(dbMap);

        expect(record.sleepDate, isA<DateTime>());
        expect(record.bedTime, isA<DateTime>());
        expect(record.createdAt, isA<DateTime>());
        expect(record.updatedAt, isA<DateTime>());

        // Verify specific values
        expect(record.sleepDate.year, 2025);
        expect(record.sleepDate.month, 11);
        expect(record.sleepDate.day, 1);
      });

      test('fromDatabase handles nullable fields correctly', () {
        final dbMap = {
          SLEEP_RECORDS_ID: 'test-id',
          SLEEP_RECORDS_USER_ID: 'user-123',
          SLEEP_RECORDS_SLEEP_DATE: '2025-11-01',
          SLEEP_RECORDS_DATA_SOURCE: 'test',
          SLEEP_RECORDS_CREATED_AT: '2025-11-01T10:00:00.000',
          SLEEP_RECORDS_UPDATED_AT: '2025-11-01T10:00:00.000',
          // Nullable fields explicitly null
          SLEEP_RECORDS_BED_TIME: null,
          SLEEP_RECORDS_TOTAL_SLEEP_TIME: null,
          SLEEP_RECORDS_AVG_HEART_RATE_VARIABILITY: null,
        };

        final record = SleepRecord.fromDatabase(dbMap);

        expect(record.bedTime, isNull);
        expect(record.totalSleepTime, isNull);
        expect(record.avgHeartRateVariability, isNull);
      });

      test('database round-trip preserves all data', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final sleepDate = DateTime(2025, 11, 1);
        final bedTime = DateTime(2025, 10, 31, 22, 30);
        final wakeTime = DateTime(2025, 11, 1, 7, 30);

        final original = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          bedTime: bedTime,
          wakeTime: wakeTime,
          totalSleepTime: 420,
          deepSleepDuration: 90,
          avgHeartRate: 58.5,
          avgHeartRateVariability: 55.5,
          dataSource: 'test',
          createdAt: now,
          updatedAt: now,
        );

        final dbMap = original.toDatabase();
        final restored = SleepRecord.fromDatabase(dbMap);

        // Compare all fields
        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(
          restored.sleepDate.toIso8601String(),
          original.sleepDate.toIso8601String(),
        );
        expect(
          restored.bedTime?.toIso8601String(),
          original.bedTime?.toIso8601String(),
        );
        expect(
          restored.wakeTime?.toIso8601String(),
          original.wakeTime?.toIso8601String(),
        );
        expect(restored.totalSleepTime, original.totalSleepTime);
        expect(restored.deepSleepDuration, original.deepSleepDuration);
        expect(restored.avgHeartRate, original.avgHeartRate);
        expect(restored.avgHeartRateVariability, original.avgHeartRateVariability);
        expect(restored.dataSource, original.dataSource);
      });

      test('database serialization includes avgHeartRateVariability', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final sleepDate = DateTime(2025, 11, 1);

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          avgHeartRateVariability: 45.5,
          dataSource: 'test',
          createdAt: now,
          updatedAt: now,
        );

        final dbMap = record.toDatabase();
        expect(
          dbMap[SLEEP_RECORDS_AVG_HEART_RATE_VARIABILITY],
          45.5,
        );

        final restored = SleepRecord.fromDatabase(dbMap);
        expect(restored.avgHeartRateVariability, 45.5);
      });
    });

    group('copyWith method', () {
      test('copyWith updates specified fields', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final sleepDate = DateTime(2025, 11, 1);

        final original = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          totalSleepTime: 420,
          qualityRating: 'average',
          dataSource: 'test',
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          totalSleepTime: 450,
          qualityRating: 'good',
        );

        // Changed fields
        expect(updated.totalSleepTime, 450);
        expect(updated.qualityRating, 'good');

        // Unchanged fields
        expect(updated.id, original.id);
        expect(updated.userId, original.userId);
        expect(updated.sleepDate, original.sleepDate);
        expect(updated.dataSource, original.dataSource);
      });

      test('copyWith with no parameters returns identical copy', () {
        final now = DateTime(2025, 11, 1, 10, 0);
        final sleepDate = DateTime(2025, 11, 1);

        final original = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          totalSleepTime: 420,
          dataSource: 'test',
          createdAt: now,
          updatedAt: now,
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
        expect(copy.sleepDate, original.sleepDate);
        expect(copy.totalSleepTime, original.totalSleepTime);
        expect(copy.dataSource, original.dataSource);
      });
    });

    group('Calculated property: sleepEfficiency', () {
      test('calculates sleep efficiency correctly', () {
        final sleepDate = DateTime(2025, 11, 1);
        final bedTime = DateTime(2025, 10, 31, 22, 0); // 10 PM
        final wakeTime = DateTime(2025, 11, 1, 7, 0); // 7 AM (9 hours = 540 min)

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          bedTime: bedTime,
          wakeTime: wakeTime,
          totalSleepTime: 420, // 7 hours
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 420 / 540 * 100 = 77.77... ≈ 78
        expect(record.sleepEfficiency, 78);
      });

      test('returns null when totalSleepTime is null', () {
        final sleepDate = DateTime(2025, 11, 1);
        final bedTime = DateTime(2025, 10, 31, 22, 0);
        final wakeTime = DateTime(2025, 11, 1, 7, 0);

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          bedTime: bedTime,
          wakeTime: wakeTime,
          // totalSleepTime is null
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(record.sleepEfficiency, isNull);
      });

      test('returns null when bedTime or wakeTime is null', () {
        final sleepDate = DateTime(2025, 11, 1);

        final recordNoBedTime = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          wakeTime: DateTime(2025, 11, 1, 7, 0),
          totalSleepTime: 420,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(recordNoBedTime.sleepEfficiency, isNull);

        final recordNoWakeTime = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          bedTime: DateTime(2025, 10, 31, 22, 0),
          totalSleepTime: 420,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(recordNoWakeTime.sleepEfficiency, isNull);
      });

      test('returns null when timeInBed is zero', () {
        final sleepDate = DateTime(2025, 11, 1);
        final sameTime = DateTime(2025, 11, 1, 7, 0);

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          bedTime: sameTime,
          wakeTime: sameTime, // Same time = 0 duration
          totalSleepTime: 420,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(record.sleepEfficiency, isNull);
      });
    });

    group('Calculated property: timeInBed', () {
      test('calculates timeInBed correctly', () {
        final sleepDate = DateTime(2025, 11, 1);
        final bedTime = DateTime(2025, 10, 31, 22, 0); // 10 PM
        final wakeTime = DateTime(2025, 11, 1, 7, 0); // 7 AM

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          bedTime: bedTime,
          wakeTime: wakeTime,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(record.timeInBed, Duration(hours: 9));
      });

      test('returns null when bedTime or wakeTime is null', () {
        final sleepDate = DateTime(2025, 11, 1);

        final recordNoBedTime = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          wakeTime: DateTime(2025, 11, 1, 7, 0),
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(recordNoBedTime.timeInBed, isNull);

        final recordNoWakeTime = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          bedTime: DateTime(2025, 10, 31, 22, 0),
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(recordNoWakeTime.timeInBed, isNull);
      });

      test('handles overnight time correctly', () {
        final sleepDate = DateTime(2025, 11, 1);
        final bedTime = DateTime(2025, 10, 31, 23, 30); // 11:30 PM day 1
        final wakeTime = DateTime(2025, 11, 1, 7, 30); // 7:30 AM day 2

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: sleepDate,
          bedTime: bedTime,
          wakeTime: wakeTime,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(record.timeInBed, Duration(hours: 8));
      });
    });
  });
}
