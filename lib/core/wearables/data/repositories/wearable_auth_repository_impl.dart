import '../../../utils/database_date_utils.dart';
import '../../domain/enums/wearable_provider.dart';
import '../../domain/models/wearable_credentials.dart';
import '../../domain/models/wearable_sync_record.dart';
import '../../domain/repositories/wearable_auth_repository.dart';
import '../datasources/wearable_credentials_local_datasource.dart';

/// Implementation of WearableAuthRepository
///
/// Delegates database operations to datasource and adds business logic layer.
class WearableAuthRepositoryImpl implements WearableAuthRepository {
  final WearableCredentialsLocalDataSource _dataSource;

  WearableAuthRepositoryImpl({required WearableCredentialsLocalDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<void> saveConnection(WearableCredentials credentials) async {
    await _dataSource.insertConnection(credentials);
  }

  @override
  Future<WearableCredentials?> getConnection(
    String userId,
    WearableProvider provider,
  ) async {
    return await _dataSource.getConnectionByProvider(
      userId,
      provider.apiIdentifier,
    );
  }

  @override
  Future<List<WearableCredentials>> getAllConnections(String userId) async {
    return await _dataSource.getAllUserConnections(userId);
  }

  @override
  Future<List<WearableCredentials>> getActiveConnections(String userId) async {
    return await _dataSource.getActiveConnections(userId);
  }

  @override
  Future<void> disconnectProvider(
    String userId,
    WearableProvider provider,
  ) async {
    await _dataSource.deleteConnection(userId, provider.apiIdentifier);
  }

  @override
  Future<bool> isTokenValid(String userId, WearableProvider provider) async {
    final connection = await getConnection(userId, provider);
    if (connection == null) return false;
    if (!connection.isActive) return false;
    return !connection.isTokenExpired();
  }

  @override
  Future<void> updateAccessToken(
    String userId,
    WearableProvider provider,
    String newToken,
    DateTime expiresAt,
  ) async {
    final connection = await getConnection(userId, provider);
    if (connection == null) {
      throw Exception('No connection found for provider: ${provider.displayName}');
    }

    final updated = connection.copyWith(
      accessToken: newToken,
      tokenExpiresAt: expiresAt,
      updatedAt: DateTime.now(),
    );

    await _dataSource.updateConnection(updated);
  }

  @override
  Future<void> updateLastSyncTime(
    String userId,
    WearableProvider provider,
    DateTime syncTime,
  ) async {
    await _dataSource.updateLastSyncTime(
      userId,
      provider.apiIdentifier,
      DatabaseDateUtils.toTimestamp(syncTime),
    );
  }

  @override
  Future<void> recordSyncAttempt(WearableSyncRecord record) async {
    await _dataSource.insertSyncRecord(record);
  }

  @override
  Future<WearableSyncRecord?> getLastSyncRecord(
    String userId,
    WearableProvider provider,
  ) async {
    return await _dataSource.getLatestSyncRecord(
      userId,
      provider.apiIdentifier,
    );
  }

  @override
  Future<List<WearableSyncRecord>> getRecentSyncHistory(
    String userId,
    WearableProvider provider, {
    int limit = 10,
  }) async {
    return await _dataSource.getRecentSyncHistory(
      userId,
      provider.apiIdentifier,
      limit,
    );
  }
}
