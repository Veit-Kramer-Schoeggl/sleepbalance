import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/utils/database_date_utils.dart';
import 'package:sleepbalance/core/wearables/domain/enums/sync_status.dart';
import 'package:sleepbalance/core/wearables/domain/enums/wearable_provider.dart';
import 'package:sleepbalance/core/wearables/domain/models/wearable_sync_record.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';

void main() {
  group('WearableSyncRecord', () {
    late DateTime testSyncDateFrom;
    late DateTime testSyncDateTo;
    late DateTime testSyncStartedAt;
    late DateTime testSyncCompletedAt;

    setUp(() {
      testSyncDateFrom = DateTime(2025, 11, 10);
      testSyncDateTo = DateTime(2025, 11, 16);
      testSyncStartedAt = DateTime(2025, 11, 16, 14, 30);
      testSyncCompletedAt = DateTime(2025, 11, 16, 14, 32); // 2 minutes later
    });

    group('Constructor and basic properties', () {
      test('creates with required fields only', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: null,
          status: SyncStatus.success,
          recordsFetched: 0,
          recordsInserted: 0,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorCode: null,
          errorMessage: null,
        );

        expect(record.id, equals('test-id'));
        expect(record.userId, equals('user-123'));
        expect(record.provider, equals(WearableProvider.fitbit));
        expect(record.syncDateFrom, equals(testSyncDateFrom));
        expect(record.syncDateTo, equals(testSyncDateTo));
        expect(record.syncStartedAt, equals(testSyncStartedAt));
        expect(record.syncCompletedAt, isNull);
        expect(record.status, equals(SyncStatus.success));
        expect(record.recordsFetched, equals(0));
        expect(record.recordsInserted, equals(0));
        expect(record.recordsUpdated, equals(0));
        expect(record.recordsSkipped, equals(0));
        expect(record.errorCode, isNull);
        expect(record.errorMessage, isNull);
      });

      test('creates with all fields', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: testSyncCompletedAt,
          status: SyncStatus.partial,
          recordsFetched: 10,
          recordsInserted: 8,
          recordsUpdated: 1,
          recordsSkipped: 1,
          errorCode: 'PARTIAL_SYNC',
          errorMessage: 'Some records could not be synced',
        );

        expect(record.syncCompletedAt, equals(testSyncCompletedAt));
        expect(record.status, equals(SyncStatus.partial));
        expect(record.recordsFetched, equals(10));
        expect(record.recordsInserted, equals(8));
        expect(record.recordsUpdated, equals(1));
        expect(record.recordsSkipped, equals(1));
        expect(record.errorCode, equals('PARTIAL_SYNC'));
        expect(record.errorMessage, equals('Some records could not be synced'));
      });
    });

    group('Database serialization', () {
      test('fromDatabase with all fields', () {
        final map = {
          WEARABLE_SYNC_HISTORY_ID: 'test-id',
          WEARABLE_SYNC_HISTORY_USER_ID: 'user-123',
          WEARABLE_SYNC_HISTORY_PROVIDER: 'fitbit',
          WEARABLE_SYNC_HISTORY_SYNC_DATE_FROM: DatabaseDateUtils.toDateString(testSyncDateFrom),
          WEARABLE_SYNC_HISTORY_SYNC_DATE_TO: DatabaseDateUtils.toDateString(testSyncDateTo),
          WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT: DatabaseDateUtils.toTimestamp(testSyncStartedAt),
          WEARABLE_SYNC_HISTORY_SYNC_COMPLETED_AT: DatabaseDateUtils.toTimestamp(testSyncCompletedAt),
          WEARABLE_SYNC_HISTORY_STATUS: 'success',
          WEARABLE_SYNC_HISTORY_RECORDS_FETCHED: 15,
          WEARABLE_SYNC_HISTORY_RECORDS_INSERTED: 12,
          WEARABLE_SYNC_HISTORY_RECORDS_UPDATED: 2,
          WEARABLE_SYNC_HISTORY_RECORDS_SKIPPED: 1,
          WEARABLE_SYNC_HISTORY_ERROR_CODE: 'TEST_ERROR',
          WEARABLE_SYNC_HISTORY_ERROR_MESSAGE: 'Test error message',
        };

        final record = WearableSyncRecord.fromDatabase(map);

        expect(record.id, equals('test-id'));
        expect(record.userId, equals('user-123'));
        expect(record.provider, equals(WearableProvider.fitbit));
        expect(record.syncDateFrom, equals(testSyncDateFrom));
        expect(record.syncDateTo, equals(testSyncDateTo));
        expect(record.syncStartedAt, equals(testSyncStartedAt));
        expect(record.syncCompletedAt, equals(testSyncCompletedAt));
        expect(record.status, equals(SyncStatus.success));
        expect(record.recordsFetched, equals(15));
        expect(record.recordsInserted, equals(12));
        expect(record.recordsUpdated, equals(2));
        expect(record.recordsSkipped, equals(1));
        expect(record.errorCode, equals('TEST_ERROR'));
        expect(record.errorMessage, equals('Test error message'));
      });

      test('fromDatabase with nullable fields as null', () {
        final map = {
          WEARABLE_SYNC_HISTORY_ID: 'test-id',
          WEARABLE_SYNC_HISTORY_USER_ID: 'user-123',
          WEARABLE_SYNC_HISTORY_PROVIDER: 'apple_health',
          WEARABLE_SYNC_HISTORY_SYNC_DATE_FROM: DatabaseDateUtils.toDateString(testSyncDateFrom),
          WEARABLE_SYNC_HISTORY_SYNC_DATE_TO: DatabaseDateUtils.toDateString(testSyncDateTo),
          WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT: DatabaseDateUtils.toTimestamp(testSyncStartedAt),
          WEARABLE_SYNC_HISTORY_SYNC_COMPLETED_AT: null,
          WEARABLE_SYNC_HISTORY_STATUS: 'failed',
          WEARABLE_SYNC_HISTORY_RECORDS_FETCHED: 0,
          WEARABLE_SYNC_HISTORY_RECORDS_INSERTED: 0,
          WEARABLE_SYNC_HISTORY_RECORDS_UPDATED: 0,
          WEARABLE_SYNC_HISTORY_RECORDS_SKIPPED: 0,
          WEARABLE_SYNC_HISTORY_ERROR_CODE: null,
          WEARABLE_SYNC_HISTORY_ERROR_MESSAGE: null,
        };

        final record = WearableSyncRecord.fromDatabase(map);

        expect(record.provider, equals(WearableProvider.appleHealth));
        expect(record.syncCompletedAt, isNull);
        expect(record.status, equals(SyncStatus.failed));
        expect(record.errorCode, isNull);
        expect(record.errorMessage, isNull);
      });

      test('toDatabase with all fields', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.garmin,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: testSyncCompletedAt,
          status: SyncStatus.partial,
          recordsFetched: 20,
          recordsInserted: 15,
          recordsUpdated: 3,
          recordsSkipped: 2,
          errorCode: 'PARTIAL_ERROR',
          errorMessage: 'Some records failed',
        );

        final map = record.toDatabase();

        expect(map[WEARABLE_SYNC_HISTORY_ID], equals('test-id'));
        expect(map[WEARABLE_SYNC_HISTORY_USER_ID], equals('user-123'));
        expect(map[WEARABLE_SYNC_HISTORY_PROVIDER], equals('garmin'));
        expect(map[WEARABLE_SYNC_HISTORY_SYNC_DATE_FROM], equals(DatabaseDateUtils.toDateString(testSyncDateFrom)));
        expect(map[WEARABLE_SYNC_HISTORY_SYNC_DATE_TO], equals(DatabaseDateUtils.toDateString(testSyncDateTo)));
        expect(map[WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT], equals(DatabaseDateUtils.toTimestamp(testSyncStartedAt)));
        expect(map[WEARABLE_SYNC_HISTORY_SYNC_COMPLETED_AT], equals(DatabaseDateUtils.toTimestamp(testSyncCompletedAt)));
        expect(map[WEARABLE_SYNC_HISTORY_STATUS], equals('partial'));
        expect(map[WEARABLE_SYNC_HISTORY_RECORDS_FETCHED], equals(20));
        expect(map[WEARABLE_SYNC_HISTORY_RECORDS_INSERTED], equals(15));
        expect(map[WEARABLE_SYNC_HISTORY_RECORDS_UPDATED], equals(3));
        expect(map[WEARABLE_SYNC_HISTORY_RECORDS_SKIPPED], equals(2));
        expect(map[WEARABLE_SYNC_HISTORY_ERROR_CODE], equals('PARTIAL_ERROR'));
        expect(map[WEARABLE_SYNC_HISTORY_ERROR_MESSAGE], equals('Some records failed'));
      });

      test('toDatabase handles nullable fields', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.googleFit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: null,
          status: SyncStatus.failed,
          recordsFetched: 0,
          recordsInserted: 0,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorCode: null,
          errorMessage: null,
        );

        final map = record.toDatabase();

        expect(map[WEARABLE_SYNC_HISTORY_PROVIDER], equals('google_fit'));
        expect(map[WEARABLE_SYNC_HISTORY_SYNC_COMPLETED_AT], isNull);
        expect(map[WEARABLE_SYNC_HISTORY_STATUS], equals('failed'));
        expect(map[WEARABLE_SYNC_HISTORY_ERROR_CODE], isNull);
        expect(map[WEARABLE_SYNC_HISTORY_ERROR_MESSAGE], isNull);
      });

      test('database round-trip preserves all data', () {
        final original = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: testSyncCompletedAt,
          status: SyncStatus.success,
          recordsFetched: 25,
          recordsInserted: 20,
          recordsUpdated: 3,
          recordsSkipped: 2,
          errorCode: 'TEST_CODE',
          errorMessage: 'Test message',
        );

        final map = original.toDatabase();
        final restored = WearableSyncRecord.fromDatabase(map);

        expect(restored.id, equals(original.id));
        expect(restored.userId, equals(original.userId));
        expect(restored.provider, equals(original.provider));
        expect(restored.syncDateFrom, equals(original.syncDateFrom));
        expect(restored.syncDateTo, equals(original.syncDateTo));
        expect(restored.syncStartedAt, equals(original.syncStartedAt));
        expect(restored.syncCompletedAt, equals(original.syncCompletedAt));
        expect(restored.status, equals(original.status));
        expect(restored.recordsFetched, equals(original.recordsFetched));
        expect(restored.recordsInserted, equals(original.recordsInserted));
        expect(restored.recordsUpdated, equals(original.recordsUpdated));
        expect(restored.recordsSkipped, equals(original.recordsSkipped));
        expect(restored.errorCode, equals(original.errorCode));
        expect(restored.errorMessage, equals(original.errorMessage));
      });
    });

    group('syncDuration getter', () {
      test('returns null when syncCompletedAt is null', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: null,
          status: SyncStatus.success,
          recordsFetched: 0,
          recordsInserted: 0,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorCode: null,
          errorMessage: null,
        );

        expect(record.syncDuration, isNull);
      });

      test('calculates duration correctly when completed', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: testSyncCompletedAt,
          status: SyncStatus.success,
          recordsFetched: 10,
          recordsInserted: 10,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorCode: null,
          errorMessage: null,
        );

        expect(record.syncDuration, equals(const Duration(minutes: 2)));
      });
    });

    group('isRunning getter', () {
      test('returns true when not completed and not failed', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: null,
          status: SyncStatus.success,
          recordsFetched: 0,
          recordsInserted: 0,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorCode: null,
          errorMessage: null,
        );

        expect(record.isRunning, isTrue);
      });

      test('returns false when completed', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: testSyncCompletedAt,
          status: SyncStatus.success,
          recordsFetched: 10,
          recordsInserted: 10,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorCode: null,
          errorMessage: null,
        );

        expect(record.isRunning, isFalse);
      });

      test('returns false when failed', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: null,
          status: SyncStatus.failed,
          recordsFetched: 0,
          recordsInserted: 0,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorCode: 'SYNC_ERROR',
          errorMessage: 'Sync failed',
        );

        expect(record.isRunning, isFalse);
      });
    });

    group('summary getter', () {
      test('returns success message for success status', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: testSyncCompletedAt,
          status: SyncStatus.success,
          recordsFetched: 10,
          recordsInserted: 10,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorCode: null,
          errorMessage: null,
        );

        expect(record.summary, equals('Synced 10 records successfully'));
      });

      test('returns partial message for partial status', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: testSyncCompletedAt,
          status: SyncStatus.partial,
          recordsFetched: 10,
          recordsInserted: 8,
          recordsUpdated: 0,
          recordsSkipped: 2,
          errorCode: 'PARTIAL_ERROR',
          errorMessage: 'Some records failed',
        );

        expect(record.summary, equals('Synced 8 of 10 records'));
      });

      test('returns error message for failed status', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: testSyncCompletedAt,
          status: SyncStatus.failed,
          recordsFetched: 0,
          recordsInserted: 0,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorCode: 'SYNC_ERROR',
          errorMessage: 'Connection failed',
        );

        // When failed, summary returns the error message if available
        expect(record.summary, equals('Connection failed'));
      });

      test('returns default message for failed status when no error message', () {
        final record = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: testSyncCompletedAt,
          status: SyncStatus.failed,
          recordsFetched: 0,
          recordsInserted: 0,
          recordsUpdated: 0,
          recordsSkipped: 0,
          errorCode: 'SYNC_ERROR',
          errorMessage: null,
        );

        // When failed with no error message, returns default
        expect(record.summary, equals('Sync failed'));
      });
    });

    group('copyWith method', () {
      late WearableSyncRecord original;

      setUp(() {
        original = WearableSyncRecord(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: testSyncDateFrom,
          syncDateTo: testSyncDateTo,
          syncStartedAt: testSyncStartedAt,
          syncCompletedAt: null,
          status: SyncStatus.success,
          recordsFetched: 10,
          recordsInserted: 8,
          recordsUpdated: 1,
          recordsSkipped: 1,
          errorCode: null,
          errorMessage: null,
        );
      });

      test('updates specified fields', () {
        final updated = original.copyWith(
          syncCompletedAt: testSyncCompletedAt,
          recordsInserted: 10,
          recordsSkipped: 0,
        );

        expect(updated.syncCompletedAt, equals(testSyncCompletedAt));
        expect(updated.recordsInserted, equals(10));
        expect(updated.recordsSkipped, equals(0));
        // Unchanged fields
        expect(updated.id, equals('test-id'));
        expect(updated.userId, equals('user-123'));
        expect(updated.recordsFetched, equals(10));
        expect(updated.recordsUpdated, equals(1));
      });

      test('with no parameters returns copy with same values', () {
        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.userId, equals(original.userId));
        expect(copy.provider, equals(original.provider));
        expect(copy.syncDateFrom, equals(original.syncDateFrom));
        expect(copy.syncDateTo, equals(original.syncDateTo));
        expect(copy.syncStartedAt, equals(original.syncStartedAt));
        expect(copy.syncCompletedAt, equals(original.syncCompletedAt));
        expect(copy.status, equals(original.status));
        expect(copy.recordsFetched, equals(original.recordsFetched));
        expect(copy.recordsInserted, equals(original.recordsInserted));
        expect(copy.recordsUpdated, equals(original.recordsUpdated));
        expect(copy.recordsSkipped, equals(original.recordsSkipped));
        expect(copy.errorCode, equals(original.errorCode));
        expect(copy.errorMessage, equals(original.errorMessage));
      });
    });
  });
}
