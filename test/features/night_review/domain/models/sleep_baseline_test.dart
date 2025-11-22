import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/utils/database_date_utils.dart';
import 'package:sleepbalance/features/night_review/domain/models/sleep_baseline.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';

void main() {
  group('SleepBaseline', () {
    group('Constructor and basic properties', () {
      test('creates SleepBaseline with all required fields', () {
        final start = DateTime(2025, 10, 25);
        final end = DateTime(2025, 11, 1);
        final computedAt = DateTime(2025, 11, 1, 10, 0);

        final baseline = SleepBaseline(
          id: 'baseline-id',
          userId: 'user-123',
          baselineType: '7_day',
          metricName: 'avg_deep_sleep',
          metricValue: 85.5,
          dataRangeStart: start,
          dataRangeEnd: end,
          computedAt: computedAt,
        );

        expect(baseline.id, 'baseline-id');
        expect(baseline.userId, 'user-123');
        expect(baseline.baselineType, '7_day');
        expect(baseline.metricName, 'avg_deep_sleep');
        expect(baseline.metricValue, 85.5);
        expect(baseline.dataRangeStart, start);
        expect(baseline.dataRangeEnd, end);
        expect(baseline.computedAt, computedAt);
      });
    });

    group('JSON serialization (toJson/fromJson)', () {
      test('toJson converts model to JSON map', () {
        final start = DateTime(2025, 10, 25);
        final end = DateTime(2025, 11, 1);
        final computedAt = DateTime(2025, 11, 1, 10, 0);

        final baseline = SleepBaseline(
          id: 'baseline-id',
          userId: 'user-123',
          baselineType: '7_day',
          metricName: 'avg_deep_sleep',
          metricValue: 85.5,
          dataRangeStart: start,
          dataRangeEnd: end,
          computedAt: computedAt,
        );

        final json = baseline.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], 'baseline-id');
        expect(json['userId'], 'user-123');
        expect(json['baselineType'], '7_day');
        expect(json['metricName'], 'avg_deep_sleep');
        expect(json['metricValue'], 85.5);
      });

      test('fromJson creates model from JSON map', () {
        final json = {
          'id': 'baseline-id',
          'userId': 'user-123',
          'baselineType': '7_day',
          'metricName': 'avg_deep_sleep',
          'metricValue': 85.5,
          'dataRangeStart': '2025-10-25T00:00:00.000',
          'dataRangeEnd': '2025-11-01T00:00:00.000',
          'computedAt': '2025-11-01T10:00:00.000',
        };

        final baseline = SleepBaseline.fromJson(json);

        expect(baseline.id, 'baseline-id');
        expect(baseline.userId, 'user-123');
        expect(baseline.baselineType, '7_day');
        expect(baseline.metricName, 'avg_deep_sleep');
        expect(baseline.metricValue, 85.5);
      });

      test('JSON round-trip preserves data', () {
        final start = DateTime(2025, 10, 25);
        final end = DateTime(2025, 11, 1);
        final computedAt = DateTime(2025, 11, 1, 10, 0);

        final original = SleepBaseline(
          id: 'baseline-id',
          userId: 'user-123',
          baselineType: '7_day',
          metricName: 'avg_deep_sleep',
          metricValue: 85.5,
          dataRangeStart: start,
          dataRangeEnd: end,
          computedAt: computedAt,
        );

        final json = original.toJson();
        final restored = SleepBaseline.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.baselineType, original.baselineType);
        expect(restored.metricName, original.metricName);
        expect(restored.metricValue, original.metricValue);
      });
    });

    group('Database serialization (toDatabase/fromDatabase)', () {
      test('toDatabase converts DateTime to ISO 8601 strings', () {
        final start = DateTime(2025, 10, 25);
        final end = DateTime(2025, 11, 1);
        final computedAt = DateTime(2025, 11, 1, 10, 0);

        final baseline = SleepBaseline(
          id: 'baseline-id',
          userId: 'user-123',
          baselineType: '7_day',
          metricName: 'avg_deep_sleep',
          metricValue: 85.5,
          dataRangeStart: start,
          dataRangeEnd: end,
          computedAt: computedAt,
        );

        final dbMap = baseline.toDatabase();

        // Verify uses DatabaseConstants
        expect(dbMap.containsKey(USER_SLEEP_BASELINES_ID), isTrue);
        expect(dbMap.containsKey(USER_SLEEP_BASELINES_USER_ID), isTrue);
        expect(dbMap.containsKey(USER_SLEEP_BASELINES_BASELINE_TYPE), isTrue);

        // Verify date range uses toDateString (date-only)
        expect(dbMap[USER_SLEEP_BASELINES_DATA_RANGE_START], '2025-10-25');
        expect(dbMap[USER_SLEEP_BASELINES_DATA_RANGE_END], '2025-11-01');

        // Verify computedAt uses toTimestamp (includes time)
        expect(dbMap[USER_SLEEP_BASELINES_COMPUTED_AT], contains('T'));

        // Verify other fields
        expect(dbMap[USER_SLEEP_BASELINES_METRIC_NAME], 'avg_deep_sleep');
        expect(dbMap[USER_SLEEP_BASELINES_METRIC_VALUE], 85.5);
      });

      test('fromDatabase converts strings to DateTime', () {
        final dbMap = {
          USER_SLEEP_BASELINES_ID: 'baseline-id',
          USER_SLEEP_BASELINES_USER_ID: 'user-123',
          USER_SLEEP_BASELINES_BASELINE_TYPE: '7_day',
          USER_SLEEP_BASELINES_METRIC_NAME: 'avg_deep_sleep',
          USER_SLEEP_BASELINES_METRIC_VALUE: 85.5,
          USER_SLEEP_BASELINES_DATA_RANGE_START: '2025-10-25',
          USER_SLEEP_BASELINES_DATA_RANGE_END: '2025-11-01',
          USER_SLEEP_BASELINES_COMPUTED_AT: '2025-11-01T10:00:00.000',
        };

        final baseline = SleepBaseline.fromDatabase(dbMap);

        expect(baseline.dataRangeStart, isA<DateTime>());
        expect(baseline.dataRangeEnd, isA<DateTime>());
        expect(baseline.computedAt, isA<DateTime>());

        // Verify specific values
        expect(baseline.dataRangeStart.year, 2025);
        expect(baseline.dataRangeStart.month, 10);
        expect(baseline.dataRangeStart.day, 25);

        expect(baseline.dataRangeEnd.year, 2025);
        expect(baseline.dataRangeEnd.month, 11);
        expect(baseline.dataRangeEnd.day, 1);
      });

      test('database round-trip preserves all data', () {
        final start = DateTime(2025, 10, 25);
        final end = DateTime(2025, 11, 1);
        final computedAt = DateTime(2025, 11, 1, 10, 0);

        final original = SleepBaseline(
          id: 'baseline-id',
          userId: 'user-123',
          baselineType: '7_day',
          metricName: 'avg_deep_sleep',
          metricValue: 85.5,
          dataRangeStart: start,
          dataRangeEnd: end,
          computedAt: computedAt,
        );

        final dbMap = original.toDatabase();
        final restored = SleepBaseline.fromDatabase(dbMap);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.baselineType, original.baselineType);
        expect(restored.metricName, original.metricName);
        expect(restored.metricValue, original.metricValue);
        expect(
          restored.dataRangeStart.toIso8601String(),
          original.dataRangeStart.toIso8601String(),
        );
        expect(
          restored.dataRangeEnd.toIso8601String(),
          original.dataRangeEnd.toIso8601String(),
        );
        expect(
          restored.computedAt.toIso8601String(),
          original.computedAt.toIso8601String(),
        );
      });
    });

    group('copyWith method', () {
      test('copyWith updates specified fields', () {
        final start = DateTime(2025, 10, 25);
        final end = DateTime(2025, 11, 1);
        final computedAt = DateTime(2025, 11, 1, 10, 0);
        final newComputedAt = DateTime(2025, 11, 1, 11, 0);

        final original = SleepBaseline(
          id: 'baseline-id',
          userId: 'user-123',
          baselineType: '7_day',
          metricName: 'avg_deep_sleep',
          metricValue: 85.5,
          dataRangeStart: start,
          dataRangeEnd: end,
          computedAt: computedAt,
        );

        final updated = original.copyWith(
          metricValue: 90.0,
          computedAt: newComputedAt,
        );

        // Changed fields
        expect(updated.metricValue, 90.0);
        expect(updated.computedAt, newComputedAt);

        // Unchanged fields
        expect(updated.id, original.id);
        expect(updated.userId, original.userId);
        expect(updated.baselineType, original.baselineType);
        expect(updated.metricName, original.metricName);
        expect(updated.dataRangeStart, original.dataRangeStart);
        expect(updated.dataRangeEnd, original.dataRangeEnd);
      });

      test('copyWith with no parameters returns identical copy', () {
        final start = DateTime(2025, 10, 25);
        final end = DateTime(2025, 11, 1);
        final computedAt = DateTime(2025, 11, 1, 10, 0);

        final original = SleepBaseline(
          id: 'baseline-id',
          userId: 'user-123',
          baselineType: '7_day',
          metricName: 'avg_deep_sleep',
          metricValue: 85.5,
          dataRangeStart: start,
          dataRangeEnd: end,
          computedAt: computedAt,
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
        expect(copy.baselineType, original.baselineType);
        expect(copy.metricName, original.metricName);
        expect(copy.metricValue, original.metricValue);
        expect(copy.dataRangeStart, original.dataRangeStart);
        expect(copy.dataRangeEnd, original.dataRangeEnd);
        expect(copy.computedAt, original.computedAt);
      });
    });

    group('Different baseline types', () {
      test('supports 7_day baseline type', () {
        final start = DateTime(2025, 10, 25);
        final end = DateTime(2025, 11, 1);
        final computedAt = DateTime(2025, 11, 1, 10, 0);

        final baseline = SleepBaseline(
          id: 'baseline-id',
          userId: 'user-123',
          baselineType: '7_day',
          metricName: 'avg_deep_sleep',
          metricValue: 85.5,
          dataRangeStart: start,
          dataRangeEnd: end,
          computedAt: computedAt,
        );

        expect(baseline.baselineType, '7_day');

        // Verify serialization handles this correctly
        final dbMap = baseline.toDatabase();
        final restored = SleepBaseline.fromDatabase(dbMap);
        expect(restored.baselineType, '7_day');
      });

      test('supports 30_day baseline type', () {
        final start = DateTime(2025, 10, 2);
        final end = DateTime(2025, 11, 1);
        final computedAt = DateTime(2025, 11, 1, 10, 0);

        final baseline = SleepBaseline(
          id: 'baseline-id',
          userId: 'user-123',
          baselineType: '30_day',
          metricName: 'avg_total_sleep',
          metricValue: 420.0,
          dataRangeStart: start,
          dataRangeEnd: end,
          computedAt: computedAt,
        );

        expect(baseline.baselineType, '30_day');

        // Verify serialization handles this correctly
        final dbMap = baseline.toDatabase();
        final restored = SleepBaseline.fromDatabase(dbMap);
        expect(restored.baselineType, '30_day');
      });

      test('supports all_time baseline type', () {
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 11, 1);
        final computedAt = DateTime(2025, 11, 1, 10, 0);

        final baseline = SleepBaseline(
          id: 'baseline-id',
          userId: 'user-123',
          baselineType: 'all_time',
          metricName: 'avg_sleep_efficiency',
          metricValue: 82.0,
          dataRangeStart: start,
          dataRangeEnd: end,
          computedAt: computedAt,
        );

        expect(baseline.baselineType, 'all_time');

        // Verify serialization handles this correctly
        final dbMap = baseline.toDatabase();
        final restored = SleepBaseline.fromDatabase(dbMap);
        expect(restored.baselineType, 'all_time');
      });
    });
  });
}