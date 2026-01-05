import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/wearables/domain/enums/wearable_provider.dart';

void main() {
  group('WearableProvider', () {
    group('displayName getter', () {
      test('returns "Fitbit" for fitbit', () {
        expect(WearableProvider.fitbit.displayName, equals('Fitbit'));
      });

      test('returns "Apple Health" for appleHealth', () {
        expect(WearableProvider.appleHealth.displayName, equals('Apple Health'));
      });

      test('returns "Google Fit" for googleFit', () {
        expect(WearableProvider.googleFit.displayName, equals('Google Fit'));
      });

      test('returns "Garmin" for garmin', () {
        expect(WearableProvider.garmin.displayName, equals('Garmin'));
      });
    });

    group('apiIdentifier getter', () {
      test('returns "fitbit" for fitbit', () {
        expect(WearableProvider.fitbit.apiIdentifier, equals('fitbit'));
      });

      test('returns "apple_health" for appleHealth', () {
        expect(WearableProvider.appleHealth.apiIdentifier, equals('apple_health'));
      });

      test('returns "google_fit" for googleFit', () {
        expect(WearableProvider.googleFit.apiIdentifier, equals('google_fit'));
      });

      test('returns "garmin" for garmin', () {
        expect(WearableProvider.garmin.apiIdentifier, equals('garmin'));
      });
    });

    group('fromString', () {
      test('parses "fitbit" correctly', () {
        expect(WearableProvider.fromString('fitbit'), equals(WearableProvider.fitbit));
      });

      test('parses "apple_health" correctly', () {
        expect(WearableProvider.fromString('apple_health'), equals(WearableProvider.appleHealth));
      });

      test('parses "google_fit" correctly', () {
        expect(WearableProvider.fromString('google_fit'), equals(WearableProvider.googleFit));
      });

      test('parses "garmin" correctly', () {
        expect(WearableProvider.fromString('garmin'), equals(WearableProvider.garmin));
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => WearableProvider.fromString('invalid_provider'),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for empty string', () {
        expect(
          () => WearableProvider.fromString(''),
          throwsArgumentError,
        );
      });
    });
  });
}
