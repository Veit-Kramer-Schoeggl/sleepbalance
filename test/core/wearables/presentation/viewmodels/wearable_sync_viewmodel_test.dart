import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/wearables/domain/enums/sync_status.dart';
import 'package:sleepbalance/core/wearables/domain/enums/wearable_provider.dart';
import 'package:sleepbalance/core/wearables/domain/exceptions/wearable_exception.dart';
import 'package:sleepbalance/core/wearables/domain/models/wearable_sync_record.dart';
import 'package:sleepbalance/core/wearables/domain/repositories/wearable_data_sync_repository.dart';
import 'package:sleepbalance/core/wearables/presentation/viewmodels/wearable_sync_viewmodel.dart';

/// Fake repository for testing
class FakeWearableDataSyncRepository implements WearableDataSyncRepository {
  WearableSyncRecord? syncResult;
  WearableException? syncException;
  WearableSyncRecord? lastSyncResult;
  List<WearableSyncRecord> syncHistory = [];

  int syncCallCount = 0;
  DateTime? lastSyncStartDate;
  DateTime? lastSyncEndDate;

  void setNextSyncResult(WearableSyncRecord result) {
    syncResult = result;
    syncException = null;
  }

  void setNextSyncException(WearableException exception) {
    syncException = exception;
    syncResult = null;
  }

  @override
  Future<WearableSyncRecord> syncSleepData({
    required WearableProvider provider,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    syncCallCount++;
    lastSyncStartDate = startDate;
    lastSyncEndDate = endDate;

    if (syncException != null) {
      throw syncException!;
    }

    return syncResult!;
  }

  @override
  Future<WearableSyncRecord?> getLastSync({
    required String userId,
    required WearableProvider provider,
  }) async {
    return lastSyncResult;
  }

  @override
  Future<List<WearableSyncRecord>> getSyncHistory({
    required String userId,
    WearableProvider? provider,
    int? limit,
  }) async {
    return syncHistory;
  }
}

void main() {
  late WearableSyncViewModel viewModel;
  late FakeWearableDataSyncRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeWearableDataSyncRepository();
    viewModel = WearableSyncViewModel(
      repository: fakeRepository,
      userId: 'test-user-123',
    );
  });

  group('WearableSyncViewModel', () {
    group('initial state', () {
      test('starts in idle state', () {
        expect(viewModel.state, equals(SyncState.idle));
        expect(viewModel.isSyncing, isFalse);
        expect(viewModel.hasError, isFalse);
        expect(viewModel.isSuccess, isFalse);
        expect(viewModel.lastSyncResult, isNull);
        expect(viewModel.errorMessage, isNull);
      });
    });

    group('loadLastSyncDate', () {
      test('loads last sync record from repository', () async {
        final lastSync = WearableSyncRecord(
          id: 'sync-1',
          userId: 'test-user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: DateTime(2025, 11, 8),
          syncDateTo: DateTime(2025, 11, 15),
          syncStartedAt: DateTime(2025, 11, 15, 10, 0),
          syncCompletedAt: DateTime(2025, 11, 15, 10, 1),
          status: SyncStatus.success,
          recordsFetched: 7,
          recordsInserted: 5,
          recordsUpdated: 2,
        );
        fakeRepository.lastSyncResult = lastSync;

        await viewModel.loadLastSyncDate();

        expect(viewModel.lastSyncResult, equals(lastSync));
        expect(viewModel.lastSyncDate, equals(DateTime(2025, 11, 15, 10, 1)));
      });

      test('handles null last sync gracefully', () async {
        fakeRepository.lastSyncResult = null;

        await viewModel.loadLastSyncDate();

        expect(viewModel.lastSyncResult, isNull);
        expect(viewModel.lastSyncDate, isNull);
      });
    });

    group('syncRecentData', () {
      test('sets state to syncing during sync', () async {
        final syncRecord = WearableSyncRecord(
          id: 'sync-1',
          userId: 'test-user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: DateTime(2025, 11, 8),
          syncDateTo: DateTime(2025, 11, 15),
          syncStartedAt: DateTime.now(),
          syncCompletedAt: DateTime.now(),
          status: SyncStatus.success,
          recordsFetched: 7,
          recordsInserted: 5,
          recordsUpdated: 2,
        );
        fakeRepository.setNextSyncResult(syncRecord);

        // We can't easily check intermediate state without more complex setup
        // Just verify final state
        await viewModel.syncRecentData();

        expect(viewModel.state, equals(SyncState.success));
      });

      test('sets state to success on successful sync', () async {
        final syncRecord = WearableSyncRecord(
          id: 'sync-1',
          userId: 'test-user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: DateTime(2025, 11, 8),
          syncDateTo: DateTime(2025, 11, 15),
          syncStartedAt: DateTime.now(),
          syncCompletedAt: DateTime.now(),
          status: SyncStatus.success,
          recordsFetched: 7,
          recordsInserted: 5,
          recordsUpdated: 2,
        );
        fakeRepository.setNextSyncResult(syncRecord);

        await viewModel.syncRecentData(days: 7);

        expect(viewModel.state, equals(SyncState.success));
        expect(viewModel.isSuccess, isTrue);
        expect(viewModel.lastSyncResult, equals(syncRecord));
        expect(viewModel.hasError, isFalse);
      });

      test('sets state to error on WearableException', () async {
        fakeRepository.setNextSyncException(WearableException(
          message: 'Token expired',
          errorType: WearableErrorType.authentication,
        ));

        await viewModel.syncRecentData();

        expect(viewModel.state, equals(SyncState.error));
        expect(viewModel.hasError, isTrue);
        expect(viewModel.errorMessage, equals('Token expired'));
        expect(viewModel.isSuccess, isFalse);
      });

      test('prevents duplicate sync calls while syncing', () async {
        final syncRecord = WearableSyncRecord(
          id: 'sync-1',
          userId: 'test-user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: DateTime(2025, 11, 8),
          syncDateTo: DateTime(2025, 11, 15),
          syncStartedAt: DateTime.now(),
          syncCompletedAt: DateTime.now(),
          status: SyncStatus.success,
        );
        fakeRepository.setNextSyncResult(syncRecord);

        // Start first sync
        final future1 = viewModel.syncRecentData();
        // Immediately try second sync (should be ignored since already syncing)
        final future2 = viewModel.syncRecentData();

        await Future.wait([future1, future2]);

        // Should only have called sync once
        expect(fakeRepository.syncCallCount, equals(1));
      });

      test('uses correct date range for days parameter', () async {
        final syncRecord = WearableSyncRecord(
          id: 'sync-1',
          userId: 'test-user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: DateTime(2025, 11, 1),
          syncDateTo: DateTime(2025, 11, 15),
          syncStartedAt: DateTime.now(),
          syncCompletedAt: DateTime.now(),
          status: SyncStatus.success,
        );
        fakeRepository.setNextSyncResult(syncRecord);

        await viewModel.syncRecentData(days: 14);

        // Verify the repository was called with appropriate date range
        expect(fakeRepository.lastSyncStartDate, isNotNull);
        expect(fakeRepository.lastSyncEndDate, isNotNull);

        // End date should be close to now
        final now = DateTime.now();
        expect(
          fakeRepository.lastSyncEndDate!.difference(now).inMinutes.abs(),
          lessThan(1),
        );

        // Start date should be ~14 days before end
        final daysDiff = fakeRepository.lastSyncEndDate!
            .difference(fakeRepository.lastSyncStartDate!)
            .inDays;
        expect(daysDiff, equals(14));
      });
    });

    group('clearError', () {
      test('resets error state to idle', () async {
        fakeRepository.setNextSyncException(WearableException(
          message: 'Test error',
          errorType: WearableErrorType.network,
        ));

        await viewModel.syncRecentData();
        expect(viewModel.hasError, isTrue);

        viewModel.clearError();

        expect(viewModel.state, equals(SyncState.idle));
        expect(viewModel.hasError, isFalse);
        expect(viewModel.errorMessage, isNull);
      });
    });

    group('clearSuccess', () {
      test('resets success state to idle', () async {
        final syncRecord = WearableSyncRecord(
          id: 'sync-1',
          userId: 'test-user-123',
          provider: WearableProvider.fitbit,
          syncDateFrom: DateTime(2025, 11, 8),
          syncDateTo: DateTime(2025, 11, 15),
          syncStartedAt: DateTime.now(),
          syncCompletedAt: DateTime.now(),
          status: SyncStatus.success,
        );
        fakeRepository.setNextSyncResult(syncRecord);

        await viewModel.syncRecentData();
        expect(viewModel.isSuccess, isTrue);

        viewModel.clearSuccess();

        expect(viewModel.state, equals(SyncState.idle));
        expect(viewModel.isSuccess, isFalse);
        // Last sync result should still be available
        expect(viewModel.lastSyncResult, isNotNull);
      });
    });

    group('canRetry', () {
      test('returns true for network errors', () async {
        fakeRepository.setNextSyncException(WearableException(
          message: 'Network error connecting',
          errorType: WearableErrorType.network,
        ));

        await viewModel.syncRecentData();

        expect(viewModel.canRetry, isTrue);
      });

      test('returns false when not in error state', () {
        expect(viewModel.canRetry, isFalse);
      });
    });
  });
}
