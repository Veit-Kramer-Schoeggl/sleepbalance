import 'package:sqflite/sqflite.dart';
import '../../../../shared/constants/database_constants.dart';
import '../../domain/enums/wearable_provider.dart';
import '../../domain/models/wearable_sync_record.dart';

/// Wearable Sync Record Local Data Source
///
/// Handles SQLite operations for wearable sync history records.
/// Provides low-level database access for tracking sync attempts.
class WearableSyncRecordLocalDataSource {
  final Database database;

  WearableSyncRecordLocalDataSource({required this.database});

  /// Insert a new sync record
  ///
  /// Used to create a record at the start of a sync operation.
  Future<void> insertSyncRecord(WearableSyncRecord record) async {
    await database.insert(
      TABLE_WEARABLE_SYNC_HISTORY,
      record.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing sync record
  ///
  /// Used to update sync progress and final status.
  Future<void> updateSyncRecord(WearableSyncRecord record) async {
    await database.update(
      TABLE_WEARABLE_SYNC_HISTORY,
      record.toDatabase(),
      where: '$WEARABLE_SYNC_HISTORY_ID = ?',
      whereArgs: [record.id],
    );
  }

  /// Get sync history for a user
  ///
  /// Returns list of sync records, optionally filtered by provider.
  /// Results are ordered by sync start time (most recent first).
  Future<List<WearableSyncRecord>> getSyncHistory({
    required String userId,
    WearableProvider? provider,
    int? limit,
  }) async {
    String where = '$WEARABLE_SYNC_HISTORY_USER_ID = ?';
    List<dynamic> whereArgs = [userId];

    if (provider != null) {
      where += ' AND $WEARABLE_SYNC_HISTORY_PROVIDER = ?';
      whereArgs.add(provider.apiIdentifier);
    }

    final results = await database.query(
      TABLE_WEARABLE_SYNC_HISTORY,
      where: where,
      whereArgs: whereArgs,
      orderBy: '$WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT DESC',
      limit: limit,
    );

    return results.map((row) => WearableSyncRecord.fromDatabase(row)).toList();
  }

  /// Get the most recent sync record for a provider
  ///
  /// Returns the last sync attempt, or null if no sync has occurred.
  Future<WearableSyncRecord?> getLastSync({
    required String userId,
    required WearableProvider provider,
  }) async {
    final results = await database.query(
      TABLE_WEARABLE_SYNC_HISTORY,
      where:
          '$WEARABLE_SYNC_HISTORY_USER_ID = ? AND $WEARABLE_SYNC_HISTORY_PROVIDER = ?',
      whereArgs: [userId, provider.apiIdentifier],
      orderBy: '$WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return WearableSyncRecord.fromDatabase(results.first);
  }

  /// Get a sync record by ID
  ///
  /// Returns the sync record with the specified ID, or null if not found.
  Future<WearableSyncRecord?> getSyncRecordById(String id) async {
    final results = await database.query(
      TABLE_WEARABLE_SYNC_HISTORY,
      where: '$WEARABLE_SYNC_HISTORY_ID = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return WearableSyncRecord.fromDatabase(results.first);
  }
}
