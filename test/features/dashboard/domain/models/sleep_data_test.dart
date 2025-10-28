import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/dashboard/domain/models/sleep_data.dart';

void main() {
  group('SleepData', () {
    late SleepData sleepData;

    setUp(() {
      sleepData = SleepData(
        timestamp: DateTime(2024, 1, 15, 7, 30),
        lightSleepMinutes: 180,
        deepSleepMinutes: 120,
        remSleepMinutes: 90,
        averageHeartRate: 65,
        lowestHeartRate: 58,
        highestHeartRate: 72,
        heartRateVariability: 45,
        breathingRate: 16,
        fragmentationScore: 25,
        timesAwake: 2,
        numberOfWakeUps: 3,
      );
    });

    test('calculates total sleep minutes correctly', () {
      expect(sleepData.totalSleepMinutes, equals(390)); // 180 + 120 + 90
    });

    test('formats total sleep time correctly', () {
      expect(sleepData.totalSleepFormatted, equals('6h 30m')); // 390 minutes = 6h 30m
    });

    test('converts to JSON correctly', () {
      final json = sleepData.toJson();
      
      expect(json['lightSleepMinutes'], equals(180));
      expect(json['deepSleepMinutes'], equals(120));
      expect(json['remSleepMinutes'], equals(90));
      expect(json['averageHeartRate'], equals(65));
      expect(json['fragmentationScore'], equals(25));
    });

    test('creates from JSON correctly', () {
      final json = {
        'timestamp': '2024-01-15T07:30:00.000',
        'lightSleepMinutes': 180,
        'deepSleepMinutes': 120,
        'remSleepMinutes': 90,
        'averageHeartRate': 65,
        'lowestHeartRate': 58,
        'highestHeartRate': 72,
        'heartRateVariability': 45,
        'breathingRate': 16,
        'fragmentationScore': 25,
        'timesAwake': 2,
        'numberOfWakeUps': 3,
      };

      final sleepDataFromJson = SleepData.fromJson(json);
      
      expect(sleepDataFromJson.lightSleepMinutes, equals(180));
      expect(sleepDataFromJson.averageHeartRate, equals(65));
      expect(sleepDataFromJson.totalSleepMinutes, equals(390));
    });
  });
}