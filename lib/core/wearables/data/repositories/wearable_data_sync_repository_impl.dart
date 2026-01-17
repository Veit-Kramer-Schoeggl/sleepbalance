import 'package:fitbitter/fitbitter.dart';
import 'package:sleepbalance/features/night_review/domain/models/sleep_record_sleep_phase.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/wearable_config.dart';
import '../../../../features/night_review/data/datasources/sleep_record_local_datasource.dart';
import '../../../../features/night_review/domain/models/sleep_record.dart';
import '../../domain/enums/sync_status.dart';
import '../../domain/enums/wearable_provider.dart';
import '../../domain/exceptions/wearable_exception.dart';
import '../../domain/models/wearable_credentials.dart';
import '../../domain/models/wearable_sync_record.dart';
import '../../domain/repositories/wearable_data_sync_repository.dart';
import '../datasources/fitbit_api_datasource.dart';
import '../datasources/wearable_credentials_local_datasource.dart';
import '../datasources/wearable_sync_record_local_datasource.dart';
import '../transformers/fitbit_sleep_transformer.dart';

/// Implementation of WearableDataSyncRepository
///
/// Orchestrates data synchronization from wearable providers to local database.
/// Handles token refresh, API calls, data transformation, and conflict resolution.
class WearableDataSyncRepositoryImpl implements WearableDataSyncRepository {
  WearableDataSyncRepositoryImpl({
    required WearableCredentialsLocalDataSource credentialsDataSource,
    required WearableSyncRecordLocalDataSource syncRecordDataSource,
    required FitbitApiDataSource fitbitApiDataSource,
    required SleepRecordLocalDataSource sleepRecordDataSource,
  })  : _credentialsDataSource = credentialsDataSource,
        _syncRecordDataSource = syncRecordDataSource,
        _fitbitApiDataSource = fitbitApiDataSource,
        _sleepRecordDataSource = sleepRecordDataSource;

  final WearableCredentialsLocalDataSource _credentialsDataSource;
  final WearableSyncRecordLocalDataSource _syncRecordDataSource;
  final FitbitApiDataSource _fitbitApiDataSource;
  final SleepRecordLocalDataSource _sleepRecordDataSource;

  static const _uuid = Uuid();
  static const _defaultSyncDays = 7; // Sync last 7 days by default
  static const _tokenRefreshThreshold =
      Duration(minutes: 5); // Refresh if expires within 5 min

  @override

  /// Starts the synchronization of sleep data for a given wearable provider.
  ///
  /// This method orchestrates the entire sync process, including:
  /// 1. Creating an initial sync record in the local database.
  /// 2. Verifying active credentials for the specified provider.
  /// 3. Refreshing the access token if it's about to expire.
  /// 4. Fetching sleep data from the provider's API for the given date range.
  /// 5. Transforming the fetched data into the application's domain models.
  /// 6. Saving the transformed data to the local database, with conflict resolution.
  /// 7. Updating the sync record with the final status (success, partial, or failed).
  ///
  /// Throws a [WearableException] for authentication errors, unimplemented providers,
  /// or any other failure during the sync process.
  Future<WearableSyncRecord> syncSleepData({
    required WearableProvider provider,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Determine date range
    final now = DateTime.now();
    final syncEndDate = endDate ?? now;
    final syncStartDate =
        startDate ?? now.subtract(Duration(days: _defaultSyncDays));

    // Create initial sync record
    var syncRecord = WearableSyncRecord(
      id: _uuid.v4(),
      userId: userId,
      provider: provider,
      syncDateFrom: syncStartDate,
      syncDateTo: syncEndDate,
      syncStartedAt: now,
      status: SyncStatus.failed, // Default to failed, update on success
    );

    // Save initial sync record
    await _syncRecordDataSource.insertSyncRecord(syncRecord);

    try {
      // Get credentials for provider
      final credentials = await _credentialsDataSource.getConnectionByProvider(
        userId,
        provider.apiIdentifier,
      );

      if (credentials == null || !credentials.isActive) {
        throw WearableException(
          message: 'No active ${provider.displayName} connection found',
          errorType: WearableErrorType.authentication,
        );
      }

      // Ensure token is valid (refresh if needed)
      final validCredentials = await _ensureValidToken(credentials);

      // Sync based on provider
      switch (provider) {
        case WearableProvider.fitbit:
          syncRecord = await _syncFitbitSleepData(
            credentials: validCredentials,
            startDate: syncStartDate,
            endDate: syncEndDate,
            syncRecord: syncRecord,
          );
          break;

        case WearableProvider.appleHealth:
        case WearableProvider.googleFit:
        case WearableProvider.garmin:
          throw WearableException(
            message: '${provider.displayName} sync not yet implemented',
            errorType: WearableErrorType.unknown,
          );
      }

      // Update sync record to success
      final completedRecord = syncRecord.copyWith(
        syncCompletedAt: DateTime.now(),
        status: syncRecord.recordsInserted > 0
            ? SyncStatus.success
            : SyncStatus.partial,
      );

      await _syncRecordDataSource.updateSyncRecord(completedRecord);
      return completedRecord;
    } on WearableException catch (e) {
      // Update sync record with error
      final failedRecord = syncRecord.copyWith(
        syncCompletedAt: DateTime.now(),
        status: SyncStatus.failed,
        errorCode: e.errorType.name,
        errorMessage: e.message,
      );

      await _syncRecordDataSource.updateSyncRecord(failedRecord);
      rethrow;
    } catch (e, stackTrace) {
      // Unexpected error
      final failedRecord = syncRecord.copyWith(
        syncCompletedAt: DateTime.now(),
        status: SyncStatus.failed,
        errorCode: 'unknown',
        errorMessage: 'Unexpected error: $e',
      );

      await _syncRecordDataSource.updateSyncRecord(failedRecord);

      throw WearableException(
        message: 'Sync failed unexpectedly: $e',
        errorType: WearableErrorType.unknown,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override

  /// Retrieves a list of past synchronization records for a user.
  ///
  /// Allows filtering by a specific [WearableProvider] and limiting the
  /// number of records returned.
  Future<List<WearableSyncRecord>> getSyncHistory({
    required String userId,
    WearableProvider? provider,
    int? limit,
  }) async {
    return _syncRecordDataSource.getSyncHistory(
      userId: userId,
      provider: provider,
      limit: limit,
    );
  }

  @override

  /// Retrieves the most recent synchronization record for a specific provider.
  Future<WearableSyncRecord?> getLastSync({
    required String userId,
    required WearableProvider provider,
  }) async {
    return _syncRecordDataSource.getLastSync(
      userId: userId,
      provider: provider,
    );
  }

  // ==========================================================================
  // Private Helper Methods
  // ==========================================================================

  /// Ensure access token is valid, refreshing if necessary
  ///
  /// Checks if token expires within [_tokenRefreshThreshold] and refreshes
  /// if needed to prevent mid-sync auth failures.
  Future<WearableCredentials> _ensureValidToken(
    WearableCredentials credentials,
  ) async {
    // If no expiration time or not expiring soon, use existing token
    if (credentials.tokenExpiresAt == null) {
      return credentials;
    }

    final now = DateTime.now();
    final expiresAt = credentials.tokenExpiresAt!;

    // Check if token expires within threshold
    if (expiresAt.difference(now) > _tokenRefreshThreshold) {
      return credentials; // Token still valid
    }

    // Token expired or expiring soon - refresh based on provider
    switch (credentials.provider) {
      case WearableProvider.fitbit:
        return await _refreshFitbitToken(credentials);

      case WearableProvider.appleHealth:
      case WearableProvider.googleFit:
      case WearableProvider.garmin:
        throw WearableException(
          message:
              'Token refresh not implemented for ${credentials.provider.displayName}',
          errorType: WearableErrorType.authentication,
        );
    }
  }

  /// Refresh Fitbit access token using refresh token
  ///
  /// Uses fitbitter's refreshToken() method and updates credentials in database.
  Future<WearableCredentials> _refreshFitbitToken(
    WearableCredentials credentials,
  ) async {
    try {
      // Create FitbitCredentials for refresh
      final fitbitCreds = FitbitCredentials(
        userID: credentials.userExternalId!,
        fitbitAccessToken: credentials.accessToken,
        fitbitRefreshToken: credentials.refreshToken!,
      );

      // Use fitbitter's refresh token method
      final newFitbitCredentials = await FitbitConnector.refreshToken(
        clientID: WearableConfig.fitbitClientId,
        clientSecret: WearableConfig.fitbitClientSecret,
        fitbitCredentials: fitbitCreds,
      );

      // Update our credentials model
      final updatedCredentials = credentials.copyWith(
        accessToken: newFitbitCredentials.fitbitAccessToken,
        refreshToken: newFitbitCredentials.fitbitRefreshToken,
        // fitbitter doesn't provide new expiration time on refresh
        // Keep existing expiration or set to 8 hours from now
        tokenExpiresAt: DateTime.now().add(const Duration(hours: 8)),
        updatedAt: DateTime.now(),
      );

      // Save updated credentials
      await _credentialsDataSource.updateConnection(updatedCredentials);

      return updatedCredentials;
    } catch (e, stackTrace) {
      throw WearableException(
        message: 'Failed to refresh Fitbit token: $e',
        errorType: WearableErrorType.authentication,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sync sleep data from Fitbit
  ///
  /// Fetches data for date range, transforms to SleepRecords, and saves with
  /// smart conflict resolution.
  ///
  /// Returns the updated sync record with final counts.
  Future<WearableSyncRecord> _syncFitbitSleepData({
    required WearableCredentials credentials,
    required DateTime startDate,
    required DateTime endDate,
    required WearableSyncRecord syncRecord,
  }) async {
    int recordsFetched = 0;
    int recordsInserted = 0;
    int recordsUpdated = 0;
    int recordsSkipped = 0;

    // Fetch data for each date in range
    var currentDate = startDate;
    while (!currentDate.isAfter(endDate)) {
      try {
        // Fetch sleep data for this date
        final fitbitData = await _fitbitApiDataSource.fetchSleepData(
          userId: credentials.userExternalId!,
          accessToken: credentials.accessToken,
          date: currentDate,
        );

        if (currentDate.day == DateTime.now().day) {
          recordsFetched = recordsFetched;
        }

        recordsFetched++;

        // Transform to SleepRecord
        final sleepRecord = FitbitSleepTransformer.transformSleepData(
          fitbitData: fitbitData,
          userId: credentials.userId,
        );

        if (sleepRecord != null) {
          // Save with smart conflict resolution
          final (wasUpdate, recordId) = await _saveSleepRecord(
            newRecord: sleepRecord,
            userId: credentials.userId,
          );

          final sleepPhases = FitbitSleepTransformer.transformSleepPhases(
              fitbitData,
              recordId
          );

          await _saveSleepPhases(sleepPhases, recordId);

          if (wasUpdate) {
            recordsUpdated++;
          } else {
            recordsInserted++;
          }
        } else {
          // No main sleep data for this date (only naps or no data)
          recordsSkipped++;
        }
      } catch (e) {
        // Skip this date on error, continue with others
        recordsSkipped++;
      }

      // Move to next day
      currentDate = currentDate.add(const Duration(days: 1));

      // Update sync record progress
      final updatedSyncRecord = syncRecord.copyWith(
        recordsFetched: recordsFetched,
        recordsInserted: recordsInserted,
        recordsUpdated: recordsUpdated,
        recordsSkipped: recordsSkipped,
      );
      await _syncRecordDataSource.updateSyncRecord(updatedSyncRecord);

      syncRecord = updatedSyncRecord;
    }

    // Update last sync time in credentials
    final updatedCredentials = credentials.copyWith(
      lastSyncAt: DateTime.now(),
    );
    await _credentialsDataSource.updateConnection(updatedCredentials);

    return syncRecord;
  }

  /// Save sleep record with smart conflict resolution
  ///
  /// Strategy:
  /// - No existing record → Insert new Fitbit data
  /// - Existing record from Fitbit → Replace with new data (re-sync)
  /// - Existing manual record → Merge (preserve user's quality notes)
  ///
  /// Returns true if an existing record was updated, false if new record inserted.
  Future<(bool, String)> _saveSleepRecord({
    required SleepRecord newRecord,
    required String userId,
  }) async {
    // Check for existing record on this date
    final existing = await _sleepRecordDataSource.getRecordByDate(
      userId,
      newRecord.sleepDate,
    );

    if (existing == null) {
      // No conflict - insert new record
      await _sleepRecordDataSource.insertRecord(newRecord);
      return (false, newRecord.id);
    }

    // Record exists - apply smart merge strategy
    if (existing.dataSource == 'fitbit') {
      // Re-sync from Fitbit - replace with new data
      final updatedRecord = newRecord.copyWith(
        id: existing.id, // Preserve existing ID
        createdAt: existing.createdAt, // Preserve creation time
        updatedAt: DateTime.now(),
      );
      await _sleepRecordDataSource.updateRecord(updatedRecord);
      return (true, updatedRecord.id);
    } else if (existing.dataSource == 'manual') {
      // Manual entry - merge Fitbit metrics with user's quality notes
      final mergedRecord = newRecord.copyWith(
        id: existing.id, // Preserve existing ID
        qualityRating: existing.qualityRating, // Preserve user rating
        qualityNotes: existing.qualityNotes, // Preserve user notes
        createdAt: existing.createdAt, // Preserve creation time
        updatedAt: DateTime.now(),
      );
      await _sleepRecordDataSource.insertRecord(mergedRecord);
      return (true, mergedRecord.id);
    }

    // Unknown data source - default to replace
    final updatedRecord = newRecord.copyWith(
      id: existing.id,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    await _sleepRecordDataSource.insertRecord(updatedRecord);
    return (true, updatedRecord.id);
  }

  /// Deletes all existing sleep phases for a given record and inserts the new ones.
  ///
  /// This ensures that every sync provides a completely fresh and up-to-date
  /// set of sleep phase data, preventing data duplication or conflicts from
  /// previous syncs.
  Future _saveSleepPhases(
    List<SleepRecordSleepPhase> phases,
    String sleepRecordId
  ) async {
    await _sleepRecordDataSource.clearPhasesForRecord(sleepRecordId);

    for (final phase in phases) {
      await _sleepRecordDataSource.insertSleepPhase(phase);
    }
  }
}
