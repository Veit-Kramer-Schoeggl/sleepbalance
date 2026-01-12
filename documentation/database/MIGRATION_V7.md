# Migration V7: Wearables Integration Tables

**Version:** 7
**Status:** ✅ Active
**Purpose:** Adds wearable device connection and sync tracking

## Overview

Migration V7 introduces tables for Phase 7 Wearables Integration, enabling SleepBalance to connect with wearable devices (Fitbit, Apple Health, Google Fit, Garmin) and sync sleep data.

This migration adds:
1. **wearable_connections:** OAuth credentials and connection metadata
2. **wearable_sync_history:** Sync attempt logging for debugging and transparency

## Tables Created

### 1. `wearable_connections`

Stores OAuth credentials and connection status for wearable device providers.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID for connection |
| `user_id` | TEXT | NOT NULL, FK → users(id) | User who owns this connection |
| `provider` | TEXT | NOT NULL, CHECK: 'fitbit', 'apple_health', 'google_fit', 'garmin' | Wearable provider |
| `access_token` | TEXT | NOT NULL | OAuth access token (encrypted in production) |
| `refresh_token` | TEXT | | OAuth refresh token (encrypted in production) |
| `token_expires_at` | TEXT | | Access token expiration timestamp |
| `user_external_id` | TEXT | | Provider's user ID (for API calls) |
| `granted_scopes` | TEXT | | OAuth scopes granted (comma-separated) |
| `is_active` | INTEGER | NOT NULL DEFAULT 1 | Connection is currently active |
| `connected_at` | TEXT | NOT NULL | When connection was established |
| `last_sync_at` | TEXT | | When data was last synced from this provider |
| `created_at` | TEXT | NOT NULL | Record creation timestamp |
| `updated_at` | TEXT | NOT NULL | Last update timestamp |

**Constraints:**
- `UNIQUE(user_id, provider)` - One connection per provider per user
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`

**Indexes:**
- `idx_wearable_connections_user` on `(user_id)` - Fast user lookups
- `idx_wearable_connections_provider_active` on `(provider, is_active)` - Filter active connections by provider

**Use Cases:**

1. **OAuth Connection Flow:**
   ```dart
   // User connects Fitbit account
   INSERT INTO wearable_connections (
     id, user_id, provider,
     access_token, refresh_token, token_expires_at,
     user_external_id, granted_scopes,
     is_active, connected_at, created_at, updated_at
   ) VALUES (
     'uuid', 'user123', 'fitbit',
     'encrypted_access_token', 'encrypted_refresh_token', '2025-11-01 10:00:00',
     'fitbit_user_456', 'sleep,heartrate,activity',
     1, '2025-10-29 10:00:00', '2025-10-29 10:00:00', '2025-10-29 10:00:00'
   );
   ```

2. **Token Refresh:**
   ```sql
   -- Update tokens after refresh
   UPDATE wearable_connections
   SET access_token = 'new_encrypted_token',
       token_expires_at = '2025-11-02 10:00:00',
       updated_at = '2025-10-30 10:00:00'
   WHERE user_id = 'user123' AND provider = 'fitbit';
   ```

3. **Disconnect Provider:**
   ```sql
   -- User disconnects Fitbit
   UPDATE wearable_connections
   SET is_active = 0, updated_at = '2025-10-30 12:00:00'
   WHERE user_id = 'user123' AND provider = 'fitbit';

   -- Or completely remove
   DELETE FROM wearable_connections
   WHERE user_id = 'user123' AND provider = 'fitbit';
   ```

**Security Considerations:**
- **Production:** Tokens MUST be encrypted before storage (use flutter_secure_storage or similar)
- **Development:** Tokens stored as plaintext for debugging (acceptable for local-only dev databases)
- **Token Rotation:** Refresh tokens before expiration to maintain connection
- **Scope Management:** Only request minimum necessary OAuth scopes

---

### 2. `wearable_sync_history`

Logs all sync attempts for debugging, transparency, and analytics.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID for sync record |
| `user_id` | TEXT | NOT NULL, FK → users(id) | User whose data was synced |
| `provider` | TEXT | NOT NULL | Wearable provider that was synced |
| `sync_date_from` | TEXT | NOT NULL | Start of sync window (DATE) |
| `sync_date_to` | TEXT | NOT NULL | End of sync window (DATE) |
| `sync_started_at` | TEXT | NOT NULL | When sync began (TIMESTAMP) |
| `sync_completed_at` | TEXT | | When sync finished (TIMESTAMP, NULL if failed) |
| `status` | TEXT | NOT NULL, CHECK: 'success', 'failed', 'partial' | Sync outcome |
| `records_fetched` | INTEGER | NOT NULL DEFAULT 0 | How many records fetched from API |
| `records_inserted` | INTEGER | NOT NULL DEFAULT 0 | How many new records inserted |
| `records_updated` | INTEGER | NOT NULL DEFAULT 0 | How many existing records updated |
| `records_skipped` | INTEGER | NOT NULL DEFAULT 0 | How many records skipped (duplicates/invalid) |
| `error_code` | TEXT | | Error code if sync failed |
| `error_message` | TEXT | | Error message if sync failed |

**Constraints:**
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`

**Indexes:**
- `idx_sync_history_user_time` on `(user_id, sync_started_at)` - Fast user sync history queries
- `idx_sync_history_status` on `(status)` - Filter failed syncs for debugging

**Use Cases:**

1. **Log Successful Sync:**
   ```dart
   INSERT INTO wearable_sync_history (
     id, user_id, provider,
     sync_date_from, sync_date_to,
     sync_started_at, sync_completed_at,
     status, records_fetched, records_inserted, records_updated, records_skipped
   ) VALUES (
     'uuid', 'user123', 'fitbit',
     '2025-10-22', '2025-10-29',
     '2025-10-29 08:00:00', '2025-10-29 08:02:15',
     'success', 7, 5, 2, 0
   );
   ```

2. **Log Failed Sync:**
   ```dart
   INSERT INTO wearable_sync_history (
     id, user_id, provider,
     sync_date_from, sync_date_to,
     sync_started_at, sync_completed_at,
     status, records_fetched, records_inserted, records_updated, records_skipped,
     error_code, error_message
   ) VALUES (
     'uuid', 'user123', 'fitbit',
     '2025-10-22', '2025-10-29',
     '2025-10-29 08:00:00', '2025-10-29 08:00:05',
     'failed', 0, 0, 0, 0,
     'AUTH_ERROR', 'Access token expired'
   );
   ```

3. **Query Recent Sync Status:**
   ```sql
   -- Get last 10 syncs for user
   SELECT provider, sync_date_from, sync_date_to, status, sync_started_at
   FROM wearable_sync_history
   WHERE user_id = 'user123'
   ORDER BY sync_started_at DESC
   LIMIT 10;
   ```

4. **Debugging Failed Syncs:**
   ```sql
   -- Find all failed syncs in last week
   SELECT user_id, provider, error_code, error_message, sync_started_at
   FROM wearable_sync_history
   WHERE status = 'failed'
     AND sync_started_at >= date('now', '-7 days')
   ORDER BY sync_started_at DESC;
   ```

**Benefits:**
- **Transparency:** User can see when data was last synced
- **Debugging:** Developers can identify sync failures and patterns
- **Analytics:** Track sync success rates per provider
- **Conflict Resolution:** Understand data freshness for conflict handling

---

## Integration with Existing Schema

### Data Flow

```
1. User connects wearable
   ↓
2. OAuth flow → wearable_connections (save tokens)
   ↓
3. Background sync triggers
   ↓
4. Fetch data from wearable API
   ↓
5. Log sync attempt → wearable_sync_history
   ↓
6. Insert/update sleep_records
   ↓
7. Mark sync as complete → wearable_sync_history (update)
   ↓
8. Update last_sync_at → wearable_connections
```

### Example: Complete Sync Process

```dart
// 1. Check connection exists and is active
SELECT * FROM wearable_connections
WHERE user_id = 'user123' AND provider = 'fitbit' AND is_active = 1;

// 2. Create sync history record
INSERT INTO wearable_sync_history (...)
VALUES (..., status='in_progress', ...);

// 3. Fetch from Fitbit API (external)
// 4. Process each sleep record

// 5. Insert/update sleep records
INSERT OR REPLACE INTO sleep_records (...) VALUES (...);

// 6. Update sync history
UPDATE wearable_sync_history
SET sync_completed_at = NOW(),
    status = 'success',
    records_fetched = 7,
    records_inserted = 5,
    records_updated = 2
WHERE id = 'sync_uuid';

// 7. Update connection
UPDATE wearable_connections
SET last_sync_at = NOW()
WHERE user_id = 'user123' AND provider = 'fitbit';
```

---

## Migration Script Location

`lib/core/database/migrations/migration_v7.dart`

## Applied

This migration is applied during:
- Fresh database creation (version 7+)
- Upgrade from version 6 to version 7+ (Note: V6 is skipped, so effectively V5 → V7)

## Notes

- **Security:** Token encryption required for production deployment
- **OAuth Scopes:** Only request minimum necessary permissions
- **Sync Strategy:** Incremental sync (fetch only new data since `last_sync_at`)
- **Error Handling:** Log all failures for debugging and user transparency
- **Provider Extensibility:** Easy to add new providers (Oura, Whoop, etc.) via CHECK constraint update
- **Privacy:** Sync history helps users understand what data was collected and when
- **Future:** Could add `sync_trigger` column ('manual', 'automatic', 'background') to distinguish sync types
