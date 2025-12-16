import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/wearables/domain/enums/sync_status.dart';

void main() {
  group('SyncStatus', () {
    group('displayName getter', () {
      test('returns "Success" for success', () {
        expect(SyncStatus.success.displayName, equals('Success'));
      });

      test('returns "Failed" for failed', () {
        expect(SyncStatus.failed.displayName, equals('Failed'));
      });

      test('returns "Partial" for partial', () {
        expect(SyncStatus.partial.displayName, equals('Partial'));
      });
    });

    group('apiIdentifier getter', () {
      test('returns "success" for success', () {
        expect(SyncStatus.success.apiIdentifier, equals('success'));
      });

      test('returns "failed" for failed', () {
        expect(SyncStatus.failed.apiIdentifier, equals('failed'));
      });

      test('returns "partial" for partial', () {
        expect(SyncStatus.partial.apiIdentifier, equals('partial'));
      });
    });

    group('fromString', () {
      test('parses "success" correctly', () {
        expect(SyncStatus.fromString('success'), equals(SyncStatus.success));
      });

      test('parses "failed" correctly', () {
        expect(SyncStatus.fromString('failed'), equals(SyncStatus.failed));
      });

      test('parses "partial" correctly', () {
        expect(SyncStatus.fromString('partial'), equals(SyncStatus.partial));
      });

      test('throws ArgumentError for invalid string', () {
        expect(
          () => SyncStatus.fromString('invalid_status'),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for empty string', () {
        expect(
          () => SyncStatus.fromString(''),
          throwsArgumentError,
        );
      });
    });
  });
}
