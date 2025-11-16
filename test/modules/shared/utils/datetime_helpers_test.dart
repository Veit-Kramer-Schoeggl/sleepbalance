import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/modules/shared/utils/datetime_helpers.dart';

void main() {
  group('DateTimeHelpers', () {
    group('calculateTimeRelativeToWake', () {
      test('calculates time after wake time', () {
        final wakeTime = DateTime(2025, 1, 1, 7, 0);
        final result = DateTimeHelpers.calculateTimeRelativeToWake(
          const Duration(minutes: 30),
          wakeTime,
        );

        expect(result, DateTime(2025, 1, 1, 7, 30));
      });

      test('calculates time hours after wake time', () {
        final wakeTime = DateTime(2025, 1, 1, 7, 0);
        final result = DateTimeHelpers.calculateTimeRelativeToWake(
          const Duration(hours: 2),
          wakeTime,
        );

        expect(result, DateTime(2025, 1, 1, 9, 0));
      });
    });

    group('calculateTimeRelativeToBed', () {
      test('calculates time before bed time', () {
        final bedTime = DateTime(2025, 1, 1, 22, 0);
        final result = DateTimeHelpers.calculateTimeRelativeToBed(
          const Duration(hours: 2),
          bedTime,
        );

        expect(result, DateTime(2025, 1, 1, 20, 0));
      });

      test('calculates time minutes before bed time', () {
        final bedTime = DateTime(2025, 1, 1, 22, 30);
        final result = DateTimeHelpers.calculateTimeRelativeToBed(
          const Duration(minutes: 45),
          bedTime,
        );

        expect(result, DateTime(2025, 1, 1, 21, 45));
      });
    });

    group('formatRelativeTime', () {
      test('formats minutes after', () {
        final time = DateTime(2025, 1, 1, 7, 30);
        final reference = DateTime(2025, 1, 1, 7, 0);
        final result = DateTimeHelpers.formatRelativeTime(time, reference);

        expect(result, '30 min after');
      });

      test('formats hours after', () {
        final time = DateTime(2025, 1, 1, 9, 0);
        final reference = DateTime(2025, 1, 1, 7, 0);
        final result = DateTimeHelpers.formatRelativeTime(time, reference);

        expect(result, '2 hours after');
      });

      test('formats hours and minutes after', () {
        final time = DateTime(2025, 1, 1, 9, 15);
        final reference = DateTime(2025, 1, 1, 7, 0);
        final result = DateTimeHelpers.formatRelativeTime(time, reference);

        expect(result, '2 hours 15 min after');
      });

      test('formats minutes before', () {
        final time = DateTime(2025, 1, 1, 21, 30);
        final reference = DateTime(2025, 1, 1, 22, 0);
        final result = DateTimeHelpers.formatRelativeTime(
          time,
          reference,
          isBeforeReference: true,
        );

        expect(result, '30 min before');
      });

      test('formats single hour after', () {
        final time = DateTime(2025, 1, 1, 8, 0);
        final reference = DateTime(2025, 1, 1, 7, 0);
        final result = DateTimeHelpers.formatRelativeTime(time, reference);

        expect(result, '1 hour after');
      });
    });

    group('parseTimeOfDay', () {
      test('parses morning time', () {
        final result = DateTimeHelpers.parseTimeOfDay('07:30');

        expect(result.hour, 7);
        expect(result.minute, 30);
      });

      test('parses midnight', () {
        final result = DateTimeHelpers.parseTimeOfDay('00:00');

        expect(result.hour, 0);
        expect(result.minute, 0);
      });

      test('parses evening time', () {
        final result = DateTimeHelpers.parseTimeOfDay('22:45');

        expect(result.hour, 22);
        expect(result.minute, 45);
      });
    });

    group('timeOfDayToDateTime', () {
      test('converts time to datetime on specific date', () {
        final time = const TimeOfDay(hour: 7, minute: 30);
        final date = DateTime(2025, 1, 15);
        final result = DateTimeHelpers.timeOfDayToDateTime(time, date);

        expect(result.year, 2025);
        expect(result.month, 1);
        expect(result.day, 15);
        expect(result.hour, 7);
        expect(result.minute, 30);
      });
    });

    group('formatTimeOfDay', () {
      test('formats morning time with leading zeros', () {
        final time = const TimeOfDay(hour: 7, minute: 30);
        final result = DateTimeHelpers.formatTimeOfDay(time);

        expect(result, '07:30');
      });

      test('formats midnight', () {
        final time = const TimeOfDay(hour: 0, minute: 0);
        final result = DateTimeHelpers.formatTimeOfDay(time);

        expect(result, '00:00');
      });

      test('formats evening time', () {
        final time = const TimeOfDay(hour: 22, minute: 5);
        final result = DateTimeHelpers.formatTimeOfDay(time);

        expect(result, '22:05');
      });
    });

    group('calculateHoursBetween', () {
      test('calculates hours between morning times', () {
        final start = const TimeOfDay(hour: 9, minute: 0);
        final end = const TimeOfDay(hour: 17, minute: 0);
        final result = DateTimeHelpers.calculateHoursBetween(start, end);

        expect(result, 8.0);
      });

      test('calculates hours with minutes', () {
        final start = const TimeOfDay(hour: 9, minute: 0);
        final end = const TimeOfDay(hour: 10, minute: 30);
        final result = DateTimeHelpers.calculateHoursBetween(start, end);

        expect(result, 1.5);
      });

      test('calculates hours across midnight (overnight)', () {
        final start = const TimeOfDay(hour: 22, minute: 0);
        final end = const TimeOfDay(hour: 6, minute: 0);
        final result = DateTimeHelpers.calculateHoursBetween(start, end);

        expect(result, 8.0);
      });

      test('calculates hours for same time (should be 0)', () {
        final start = const TimeOfDay(hour: 10, minute: 0);
        final end = const TimeOfDay(hour: 10, minute: 0);
        final result = DateTimeHelpers.calculateHoursBetween(start, end);

        expect(result, 0.0);
      });

      test('calculates fractional hours overnight', () {
        final start = const TimeOfDay(hour: 23, minute: 30);
        final end = const TimeOfDay(hour: 1, minute: 0);
        final result = DateTimeHelpers.calculateHoursBetween(start, end);

        expect(result, 1.5);
      });
    });

    group('addHours', () {
      test('adds hours normally', () {
        final time = const TimeOfDay(hour: 10, minute: 0);
        final result = DateTimeHelpers.addHours(time, 2.0);

        expect(result.hour, 12);
        expect(result.minute, 0);
      });

      test('adds fractional hours', () {
        final time = const TimeOfDay(hour: 10, minute: 0);
        final result = DateTimeHelpers.addHours(time, 1.5);

        expect(result.hour, 11);
        expect(result.minute, 30);
      });

      test('handles day overflow', () {
        final time = const TimeOfDay(hour: 23, minute: 0);
        final result = DateTimeHelpers.addHours(time, 2.0);

        expect(result.hour, 1);
        expect(result.minute, 0);
      });

      test('handles adding exactly 24 hours', () {
        final time = const TimeOfDay(hour: 10, minute: 0);
        final result = DateTimeHelpers.addHours(time, 24.0);

        expect(result.hour, 10);
        expect(result.minute, 0);
      });

      test('handles overflow with minutes', () {
        final time = const TimeOfDay(hour: 23, minute: 45);
        final result = DateTimeHelpers.addHours(time, 0.5);

        expect(result.hour, 0);
        expect(result.minute, 15);
      });
    });

    group('subtractHours', () {
      test('subtracts hours normally', () {
        final time = const TimeOfDay(hour: 14, minute: 0);
        final result = DateTimeHelpers.subtractHours(time, 2.0);

        expect(result.hour, 12);
        expect(result.minute, 0);
      });

      test('subtracts fractional hours', () {
        final time = const TimeOfDay(hour: 14, minute: 30);
        final result = DateTimeHelpers.subtractHours(time, 1.5);

        expect(result.hour, 13);
        expect(result.minute, 0);
      });

      test('handles day underflow', () {
        final time = const TimeOfDay(hour: 1, minute: 0);
        final result = DateTimeHelpers.subtractHours(time, 2.0);

        expect(result.hour, 23);
        expect(result.minute, 0);
      });

      test('handles underflow with minutes', () {
        final time = const TimeOfDay(hour: 0, minute: 15);
        final result = DateTimeHelpers.subtractHours(time, 0.5);

        expect(result.hour, 23);
        expect(result.minute, 45);
      });
    });

    group('midpoint', () {
      test('calculates midpoint for normal range', () {
        final start = const TimeOfDay(hour: 6, minute: 0);
        final end = const TimeOfDay(hour: 18, minute: 0);
        final result = DateTimeHelpers.midpoint(start, end);

        expect(result.hour, 12);
        expect(result.minute, 0);
      });

      test('calculates midpoint for overnight range', () {
        final start = const TimeOfDay(hour: 22, minute: 0);
        final end = const TimeOfDay(hour: 6, minute: 0);
        final result = DateTimeHelpers.midpoint(start, end);

        expect(result.hour, 2);
        expect(result.minute, 0);
      });

      test('calculates midpoint with odd hours', () {
        final start = const TimeOfDay(hour: 8, minute: 0);
        final end = const TimeOfDay(hour: 17, minute: 0);
        final result = DateTimeHelpers.midpoint(start, end);

        expect(result.hour, 12);
        expect(result.minute, 30);
      });

      test('calculates midpoint for adjacent times', () {
        final start = const TimeOfDay(hour: 10, minute: 0);
        final end = const TimeOfDay(hour: 11, minute: 0);
        final result = DateTimeHelpers.midpoint(start, end);

        expect(result.hour, 10);
        expect(result.minute, 30);
      });
    });

    group('getTimeOfDayCategory', () {
      test('categorizes early morning', () {
        final time = const TimeOfDay(hour: 5, minute: 0);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'morning');
      });

      test('categorizes mid-morning', () {
        final time = const TimeOfDay(hour: 9, minute: 30);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'morning');
      });

      test('categorizes noon', () {
        final time = const TimeOfDay(hour: 12, minute: 0);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'afternoon');
      });

      test('categorizes afternoon', () {
        final time = const TimeOfDay(hour: 14, minute: 0);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'afternoon');
      });

      test('categorizes evening', () {
        final time = const TimeOfDay(hour: 19, minute: 0);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'evening');
      });

      test('categorizes late evening', () {
        final time = const TimeOfDay(hour: 20, minute: 59);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'evening');
      });

      test('categorizes night', () {
        final time = const TimeOfDay(hour: 23, minute: 0);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'night');
      });

      test('categorizes midnight', () {
        final time = const TimeOfDay(hour: 0, minute: 0);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'night');
      });

      test('categorizes pre-dawn', () {
        final time = const TimeOfDay(hour: 4, minute: 30);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'night');
      });

      // Boundary tests
      test('categorizes boundary at 5:00 (morning starts)', () {
        final time = const TimeOfDay(hour: 5, minute: 0);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'morning');
      });

      test('categorizes boundary at 11:59 (last minute of morning)', () {
        final time = const TimeOfDay(hour: 11, minute: 59);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'morning');
      });

      test('categorizes boundary at 16:59 (last minute of afternoon)', () {
        final time = const TimeOfDay(hour: 16, minute: 59);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'afternoon');
      });

      test('categorizes boundary at 17:00 (evening starts)', () {
        final time = const TimeOfDay(hour: 17, minute: 0);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'evening');
      });

      test('categorizes boundary at 21:00 (night starts)', () {
        final time = const TimeOfDay(hour: 21, minute: 0);
        final result = DateTimeHelpers.getTimeOfDayCategory(time);

        expect(result, 'night');
      });
    });
  });
}
