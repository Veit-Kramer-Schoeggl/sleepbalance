import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/night_review/domain/models/sleep_baseline.dart';
import 'package:sleepbalance/features/night_review/domain/models/sleep_comparison.dart';
import 'package:sleepbalance/features/night_review/domain/models/sleep_record.dart';

void main() {
  group('SleepComparison', () {
    group('Factory constructor: calculate()', () {
      test('calculates differences for deep sleep metric', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 100,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.differences['avg_deep_sleep'], 15.0); // 100 - 85
        expect(comparison.baselines['avg_deep_sleep'], 85.0);
      });

      test('calculates differences for multiple metrics', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 100,
          remSleepDuration: 110,
          totalSleepTime: 450,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'b1',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b2',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_rem_sleep',
            metricValue: 95.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b3',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_total_sleep',
            metricValue: 420.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.differences['avg_deep_sleep'], 15.0); // 100 - 85
        expect(comparison.differences['avg_rem_sleep'], 15.0); // 110 - 95
        expect(comparison.differences['avg_total_sleep'], 30.0); // 450 - 420
      });

      test('handles empty baselines list', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 100,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final comparison = SleepComparison.calculate(record, []);

        expect(comparison.baselines, isEmpty);
        expect(comparison.differences, isEmpty);
      });

      test('handles missing actual values (nulls in record)', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          // deepSleepDuration is null
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.baselines['avg_deep_sleep'], 85.0);
        expect(comparison.differences['avg_deep_sleep'], isNull);
      });

      test('calculates all metric types correctly', () {
        final bedTime = DateTime(2025, 10, 31, 22, 0);
        final wakeTime = DateTime(2025, 11, 1, 7, 0);

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          bedTime: bedTime,
          wakeTime: wakeTime,
          deepSleepDuration: 100,
          remSleepDuration: 110,
          lightSleepDuration: 200,
          totalSleepTime: 450,
          awakeDuration: 30,
          avgHeartRate: 60.0,
          avgHrv: 70.0,
          avgHeartRateVariability: 55.0,
          avgBreathingRate: 15.0,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'b1',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b2',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_rem_sleep',
            metricValue: 95.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b3',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_light_sleep',
            metricValue: 180.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b4',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_total_sleep',
            metricValue: 420.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b5',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_awake_duration',
            metricValue: 25.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b6',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_heart_rate',
            metricValue: 58.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b7',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_hrv',
            metricValue: 65.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b8',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_heart_rate_variability',
            metricValue: 50.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b9',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_breathing_rate',
            metricValue: 14.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
          SleepBaseline(
            id: 'b10',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_sleep_efficiency',
            metricValue: 75.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        // Verify all 10 metric types calculated
        expect(comparison.differences['avg_deep_sleep'], 15.0);
        expect(comparison.differences['avg_rem_sleep'], 15.0);
        expect(comparison.differences['avg_light_sleep'], 20.0);
        expect(comparison.differences['avg_total_sleep'], 30.0);
        expect(comparison.differences['avg_awake_duration'], 5.0);
        expect(comparison.differences['avg_heart_rate'], 2.0);
        expect(comparison.differences['avg_hrv'], 5.0);
        expect(comparison.differences['avg_heart_rate_variability'], 5.0);
        expect(comparison.differences['avg_breathing_rate'], 1.0);
        expect(comparison.differences['avg_sleep_efficiency'], isNotNull);
      });

      test('handles avgHeartRateVariability metric specifically', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          avgHeartRateVariability: 55.5,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_heart_rate_variability',
            metricValue: 50.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.differences['avg_heart_rate_variability'], 5.5);
        expect(comparison.baselines['avg_heart_rate_variability'], 50.0);
      });
    });

    group('isAboveAverage()', () {
      test('returns true for positive difference', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 100,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.isAboveAverage('avg_deep_sleep'), isTrue);
      });

      test('returns false for negative difference', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 70,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.isAboveAverage('avg_deep_sleep'), isFalse);
      });

      test('returns false for zero difference', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 85,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.isAboveAverage('avg_deep_sleep'), isFalse);
      });

      test('returns false for missing metric', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 100,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final comparison = SleepComparison.calculate(record, []);

        expect(comparison.isAboveAverage('avg_deep_sleep'), isFalse);
      });
    });

    group('getDifferenceText()', () {
      test('formats positive difference with plus sign', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 100,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.getDifferenceText('avg_deep_sleep'), '+15 min');
      });

      test('formats negative difference with minus sign', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 75,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.getDifferenceText('avg_deep_sleep'), '-10 min');
      });

      test('formats small values with decimal', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          avgHeartRate: 60.5,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_heart_rate',
            metricValue: 58.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(
            comparison.getDifferenceText('avg_heart_rate', unit: 'bpm'),
            '+2.5 bpm');
      });

      test('formats large values without decimal', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 110,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        // 25.0 should format as "25" (no decimal)
        expect(comparison.getDifferenceText('avg_deep_sleep'), '+25 min');
      });

      test('supports custom unit parameter', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          avgHeartRate: 63.0,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_heart_rate',
            metricValue: 58.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.getDifferenceText('avg_heart_rate', unit: 'bpm'), '+5 bpm');
      });

      test('returns empty string for missing metric', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final comparison = SleepComparison.calculate(record, []);

        expect(comparison.getDifferenceText('avg_deep_sleep'), '');
      });
    });

    group('getPercentageDifference()', () {
      test('calculates percentage correctly', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 100,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 80.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        // (100 - 80) / 80 * 100 = 25%
        expect(comparison.getPercentageDifference('avg_deep_sleep'), 25.0);
      });

      test('handles zero baseline', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 10,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 0.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.getPercentageDifference('avg_deep_sleep'), isNull);
      });

      test('handles null difference', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          // deepSleepDuration is null
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 80.0,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.getPercentageDifference('avg_deep_sleep'), isNull);
      });

      test('handles null baseline', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 100,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final comparison = SleepComparison.calculate(record, []);

        expect(comparison.getPercentageDifference('avg_deep_sleep'), isNull);
      });
    });

    group('getBaselineValue() and getActualValue()', () {
      test('getBaselineValue returns correct value', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 100,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final baselines = [
          SleepBaseline(
            id: 'baseline-id',
            userId: 'user-123',
            baselineType: '7_day',
            metricName: 'avg_deep_sleep',
            metricValue: 85.5,
            dataRangeStart: DateTime(2025, 10, 25),
            dataRangeEnd: DateTime(2025, 11, 1),
            computedAt: DateTime.now(),
          ),
        ];

        final comparison = SleepComparison.calculate(record, baselines);

        expect(comparison.getBaselineValue('avg_deep_sleep'), 85.5);
      });

      test('getActualValue returns correct values for all metric types', () {
        final bedTime = DateTime(2025, 10, 31, 22, 0);
        final wakeTime = DateTime(2025, 11, 1, 7, 0);

        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          bedTime: bedTime,
          wakeTime: wakeTime,
          deepSleepDuration: 100,
          remSleepDuration: 110,
          lightSleepDuration: 200,
          totalSleepTime: 450,
          awakeDuration: 30,
          avgHeartRate: 60.0,
          avgHrv: 70.0,
          avgHeartRateVariability: 55.0,
          avgBreathingRate: 15.0,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final comparison = SleepComparison.calculate(record, []);

        // Test all metric types
        expect(comparison.getActualValue('avg_deep_sleep'), 100.0);
        expect(comparison.getActualValue('avg_rem_sleep'), 110.0);
        expect(comparison.getActualValue('avg_light_sleep'), 200.0);
        expect(comparison.getActualValue('avg_total_sleep'), 450.0);
        expect(comparison.getActualValue('avg_awake_duration'), 30.0);
        expect(comparison.getActualValue('avg_heart_rate'), 60.0);
        expect(comparison.getActualValue('avg_hrv'), 70.0);
        expect(comparison.getActualValue('avg_heart_rate_variability'), 55.0);
        expect(comparison.getActualValue('avg_breathing_rate'), 15.0);
        expect(comparison.getActualValue('avg_sleep_efficiency'), isNotNull);
      });

      test('getActualValue returns null for unknown metric', () {
        final record = SleepRecord(
          id: 'test-id',
          userId: 'user-123',
          sleepDate: DateTime(2025, 11, 1),
          deepSleepDuration: 100,
          dataSource: 'test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final comparison = SleepComparison.calculate(record, []);

        expect(comparison.getActualValue('unknown_metric'), isNull);
      });
    });
  });
}
