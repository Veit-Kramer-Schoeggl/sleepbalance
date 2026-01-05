/// Sync operation status
///
/// Represents the current state of a data synchronization operation.
enum SyncStatus {
  /// Sync operation completed successfully
  /// All requested data was fetched and stored without errors
  success,

  /// Sync operation failed completely
  /// No data was successfully synced (network error, auth error, etc.)
  failed,

  /// Sync operation partially completed
  /// Some data was synced, but some records failed or were skipped
  partial;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case SyncStatus.success:
        return 'Success';
      case SyncStatus.failed:
        return 'Failed';
      case SyncStatus.partial:
        return 'Partial';
    }
  }

  /// API identifier for database storage
  ///
  /// Lowercase string representation used in database status column.
  /// Must match CHECK constraint in wearable_sync_history table.
  String get apiIdentifier {
    switch (this) {
      case SyncStatus.success:
        return 'success';
      case SyncStatus.failed:
        return 'failed';
      case SyncStatus.partial:
        return 'partial';
    }
  }

  /// Parse from database string
  ///
  /// Converts database status value back to enum.
  /// Throws ArgumentError if status string is invalid.
  static SyncStatus fromString(String value) {
    switch (value) {
      case 'success':
        return SyncStatus.success;
      case 'failed':
        return SyncStatus.failed;
      case 'partial':
        return SyncStatus.partial;
      default:
        throw ArgumentError('Invalid sync status: $value');
    }
  }
}
