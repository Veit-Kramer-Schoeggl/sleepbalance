import 'dart:convert';

import '../../../../shared/constants/database_constants.dart';
import '../../../utils/database_date_utils.dart';
import '../enums/wearable_provider.dart';

/// Wearable device OAuth credentials
///
/// Stores authentication credentials for a connected wearable device.
/// Maps to the wearable_connections table in the database.
///
/// Each user can have one connection per provider (enforced by database).
class WearableCredentials {
  /// Unique credential ID (UUID)
  final String id;

  /// User who owns this connection
  final String userId;

  /// Wearable provider (Fitbit, Apple Health, etc.)
  final WearableProvider provider;

  /// OAuth access token for API requests
  final String accessToken;

  /// OAuth refresh token (nullable - some providers don't use refresh tokens)
  final String? refreshToken;

  /// When the access token expires (nullable if no expiration)
  final DateTime? tokenExpiresAt;

  /// Provider-specific user ID (e.g., Fitbit user ID)
  final String? userExternalId;

  /// Granted OAuth scopes as JSON array
  /// Example: ["sleep", "heartrate", "activity"]
  final List<String>? grantedScopes;

  /// Whether this connection is currently active
  final bool isActive;

  /// When the connection was first established
  final DateTime connectedAt;

  /// When data was last synced from this provider (nullable if never synced)
  final DateTime? lastSyncAt;

  /// When this record was created
  final DateTime createdAt;

  /// When this record was last updated
  final DateTime updatedAt;

  const WearableCredentials({
    required this.id,
    required this.userId,
    required this.provider,
    required this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.userExternalId,
    this.grantedScopes,
    this.isActive = true,
    required this.connectedAt,
    this.lastSyncAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // ========================================================================
  // Helper Methods
  // ========================================================================

  /// Check if access token is expired
  ///
  /// Returns true if token has an expiration date and it has passed.
  /// Returns false if no expiration date (token doesn't expire).
  bool isTokenExpired() {
    if (tokenExpiresAt == null) return false;
    return DateTime.now().isAfter(tokenExpiresAt!);
  }

  /// Get scopes as comma-separated string for display
  String get scopesDisplay {
    if (grantedScopes == null || grantedScopes!.isEmpty) {
      return 'None';
    }
    return grantedScopes!.join(', ');
  }

  // ========================================================================
  // Database Serialization (for SQLite)
  // ========================================================================

  /// Create from database row
  ///
  /// Converts SQLite row to WearableCredentials instance.
  /// Handles type conversions:
  /// - TEXT → DateTime
  /// - INTEGER → bool
  /// - TEXT (JSON) → List<String>
  factory WearableCredentials.fromDatabase(Map<String, dynamic> map) {
    return WearableCredentials(
      id: map[WEARABLE_CONNECTIONS_ID] as String,
      userId: map[WEARABLE_CONNECTIONS_USER_ID] as String,
      provider: WearableProvider.fromString(
        map[WEARABLE_CONNECTIONS_PROVIDER] as String,
      ),
      accessToken: map[WEARABLE_CONNECTIONS_ACCESS_TOKEN] as String,
      refreshToken: map[WEARABLE_CONNECTIONS_REFRESH_TOKEN] as String?,
      tokenExpiresAt: map[WEARABLE_CONNECTIONS_TOKEN_EXPIRES_AT] != null
          ? DatabaseDateUtils.fromString(
              map[WEARABLE_CONNECTIONS_TOKEN_EXPIRES_AT] as String,
            )
          : null,
      userExternalId: map[WEARABLE_CONNECTIONS_USER_EXTERNAL_ID] as String?,
      grantedScopes: map[WEARABLE_CONNECTIONS_GRANTED_SCOPES] != null
          ? List<String>.from(
              json.decode(map[WEARABLE_CONNECTIONS_GRANTED_SCOPES] as String),
            )
          : null,
      isActive: (map[WEARABLE_CONNECTIONS_IS_ACTIVE] as int) == 1,
      connectedAt: DatabaseDateUtils.fromString(
        map[WEARABLE_CONNECTIONS_CONNECTED_AT] as String,
      ),
      lastSyncAt: map[WEARABLE_CONNECTIONS_LAST_SYNC_AT] != null
          ? DatabaseDateUtils.fromString(
              map[WEARABLE_CONNECTIONS_LAST_SYNC_AT] as String,
            )
          : null,
      createdAt: DatabaseDateUtils.fromString(
        map[WEARABLE_CONNECTIONS_CREATED_AT] as String,
      ),
      updatedAt: DatabaseDateUtils.fromString(
        map[WEARABLE_CONNECTIONS_UPDATED_AT] as String,
      ),
    );
  }

  /// Convert to database row
  ///
  /// Converts WearableCredentials to Map for SQLite insertion.
  /// Handles type conversions:
  /// - DateTime → TEXT (ISO 8601)
  /// - bool → INTEGER (1 or 0)
  /// - List<String> → TEXT (JSON array)
  Map<String, dynamic> toDatabase() {
    return {
      WEARABLE_CONNECTIONS_ID: id,
      WEARABLE_CONNECTIONS_USER_ID: userId,
      WEARABLE_CONNECTIONS_PROVIDER: provider.apiIdentifier,
      WEARABLE_CONNECTIONS_ACCESS_TOKEN: accessToken,
      WEARABLE_CONNECTIONS_REFRESH_TOKEN: refreshToken,
      WEARABLE_CONNECTIONS_TOKEN_EXPIRES_AT:
          tokenExpiresAt != null ? DatabaseDateUtils.toTimestamp(tokenExpiresAt!) : null,
      WEARABLE_CONNECTIONS_USER_EXTERNAL_ID: userExternalId,
      WEARABLE_CONNECTIONS_GRANTED_SCOPES:
          grantedScopes != null ? json.encode(grantedScopes) : null,
      WEARABLE_CONNECTIONS_IS_ACTIVE: isActive ? 1 : 0,
      WEARABLE_CONNECTIONS_CONNECTED_AT: DatabaseDateUtils.toTimestamp(connectedAt),
      WEARABLE_CONNECTIONS_LAST_SYNC_AT:
          lastSyncAt != null ? DatabaseDateUtils.toTimestamp(lastSyncAt!) : null,
      WEARABLE_CONNECTIONS_CREATED_AT: DatabaseDateUtils.toTimestamp(createdAt),
      WEARABLE_CONNECTIONS_UPDATED_AT: DatabaseDateUtils.toTimestamp(updatedAt),
    };
  }

  // ========================================================================
  // CopyWith
  // ========================================================================

  /// Create a copy with updated fields
  ///
  /// Immutable pattern - returns new instance instead of mutating.
  WearableCredentials copyWith({
    String? id,
    String? userId,
    WearableProvider? provider,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    String? userExternalId,
    List<String>? grantedScopes,
    bool? isActive,
    DateTime? connectedAt,
    DateTime? lastSyncAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WearableCredentials(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      userExternalId: userExternalId ?? this.userExternalId,
      grantedScopes: grantedScopes ?? this.grantedScopes,
      isActive: isActive ?? this.isActive,
      connectedAt: connectedAt ?? this.connectedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'WearableCredentials('
        'id: $id, '
        'userId: $userId, '
        'provider: ${provider.displayName}, '
        'isActive: $isActive, '
        'tokenExpired: ${isTokenExpired()}, '
        'connectedAt: $connectedAt, '
        'lastSyncAt: $lastSyncAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WearableCredentials &&
        other.id == id &&
        other.userId == userId &&
        other.provider == provider &&
        other.accessToken == accessToken &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      provider,
      accessToken,
      isActive,
    );
  }
}
