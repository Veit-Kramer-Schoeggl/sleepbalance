import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/wearables/data/transformers/fitbit_sleep_transformer.dart';
import 'package:sleepbalance/core/wearables/domain/exceptions/wearable_exception.dart';

void main() {
  group('FitbitSleepTransformer', () {
    const userId = 'user-123';

    group('transformSleepData', () {
      test('transforms valid sleep data with all fields', () {
        final fitbitData = {
          'sleep': [
            {
              'dateOfSleep': '2025-11-15',
              'startTime': '2025-11-15T23:15:30.000',
              'endTime': '2025-11-16T07:30:30.000',
              'isMainSleep': true,
              'minutesAsleep': 420,
              'minutesAwake': 12,
              'levels': {
                'summary': {
                  'deep': {'minutes': 88, 'count': 3},
                  'light': {'minutes': 240, 'count': 20},
                  'rem': {'minutes': 92, 'count': 5},
                  'wake': {'minutes': 12, 'count': 8},
                },
              },
            },
          ],
        };

        final result = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        expect(result, isNotNull);
        expect(result!.userId, equals(userId));
        expect(result.sleepDate, equals(DateTime(2025, 11, 15)));
        expect(result.bedTime, equals(DateTime(2025, 11, 15, 23, 15, 30)));
        expect(result.sleepStartTime, equals(DateTime(2025, 11, 15, 23, 15, 30)));
        expect(result.sleepEndTime, equals(DateTime(2025, 11, 16, 7, 30, 30)));
        expect(result.wakeTime, equals(DateTime(2025, 11, 16, 7, 30, 30)));
        expect(result.totalSleepTime, equals(420));
        expect(result.deepSleepDuration, equals(88));
        expect(result.lightSleepDuration, equals(240));
        expect(result.remSleepDuration, equals(92));
        expect(result.awakeDuration, equals(12));
        expect(result.dataSource, equals('fitbit'));
      });

      test('returns null when sleep array is empty', () {
        final fitbitData = {'sleep': <dynamic>[]};

        final result = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        expect(result, isNull);
      });

      test('returns null when sleep array is null', () {
        final fitbitData = <String, dynamic>{'sleep': null};

        final result = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        expect(result, isNull);
      });

      test('returns null when no main sleep record (only naps)', () {
        final fitbitData = {
          'sleep': [
            {
              'dateOfSleep': '2025-11-15',
              'startTime': '2025-11-15T14:00:00.000',
              'endTime': '2025-11-15T14:30:00.000',
              'isMainSleep': false, // This is a nap
              'minutesAsleep': 25,
            },
          ],
        };

        final result = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        expect(result, isNull);
      });

      test('picks main sleep when multiple sleep records exist', () {
        final fitbitData = {
          'sleep': [
            {
              'dateOfSleep': '2025-11-15',
              'startTime': '2025-11-15T14:00:00.000',
              'endTime': '2025-11-15T14:30:00.000',
              'isMainSleep': false, // Nap
              'minutesAsleep': 25,
            },
            {
              'dateOfSleep': '2025-11-15',
              'startTime': '2025-11-15T23:00:00.000',
              'endTime': '2025-11-16T07:00:00.000',
              'isMainSleep': true, // Main sleep
              'minutesAsleep': 450,
              'levels': {
                'summary': {
                  'deep': {'minutes': 90},
                  'light': {'minutes': 250},
                  'rem': {'minutes': 100},
                  'wake': {'minutes': 10},
                },
              },
            },
          ],
        };

        final result = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        expect(result, isNotNull);
        expect(result!.totalSleepTime, equals(450)); // Main sleep value
      });

      test('handles missing levels/summary gracefully', () {
        final fitbitData = {
          'sleep': [
            {
              'dateOfSleep': '2025-11-15',
              'startTime': '2025-11-15T23:00:00.000',
              'endTime': '2025-11-16T07:00:00.000',
              'isMainSleep': true,
              'minutesAsleep': 420,
              'minutesAwake': 15,
              // No 'levels' field
            },
          ],
        };

        final result = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        expect(result, isNotNull);
        expect(result!.totalSleepTime, equals(420));
        expect(result.deepSleepDuration, isNull);
        expect(result.lightSleepDuration, isNull);
        expect(result.remSleepDuration, isNull);
        expect(result.awakeDuration, equals(15)); // Falls back to minutesAwake
      });

      test('handles invalid datetime strings gracefully', () {
        final fitbitData = {
          'sleep': [
            {
              'dateOfSleep': '2025-11-15',
              'startTime': 'invalid-date',
              'endTime': null,
              'isMainSleep': true,
              'minutesAsleep': 420,
            },
          ],
        };

        final result = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        expect(result, isNotNull);
        expect(result!.sleepStartTime, isNull);
        expect(result.sleepEndTime, isNull);
      });

      test('throws WearableException when dateOfSleep is missing', () {
        final fitbitData = {
          'sleep': [
            {
              // 'dateOfSleep' is missing
              'startTime': '2025-11-15T23:00:00.000',
              'endTime': '2025-11-16T07:00:00.000',
              'isMainSleep': true,
              'minutesAsleep': 420,
            },
          ],
        };

        expect(
          () => FitbitSleepTransformer.transformSleepData(
            fitbitData: fitbitData,
            userId: userId,
          ),
          throwsA(isA<WearableException>().having(
            (e) => e.errorType,
            'errorType',
            WearableErrorType.dataTransformation,
          )),
        );
      });

      test('generates unique UUID for each transformed record', () {
        final fitbitData = {
          'sleep': [
            {
              'dateOfSleep': '2025-11-15',
              'isMainSleep': true,
              'minutesAsleep': 420,
            },
          ],
        };

        final result1 = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        final result2 = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        expect(result1!.id, isNotEmpty);
        expect(result2!.id, isNotEmpty);
        expect(result1.id, isNot(equals(result2.id)));
      });

      test('sets qualityRating and qualityNotes to null (user-entered only)', () {
        final fitbitData = {
          'sleep': [
            {
              'dateOfSleep': '2025-11-15',
              'isMainSleep': true,
              'minutesAsleep': 420,
            },
          ],
        };

        final result = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        expect(result!.qualityRating, isNull);
        expect(result.qualityNotes, isNull);
      });

      test('sets heart rate fields to null (not from sleep endpoint)', () {
        final fitbitData = {
          'sleep': [
            {
              'dateOfSleep': '2025-11-15',
              'isMainSleep': true,
              'minutesAsleep': 420,
            },
          ],
        };

        final result = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: userId,
        );

        expect(result!.avgHeartRate, isNull);
        expect(result.minHeartRate, isNull);
        expect(result.maxHeartRate, isNull);
        expect(result.avgHrv, isNull);
        expect(result.avgBreathingRate, isNull);
      });
    });
  });
}
