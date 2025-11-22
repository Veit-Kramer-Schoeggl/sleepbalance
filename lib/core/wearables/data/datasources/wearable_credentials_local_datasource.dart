import 'package:sqflite/sqflite.dart';

import '../../../../shared/constants/database_constants.dart';
import '../../domain/models/wearable_credentials.dart';
import '../../domain/models/wearable_sync_record.dart';

/// Local datasource for wearable credentials and sync history
///
/// Provides direct database access for wearable_connections and
/// wearable_sync_history tables. Follows the datasource pattern used
/// throughout the app (like SleepRecordLocalDataSource).
class WearableCredentialsLocalDataSource {
  final Database database;

  WearableCredentialsLocalDataSource({required this.database});

  // ========================================================================
  // Wearable Connections CRUD
  // ========================================================================

  /// Insert new connection
  Future<void> insertConnection(WearableCredentials credentials) async {
    await database.insert(
      TABLE_WEARABLE_CONNECTIONS,
      credentials.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get connection by provider
  Future<WearableCredentials?> getConnectionByProvider(
    String userId,
    String provider,
  ) async {
    final results = await database.query(
      TABLE_WEARABLE_CONNECTIONS,
      where: '$WEARABLE_CONNECTIONS_USER_ID = ? AND $WEARABLE_CONNECTIONS_PROVIDER = ?',
      whereArgs: [userId, provider],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return WearableCredentials.fromDatabase(results.first);
  }

  /// Get all connections for user
  Future<List<WearableCredentials>> getAllUserConnections(String userId) async {
    final results = await database.query(
      TABLE_WEARABLE_CONNECTIONS,
      where: '$WEARABLE_CONNECTIONS_USER_ID = ?',
      whereArgs: [userId],
      orderBy: '$WEARABLE_CONNECTIONS_CONNECTED_AT DESC',
    );

    return results.map((row) => WearableCredentials.fromDatabase(row)).toList();
  }

  /// Get active connections
  Future<List<WearableCredentials>> getActiveConnections(String userId) async {
    final results = await database.query(
      TABLE_WEARABLE_CONNECTIONS,
      where: '$WEARABLE_CONNECTIONS_USER_ID = ? AND $WEARABLE_CONNECTIONS_IS_ACTIVE = ?',
      whereArgs: [userId, 1],
      orderBy: '$WEARABLE_CONNECTIONS_CONNECTED_AT DESC',
    );

    return results.map((row) => WearableCredentials.fromDatabase(row)).toList();
  }

  /// Update connection
  Future<void> updateConnection(WearableCredentials credentials) async {
    await database.update(
      TABLE_WEARABLE_CONNECTIONS,
      credentials.toDatabase(),
      where: '$WEARABLE_CONNECTIONS_ID = ?',
      whereArgs: [credentials.id],
    );
  }

  /// Delete connection
  Future<void> deleteConnection(String userId, String provider) async {
    await database.delete(
      TABLE_WEARABLE_CONNECTIONS,
      where: '$WEARABLE_CONNECTIONS_USER_ID = ? AND $WEARABLE_CONNECTIONS_PROVIDER = ?',
      whereArgs: [userId, provider],
    );
  }

  /// Update last sync time
  Future<void> updateLastSyncTime(
    String userId,
    String provider,
    String syncTime,
  ) async {
    await database.update(
      TABLE_WEARABLE_CONNECTIONS,
      {WEARABLE_CONNECTIONS_LAST_SYNC_AT: syncTime},
      where: '$WEARABLE_CONNECTIONS_USER_ID = ? AND $WEARABLE_CONNECTIONS_PROVIDER = ?',
      whereArgs: [userId, provider],
    );
  }

  // ========================================================================
  // Sync History
  // ========================================================================

  /// Insert sync record
  Future<void> insertSyncRecord(WearableSyncRecord record) async {
    await database.insert(
      TABLE_WEARABLE_SYNC_HISTORY,
      record.toDatabase(),
    );
  }

  /// Get latest sync record
  Future<WearableSyncRecord?> getLatestSyncRecord(
    String userId,
    String provider,
  ) async {
    final results = await database.query(
      TABLE_WEARABLE_SYNC_HISTORY,
      where: '$WEARABLE_SYNC_HISTORY_USER_ID = ? AND $WEARABLE_SYNC_HISTORY_PROVIDER = ?',
      whereArgs: [userId, provider],
      orderBy: '$WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return WearableSyncRecord.fromDatabase(results.first);
  }

  /// Get recent sync history
  Future<List<WearableSyncRecord>> getRecentSyncHistory(
    String userId,
    String provider,
    int limit,
  ) async {
    final results = await database.query(
      TABLE_WEARABLE_SYNC_HISTORY,
      where: '$WEARABLE_SYNC_HISTORY_USER_ID = ? AND $WEARABLE_SYNC_HISTORY_PROVIDER = ?',
      whereArgs: [userId, provider],
      orderBy: '$WEARABLE_SYNC_HISTORY_SYNC_STARTED_AT DESC',
      limit: limit,
    );

    return results.map((row) => WearableSyncRecord.fromDatabase(row)).toList();
  }
}
