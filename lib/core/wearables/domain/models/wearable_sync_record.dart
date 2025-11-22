import '../../../../shared/constants/database_constants.dart';
import '../../../utils/database_date_utils.dart';
import '../enums/sync_status.dart';
import '../enums/wearable_provider.dart';

/// Wearable data sync attempt record
///
/// Represents a single sync operation attempt.
/// Maps to the wearable_sync_history table in the database.
///
/// Used for:
/// - Debugging sync failures
/// - Showing "Last synced" time to users
/// - Analytics on sync reliability
class WearableSyncRecord {
  /// Unique sync record ID (UUID)
  final String id;

  /// User who performed the sync
  final String userId;

  /// Provider that was synced
  final WearableProvider provider;

  /// Start of date range requested
  final DateTime syncDateFrom;

  /// End of date range requested
  final DateTime syncDateTo;

  /// When sync operation started
  final DateTime syncStartedAt;

  /// When sync operation completed (nullable if still running or crashed)
  final DateTime? syncCompletedAt;

  /// Result status of the sync
  final SyncStatus status;

  /// Number of records fetched from provider API
  final int recordsFetched;

  /// Number of records successfully inserted into database
  final int recordsInserted;

  /// Number of existing records that were updated
  final int recordsUpdated;

  /// Number of records skipped (duplicates, invalid data, etc.)
  final int recordsSkipped;

  /// Error code if sync failed (nullable if successful)
  final String? errorCode;

  /// Human-readable error message if sync failed
  final String? errorMessage;

  const WearableSyncRecord({
    required this.id,
    required this.userId,
    required this.provider,
    required this.syncDateFrom,
    required this.syncDateTo,
    required this.syncStartedAt,
    this.syncCompletedAt,
    required this.status,
    this.recordsFetched = 0,
    this.recordsInserted = 0,
    this.recordsUpdated = 0,
    this.recordsSkipped = 0,
    this.errorCode,
    this.errorMessage,
  });

  // ========================================================================
  // Helper Methods
  // ========================================================================

  /// Calculate sync duration
  ///
  /// Returns duration of sync operation if completed, null otherwise.
  Duration? get syncDuration {
    if (syncCompletedAt == null) return null;
    return syncCompletedAt!.difference(syncStartedAt);
  }

  /// Check if sync is still running
  bool get isRunning {
    return syncCompletedAt == null && status != SyncStatus.failed;
  }

  /// Get human-readable summary
  String get summary {
    if (status == SyncStatus.success) {
      return 'Synced $recordsInserted records successfully';
    } else if (status == SyncStatus.partial) {
      return 'Synced $recordsInserted of $recordsFetched records';
    } else {
      return errorMessage ?? 'Sync failed';
    }
  }

  // ========================================================================
  // Database Serialization (for SQLite)
  // ========================================================================

  /// Create from database row
  factory WearableSyncRecord.fromDatabase(Map<String, dynamic> map) {
    return WearableSyncRecord(
      id: map[WEARABLE_SYNC_HISTORY_ID] as String,
      userId: map[WEARABLE_SYNC_HISTORY_USER_ID] as String,
      provider: WearableProvider.fromString(
        map[WEARABLE_SYNC_HISTORY_PROVIDER] as String,
      ),
      syncDateFrom: DatabaseDateUtils.fromString(
        map[WEARABLE_SYNC_HISTORY_SYNC_DATE_FROM] as String,
      ),
      syncDateTo: DatabaseDateUtils.fromString(
        map[WEARABLE_SYNC_HISTORY_SYNC_DATE_TO] as String,
      ),
      syncStartedAt: DatabaseDateUtils.fromString(
        map[WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT] as String,
      ),
      syncCompletedAt: map[WEARABLE_SYNC_HISTORY_SYNC_COMPLETED_AT] != null
          ? DatabaseDateUtils.fromString(
              map[WEARABLE_SYNC_HISTORY_SYNC_COMPLETED_AT] as String,
            )
          : null,
      status: SyncStatus.fromString(
        map[WEARABLE_SYNC_HISTORY_STATUS] as String,
      ),
      recordsFetched: map[WEARABLE_SYNC_HISTORY_RECORDS_FETCHED] as int,
      recordsInserted: map[WEARABLE_SYNC_HISTORY_RECORDS_INSERTED] as int,
      recordsUpdated: map[WEARABLE_SYNC_HISTORY_RECORDS_UPDATED] as int,
      recordsSkipped: map[WEARABLE_SYNC_HISTORY_RECORDS_SKIPPED] as int,
      errorCode: map[WEARABLE_SYNC_HISTORY_ERROR_CODE] as String?,
      errorMessage: map[WEARABLE_SYNC_HISTORY_ERROR_MESSAGE] as String?,
    );
  }

  /// Convert to database row
  Map<String, dynamic> toDatabase() {
    return {
      WEARABLE_SYNC_HISTORY_ID: id,
      WEARABLE_SYNC_HISTORY_USER_ID: userId,
      WEARABLE_SYNC_HISTORY_PROVIDER: provider.apiIdentifier,
      WEARABLE_SYNC_HISTORY_SYNC_DATE_FROM:
          DatabaseDateUtils.toDateString(syncDateFrom),
      WEARABLE_SYNC_HISTORY_SYNC_DATE_TO:
          DatabaseDateUtils.toDateString(syncDateTo),
      WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT:
          DatabaseDateUtils.toTimestamp(syncStartedAt),
      WEARABLE_SYNC_HISTORY_SYNC_COMPLETED_AT: syncCompletedAt != null
          ? DatabaseDateUtils.toTimestamp(syncCompletedAt!)
          : null,
      WEARABLE_SYNC_HISTORY_STATUS: status.apiIdentifier,
      WEARABLE_SYNC_HISTORY_RECORDS_FETCHED: recordsFetched,
      WEARABLE_SYNC_HISTORY_RECORDS_INSERTED: recordsInserted,
      WEARABLE_SYNC_HISTORY_RECORDS_UPDATED: recordsUpdated,
      WEARABLE_SYNC_HISTORY_RECORDS_SKIPPED: recordsSkipped,
      WEARABLE_SYNC_HISTORY_ERROR_CODE: errorCode,
      WEARABLE_SYNC_HISTORY_ERROR_MESSAGE: errorMessage,
    };
  }

  // ========================================================================
  // CopyWith
  // ========================================================================

  WearableSyncRecord copyWith({
    String? id,
    String? userId,
    WearableProvider? provider,
    DateTime? syncDateFrom,
    DateTime? syncDateTo,
    DateTime? syncStartedAt,
    DateTime? syncCompletedAt,
    SyncStatus? status,
    int? recordsFetched,
    int? recordsInserted,
    int? recordsUpdated,
    int? recordsSkipped,
    String? errorCode,
    String? errorMessage,
  }) {
    return WearableSyncRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      syncDateFrom: syncDateFrom ?? this.syncDateFrom,
      syncDateTo: syncDateTo ?? this.syncDateTo,
      syncStartedAt: syncStartedAt ?? this.syncStartedAt,
      syncCompletedAt: syncCompletedAt ?? this.syncCompletedAt,
      status: status ?? this.status,
      recordsFetched: recordsFetched ?? this.recordsFetched,
      recordsInserted: recordsInserted ?? this.recordsInserted,
      recordsUpdated: recordsUpdated ?? this.recordsUpdated,
      recordsSkipped: recordsSkipped ?? this.recordsSkipped,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'WearableSyncRecord('
        'id: $id, '
        'provider: ${provider.displayName}, '
        'status: ${status.displayName}, '
        'records: $recordsInserted/$recordsFetched'
        ')';
  }
}
