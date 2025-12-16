import '../enums/wearable_provider.dart';
import '../models/wearable_credentials.dart';
import '../models/wearable_sync_record.dart';

/// Repository for managing wearable authentication and connection state
///
/// Provides interface for:
/// - Saving and retrieving OAuth credentials
/// - Checking connection status
/// - Managing token lifecycle
/// - Recording sync history
///
/// Concrete implementation in data layer.
abstract class WearableAuthRepository {
  // ========================================================================
  // Connection Management
  // ========================================================================

  /// Save new wearable connection
  ///
  /// Stores OAuth credentials for a wearable provider.
  /// If connection already exists for this user+provider, replaces it.
  ///
  /// Parameters:
  /// - credentials: Complete OAuth credentials to save
  ///
  /// Throws: Exception if database operation fails
  Future<void> saveConnection(WearableCredentials credentials);

  /// Get connection for specific provider
  ///
  /// Returns credentials if connection exists and is active.
  /// Returns null if no connection or connection is inactive.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - provider: Wearable provider to query
  ///
  /// Returns: WearableCredentials or null
  Future<WearableCredentials?> getConnection(
    String userId,
    WearableProvider provider,
  );

  /// Get all connections for user
  ///
  /// Returns all wearable connections (active and inactive).
  /// Empty list if user has no connections.
  ///
  /// Parameters:
  /// - userId: User's ID
  ///
  /// Returns: List of WearableCredentials
  Future<List<WearableCredentials>> getAllConnections(String userId);

  /// Get all active connections
  ///
  /// Returns only connections where isActive = true.
  /// Useful for displaying currently connected devices.
  ///
  /// Parameters:
  /// - userId: User's ID
  ///
  /// Returns: List of active WearableCredentials
  Future<List<WearableCredentials>> getActiveConnections(String userId);

  /// Disconnect provider
  ///
  /// Deletes the connection record from database.
  /// This is destructive - credentials cannot be recovered.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - provider: Provider to disconnect
  Future<void> disconnectProvider(String userId, WearableProvider provider);

  // ========================================================================
  // Token Management
  // ========================================================================

  /// Check if connection has valid token
  ///
  /// Returns true if:
  /// - Connection exists
  /// - Connection is active
  /// - Token is not expired (or has no expiration)
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - provider: Provider to check
  ///
  /// Returns: true if token is valid, false otherwise
  Future<bool> isTokenValid(String userId, WearableProvider provider);

  /// Update access token
  ///
  /// Updates access token and expiration for an existing connection.
  /// Used after token refresh operations.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - provider: Provider whose token to update
  /// - newToken: New access token
  /// - expiresAt: New expiration time
  Future<void> updateAccessToken(
    String userId,
    WearableProvider provider,
    String newToken,
    DateTime expiresAt,
  );

  /// Update last sync time
  ///
  /// Records when data was last successfully synced from provider.
  /// Displayed to user as "Last synced X hours ago".
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - provider: Provider that was synced
  /// - syncTime: When sync completed
  Future<void> updateLastSyncTime(
    String userId,
    WearableProvider provider,
    DateTime syncTime,
  );

  // ========================================================================
  // Sync History
  // ========================================================================

  /// Record sync attempt
  ///
  /// Logs details of a sync operation for debugging and transparency.
  /// Called after each sync attempt (success or failure).
  ///
  /// Parameters:
  /// - record: Complete sync record with results
  Future<void> recordSyncAttempt(WearableSyncRecord record);

  /// Get last sync record
  ///
  /// Returns most recent sync attempt for a provider.
  /// Useful for displaying sync status to user.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - provider: Provider to query
  ///
  /// Returns: Most recent WearableSyncRecord or null if never synced
  Future<WearableSyncRecord?> getLastSyncRecord(
    String userId,
    WearableProvider provider,
  );

  /// Get recent sync history
  ///
  /// Returns last N sync attempts for a provider.
  /// Useful for debugging sync issues.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - provider: Provider to query
  /// - limit: Maximum number of records to return (default 10)
  ///
  /// Returns: List of WearableSyncRecord ordered by sync_started_at DESC
  Future<List<WearableSyncRecord>> getRecentSyncHistory(
    String userId,
    WearableProvider provider, {
    int limit = 10,
  });
}
