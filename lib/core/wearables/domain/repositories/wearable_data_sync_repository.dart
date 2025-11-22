import '../enums/wearable_provider.dart';
import '../models/wearable_sync_record.dart';

/// Repository interface for wearable data synchronization
///
/// Handles fetching sleep data from wearable providers (Fitbit, etc.)
/// and syncing it into the local database.
abstract class WearableDataSyncRepository {
  /// Sync sleep data from a wearable provider
  ///
  /// Fetches sleep records from [provider] for the specified date range
  /// and saves them to the local database with smart conflict resolution.
  ///
  /// If [startDate] and [endDate] are not provided, syncs the last 7 days.
  ///
  /// Returns a [WearableSyncRecord] containing sync statistics and status.
  ///
  /// Throws [WearableException] on auth, network, or API errors.
  Future<WearableSyncRecord> syncSleepData({
    required WearableProvider provider,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get sync history for a user
  ///
  /// Returns list of past sync attempts, optionally filtered by [provider].
  /// Results are ordered by sync start time (most recent first).
  ///
  /// [limit] restricts the number of records returned (default: all).
  Future<List<WearableSyncRecord>> getSyncHistory({
    required String userId,
    WearableProvider? provider,
    int? limit,
  });

  /// Get the most recent sync record for a provider
  ///
  /// Returns the last sync attempt for [provider] and [userId],
  /// or null if no sync has occurred yet.
  Future<WearableSyncRecord?> getLastSync({
    required String userId,
    required WearableProvider provider,
  });
}
