# Wearables Integration Analysis & Implementation Plan

**Date:** 2025-11-16
**Author:** Claude (Analysis requested by Veit)

---

## 1. Current Implementation Analysis

### 1.1 What Currently Exists

#### **File: `lib/fitbit_secrets.dart`**
**Purpose:** Stores OAuth 2.0 credentials for Fitbit API authentication

**Content:**
- `clientId`: Fitbit app client ID (`23TPMQ`)
- `clientSecret`: Fitbit app client secret (API key)
- `redirectUri`: Custom URL scheme for OAuth callback (`sleepbalance://fitbit-auth`)
- `callbackScheme`: App-specific URL scheme (`sleepbalance`)

**What it does:**
- Provides credentials required for Fitbit OAuth 2.0 flow
- Enables the app to request user authorization to access their Fitbit data
- The redirect URI allows Fitbit to send the authorization code back to the app

**Security Note:** ⚠️ These credentials should **NOT** be committed to version control in production! They should be moved to environment variables or a secrets management system.

#### **File: `lib/fitbit_test.dart`**
**Purpose:** Proof-of-concept screen to test Fitbit OAuth authentication

**What it does:**
1. Displays a simple test screen with a "Mit Fitbit verbinden" button
2. When clicked, initiates OAuth flow using the `fitbitter` package
3. Opens Fitbit login page in browser/webview
4. User authorizes the app
5. Fitbit redirects back to app with authorization code
6. `FitbitConnector.authorize()` exchanges code for access token
7. Displays connection status (authorized, canceled, or error)

**What it returns:**
- `FitbitCredentials` object containing:
  - `userID`: Fitbit user ID
  - `accessToken`: For API requests
  - `refreshToken`: To get new access tokens when expired
  - Token expiration info

**Current Limitations:**
- Only tests authentication, doesn't fetch any data
- Credentials are not persisted (lost when app restarts)
- No token refresh logic
- Not integrated with app architecture (no repository/ViewModel pattern)
- Mixed language (German UI text in code)

---

## 2. Recommended File Structure

### 2.1 Proposed Location: `lib/core/wearables/`

**Rationale:**
- Wearables integration is **core infrastructure**, not a feature
- Multiple modules (Sleep tracking, Sport module, etc.) will use it
- Similar to how `lib/core/database/` provides shared database infrastructure

### 2.2 Complete Directory Structure

```
lib/core/wearables/
├── domain/
│   ├── models/
│   │   ├── sleep_data.dart              ✅ Already exists (good!)
│   │   ├── wearable_credentials.dart    📝 New: Generic credential model
│   │   ├── wearable_sync_status.dart    📝 New: Sync state tracking
│   │   └── heart_rate_data.dart         📝 New: HR data from wearables
│   │
│   ├── repositories/
│   │   ├── wearable_auth_repository.dart       📝 New: Auth interface
│   │   └── wearable_data_repository.dart       📝 New: Data fetch interface
│   │
│   └── enums/
│       └── wearable_provider.dart       📝 New: fitbit, apple_health, google_fit
│
├── data/
│   ├── datasources/
│   │   ├── fitbit_datasource.dart       📝 New: Fitbit API calls
│   │   ├── apple_health_datasource.dart 📝 Future
│   │   └── wearable_credentials_local_datasource.dart  📝 New: Store tokens
│   │
│   └── repositories/
│       ├── wearable_auth_repository_impl.dart    📝 New
│       └── wearable_data_repository_impl.dart    📝 New
│
├── presentation/
│   ├── viewmodels/
│   │   └── wearable_connection_viewmodel.dart   📝 New: Manage connections
│   │
│   └── screens/
│       └── wearable_settings_screen.dart        📝 New: Connect/disconnect UI
│
└── utils/
    ├── fitbit_secrets.dart              ✅ Move from lib/
    └── fitbit_oauth_helper.dart         📝 New: OAuth flow logic

```

### 2.3 File Placement Justification

| File | Current Location | Recommended Location | Reason |
|------|-----------------|---------------------|---------|
| `fitbit_secrets.dart` | `lib/` | `lib/core/wearables/utils/` | Wearable-specific configuration |
| `fitbit_test.dart` | `lib/` | **DELETE** (replace with proper screen) | Testing code shouldn't be in production |
| `sleep_data.dart` | `lib/core/wearables/domain/models/` | ✅ Already correct! | Good domain model placement |

---

## 3. What's Needed for Production-Ready Wearable Integration

### 3.1 Essential Components (Must-Have)

#### **1. Credential Persistence**
**Problem:** Currently, tokens are lost when app restarts
**Solution:** Store credentials securely in local database

**Implementation:**
```sql
-- New table needed
CREATE TABLE wearable_connections (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL,  -- 'fitbit', 'apple_health', 'google_fit'
  user_external_id TEXT,   -- Fitbit user ID
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  token_expires_at TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  connected_at TEXT NOT NULL,
  last_sync_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(user_id, provider)  -- One connection per provider per user
);

CREATE INDEX idx_wearable_connections_user ON wearable_connections(user_id);
CREATE INDEX idx_wearable_connections_provider ON wearable_connections(provider, is_active);
```

#### **2. Token Refresh Logic**
**Problem:** Access tokens expire (Fitbit: 8 hours), need automatic refresh
**Solution:** Background token refresh service

**Key Methods:**
```dart
class WearableAuthRepository {
  Future<WearableCredentials> refreshAccessToken(String refreshToken);
  Future<bool> isTokenValid(String userId, WearableProvider provider);
  Future<WearableCredentials?> getValidCredentials(String userId, WearableProvider provider);
}
```

#### **3. Data Sync Service**
**Problem:** Need to fetch sleep data from Fitbit API and store in `sleep_records` table
**Solution:** Scheduled background sync

**Required Methods:**
```dart
class WearableDataRepository {
  // Fetch sleep data for date range
  Future<List<SleepData>> fetchSleepData(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  // Fetch heart rate data
  Future<List<HeartRateData>> fetchHeartRateData(
    String userId,
    DateTime date,
  );

  // Sync all data (called by background job)
  Future<SyncResult> syncAllData(String userId);
}
```

#### **4. Error Handling & Retry Logic**
**Problem:** API calls can fail (network issues, rate limits, revoked access)
**Solution:** Robust error handling with exponential backoff

**Error Types to Handle:**
- Network errors (offline, timeout)
- Authentication errors (token expired, revoked)
- Rate limiting (Fitbit: 150 requests/hour per user)
- API errors (service down, malformed response)

#### **5. Data Mapping**
**Problem:** Fitbit API response ≠ our `sleep_records` table schema
**Solution:** Data transformation layer

**Example Mapping:**
```dart
class FitbitDataMapper {
  SleepRecord mapFitbitSleepToRecord(FitbitSleepResponse response, String userId) {
    return SleepRecord(
      id: UuidGenerator.generate(),
      userId: userId,
      sleepDate: response.dateOfSleep,
      bedTime: response.startTime,
      sleepStartTime: response.startTime.add(Duration(minutes: response.minutesToFallAsleep)),
      sleepEndTime: response.endTime,
      wakeTime: response.endTime,
      totalSleepTime: response.minutesAsleep,
      deepSleepDuration: response.levels.summary.deep.minutes,
      remSleepDuration: response.levels.summary.rem.minutes,
      lightSleepDuration: response.levels.summary.light.minutes,
      awakeDuration: response.levels.summary.awake.minutes,
      avgHeartRate: response.averageHeartRate?.toDouble(),
      dataSource: 'fitbit',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
```

### 3.2 Important Features (Should-Have)

#### **6. Multi-Provider Support**
**Why:** Users might have different devices (Fitbit, Apple Watch, Garmin, etc.)
**How:** Abstract interface + provider-specific implementations

```dart
abstract class WearableDataSource {
  Future<List<SleepData>> fetchSleepData(DateTime startDate, DateTime endDate);
  Future<void> authenticate();
  String get providerName;
}

// Implementations:
class FitbitDataSource implements WearableDataSource { ... }
class AppleHealthDataSource implements WearableDataSource { ... }
class GoogleFitDataSource implements WearableDataSource { ... }
```

#### **7. Sync Status Tracking**
**Why:** User needs to know if data is up-to-date
**How:** Store last successful sync timestamp

```dart
class WearableSyncStatus {
  final String userId;
  final WearableProvider provider;
  final DateTime? lastSuccessfulSync;
  final DateTime? lastAttemptedSync;
  final SyncState state;  // idle, syncing, error
  final String? errorMessage;
}
```

#### **8. Conflict Resolution**
**Problem:** User might edit sleep data manually, then sync from Fitbit
**Solution:** Clear conflict resolution strategy

**Options:**
1. **Wearable data always wins** (simpler, recommended)
2. **Manual edits always win** (preserve user input)
3. **Ask user** (best UX, more complex)

**Recommendation:** Start with option 1, add option 3 later

#### **9. Data Validation**
**Why:** Fitbit might return corrupted/unrealistic data
**Solution:** Validation layer before database insertion

```dart
class SleepDataValidator {
  String? validate(SleepRecord record) {
    // Total sleep can't exceed 24 hours
    if (record.totalSleepTime != null && record.totalSleepTime! > 1440) {
      return 'Invalid total sleep time: ${record.totalSleepTime} minutes';
    }

    // Deep + REM + Light should roughly equal total
    final sumPhases = (record.deepSleepDuration ?? 0) +
                      (record.remSleepDuration ?? 0) +
                      (record.lightSleepDuration ?? 0);
    if ((record.totalSleepTime ?? 0) > 0 && sumPhases > record.totalSleepTime! * 1.1) {
      return 'Sleep phases exceed total sleep time';
    }

    // Heart rate ranges
    if (record.avgHeartRate != null && (record.avgHeartRate! < 30 || record.avgHeartRate! > 200)) {
      return 'Invalid average heart rate: ${record.avgHeartRate}';
    }

    return null; // Valid
  }
}
```

#### **10. User Permissions Management**
**Why:** Users should be able to see/revoke permissions
**Solution:** Settings screen with connection status

**UI Components:**
- List of connected wearables
- "Connect new device" button
- Last sync timestamp
- Manual sync trigger
- Disconnect/revoke access button

### 3.3 Advanced Features (Nice-to-Have)

#### **11. Background Sync**
**Why:** Auto-sync data every night without user interaction
**How:** Platform-specific background tasks

**Android:** WorkManager
**iOS:** Background App Refresh

```dart
class WearableSyncWorker {
  static void registerDailySync() {
    // Schedule daily sync at 8 AM
    Workmanager().registerPeriodicTask(
      "wearable-sync",
      "wearableSyncTask",
      frequency: Duration(hours: 24),
      initialDelay: _getNextSyncTime(),
    );
  }
}
```

#### **12. Selective Data Sync**
**Why:** User might only want sleep data, not activity/nutrition
**How:** Granular permission checkboxes

**Data Types:**
- Sleep stages
- Heart rate
- Activity/steps
- Nutrition (future)
- Weight (future)

#### **13. Data Export**
**Why:** User wants their raw Fitbit data
**How:** Export to JSON/CSV

#### **14. Sync History**
**Why:** Debugging sync issues
**How:** Log table with sync attempts

```sql
CREATE TABLE wearable_sync_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  sync_started_at TEXT NOT NULL,
  sync_completed_at TEXT,
  status TEXT NOT NULL,  -- 'success', 'failed', 'partial'
  records_fetched INTEGER,
  records_inserted INTEGER,
  error_message TEXT,

  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 4. Database Changes Required

### 4.1 New Tables Needed

#### **Table 1: `wearable_connections`** (High Priority)
Stores OAuth credentials and connection status

```sql
CREATE TABLE wearable_connections (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL CHECK(provider IN ('fitbit', 'apple_health', 'google_fit', 'garmin')),

  -- OAuth tokens
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  token_expires_at TEXT,

  -- Provider-specific IDs
  user_external_id TEXT,  -- Fitbit user ID, etc.

  -- Scopes/permissions granted
  granted_scopes TEXT,    -- JSON array: ["sleep", "heartrate", "activity"]

  -- Connection metadata
  is_active INTEGER NOT NULL DEFAULT 1,
  connected_at TEXT NOT NULL,
  last_sync_at TEXT,

  -- Standard fields
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(user_id, provider)
);

CREATE INDEX idx_wearable_connections_user ON wearable_connections(user_id);
CREATE INDEX idx_wearable_connections_active ON wearable_connections(provider, is_active);
```

**Why needed:**
- Store access/refresh tokens securely
- Track which users have which wearables connected
- Enable token refresh without re-authentication
- Support multiple wearable providers per user (future)

---

#### **Table 2: `wearable_sync_history`** (Medium Priority)
Logs all sync attempts for debugging and user transparency

```sql
CREATE TABLE wearable_sync_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL,

  -- Sync window
  sync_date_from TEXT NOT NULL,  -- Start of requested date range
  sync_date_to TEXT NOT NULL,    -- End of requested date range

  -- Timing
  sync_started_at TEXT NOT NULL,
  sync_completed_at TEXT,

  -- Results
  status TEXT NOT NULL CHECK(status IN ('success', 'failed', 'partial')),
  records_fetched INTEGER NOT NULL DEFAULT 0,
  records_inserted INTEGER NOT NULL DEFAULT 0,
  records_updated INTEGER NOT NULL DEFAULT 0,
  records_skipped INTEGER NOT NULL DEFAULT 0,

  -- Error info
  error_code TEXT,
  error_message TEXT,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_sync_history_user ON wearable_sync_history(user_id, sync_started_at);
CREATE INDEX idx_sync_history_status ON wearable_sync_history(status);
```

**Why needed:**
- Debugging sync failures
- Show user "Last synced 2 hours ago" in UI
- Detect patterns (e.g., sync always fails at night → token expiration)
- Analytics (how many users actively sync?)

---

### 4.2 Modifications to Existing Tables

#### **`sleep_records` Table** - No changes needed! ✅

The existing `sleep_records` table already has:
- ✅ `data_source` field (can store 'fitbit', 'apple_health', etc.)
- ✅ All necessary sleep phase fields (deep, REM, light, awake)
- ✅ Biometric fields (heart rate, HRV, breathing rate)
- ✅ Timestamp fields for sync tracking

**Perfect fit!** No schema changes required.

**Only consideration:** Add validation to prevent duplicate imports
- Current schema has `UNIQUE(user_id, sleep_date)` → Good!
- Sync logic should use `INSERT OR REPLACE` or check existence first

---

#### **`users` Table** - Consider adding wearable preferences (Optional)

**Potential additions:**
```sql
ALTER TABLE users ADD COLUMN auto_sync_enabled INTEGER DEFAULT 1;
ALTER TABLE users ADD COLUMN sync_time_preference TEXT DEFAULT '08:00';  -- HH:mm
ALTER TABLE users ADD COLUMN data_sharing_consent INTEGER DEFAULT 0;
```

**Why:**
- `auto_sync_enabled`: Let users disable background sync
- `sync_time_preference`: When to run background sync (user's convenience)
- `data_sharing_consent`: Legal requirement in some regions (GDPR)

**Priority:** Low (can add later as user preferences feature)

---

### 4.3 Migration Plan

**Recommended Migration: v7**

```dart
// lib/core/database/migrations/migration_v7.dart

const String MIGRATION_V7 = '''
-- ============================================================================
-- Wearables Integration Tables
-- ============================================================================

-- Store OAuth credentials and connection status
CREATE TABLE IF NOT EXISTS wearable_connections (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL CHECK(provider IN ('fitbit', 'apple_health', 'google_fit', 'garmin')),
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  token_expires_at TEXT,
  user_external_id TEXT,
  granted_scopes TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  connected_at TEXT NOT NULL,
  last_sync_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(user_id, provider)
);

CREATE INDEX IF NOT EXISTS idx_wearable_connections_user
  ON wearable_connections(user_id);

CREATE INDEX IF NOT EXISTS idx_wearable_connections_active
  ON wearable_connections(provider, is_active);

-- Track sync history for debugging and transparency
CREATE TABLE IF NOT EXISTS wearable_sync_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  sync_date_from TEXT NOT NULL,
  sync_date_to TEXT NOT NULL,
  sync_started_at TEXT NOT NULL,
  sync_completed_at TEXT,
  status TEXT NOT NULL CHECK(status IN ('success', 'failed', 'partial')),
  records_fetched INTEGER NOT NULL DEFAULT 0,
  records_inserted INTEGER NOT NULL DEFAULT 0,
  records_updated INTEGER NOT NULL DEFAULT 0,
  records_skipped INTEGER NOT NULL DEFAULT 0,
  error_code TEXT,
  error_message TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sync_history_user
  ON wearable_sync_history(user_id, sync_started_at);

CREATE INDEX IF NOT EXISTS idx_sync_history_status
  ON wearable_sync_history(status);
''';
```

**Steps:**
1. Create migration file: `migration_v7.dart`
2. Update `database_helper.dart` to include migration v7
3. Increment database version to 7
4. Test migration on fresh install + existing database

---

## 5. Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
**Goal:** Basic Fitbit authentication and credential storage

- [ ] Create directory structure `lib/core/wearables/`
- [ ] Move `fitbit_secrets.dart` to `lib/core/wearables/utils/`
- [ ] Implement database migration v7 (new tables)
- [ ] Create domain models:
  - [ ] `WearableCredentials`
  - [ ] `WearableProvider` enum
  - [ ] `WearableSyncStatus`
- [ ] Create repository interfaces:
  - [ ] `WearableAuthRepository`
- [ ] Implement `WearableAuthRepositoryImpl`
- [ ] Create `WearableConnectionViewModel`
- [ ] Build settings screen for connecting Fitbit
- [ ] Test: Connect → store credentials → restart app → still connected

**Deliverable:** User can connect Fitbit and credentials persist

---

### Phase 2: Data Sync (Week 3-4)
**Goal:** Fetch sleep data from Fitbit and store in database

- [ ] Create `FitbitDataSource` with API methods:
  - [ ] `fetchSleepData(startDate, endDate)`
  - [ ] `fetchHeartRateData(date)`
- [ ] Create `FitbitDataMapper` to transform API response → `SleepRecord`
- [ ] Implement `WearableDataRepository`
- [ ] Create `WearableSyncViewModel`
- [ ] Add manual sync button to settings screen
- [ ] Implement sync logic:
  - [ ] Check token validity
  - [ ] Refresh if needed
  - [ ] Fetch data from API
  - [ ] Validate data
  - [ ] Insert into `sleep_records` table
  - [ ] Log to `wearable_sync_history`
- [ ] Test: Manual sync → data appears in Night Review

**Deliverable:** User can manually sync Fitbit sleep data

---

### Phase 3: Automation (Week 5)
**Goal:** Background sync without user interaction

- [ ] Implement token refresh service
- [ ] Add background sync worker (WorkManager on Android)
- [ ] Schedule daily sync
- [ ] Handle edge cases:
  - [ ] No internet connection
  - [ ] Token expired/revoked
  - [ ] API rate limit
  - [ ] Duplicate data
- [ ] Add sync status indicator in UI
- [ ] Test: Sleep with Fitbit → wake up → open app → data already synced

**Deliverable:** Fully automated Fitbit sync

---

### Phase 4: Polish (Week 6)
**Goal:** Production-ready UX

- [ ] Error handling and user-friendly messages
- [ ] Retry logic with exponential backoff
- [ ] Disconnect/revoke access feature
- [ ] Sync history view in settings
- [ ] Data validation and sanitization
- [ ] Loading states and progress indicators
- [ ] Analytics/logging for debugging
- [ ] Documentation and code comments

**Deliverable:** Stable, production-ready wearable integration

---

### Phase 5: Multi-Provider (Future)
**Goal:** Support Apple Health, Google Fit, etc.

- [ ] Abstract common functionality
- [ ] Implement `AppleHealthDataSource`
- [ ] Implement `GoogleFitDataSource`
- [ ] Provider selection UI
- [ ] Multi-provider sync orchestration

**Deliverable:** Support for multiple wearable platforms

---

## 6. Technical Recommendations

### 6.1 Security Best Practices

1. **Never commit `fitbit_secrets.dart` to git**
   ```gitignore
   lib/core/wearables/utils/fitbit_secrets.dart
   ```

2. **Use environment variables in production**
   ```dart
   class FitbitSecrets {
     static final clientId = Platform.environment['FITBIT_CLIENT_ID'] ?? 'dev-default';
     static final clientSecret = Platform.environment['FITBIT_CLIENT_SECRET'] ?? 'dev-default';
   }
   ```

3. **Encrypt tokens at rest** (use `flutter_secure_storage`)
   ```dart
   final storage = FlutterSecureStorage();
   await storage.write(key: 'fitbit_access_token', value: token);
   ```

4. **Use HTTPS only** for API requests (Fitbit already requires this)

5. **Implement certificate pinning** for production (prevent MITM attacks)

---

### 6.2 Error Handling Strategy

**Error Categories:**

| Error Type | User Message | Action |
|------------|-------------|--------|
| Network timeout | "Couldn't connect to Fitbit. Check your internet connection." | Retry button |
| Token expired | "Fitbit connection expired. Please reconnect." | Reconnect button |
| Token revoked | "Fitbit access was revoked. Please reconnect." | Reconnect button |
| Rate limit | "Too many requests. Sync will retry automatically in 1 hour." | Auto-retry later |
| Invalid data | "Some sleep data couldn't be imported." | Log for debugging |
| Server error | "Fitbit is temporarily unavailable. We'll retry automatically." | Auto-retry |

**Implementation:**
```dart
class WearableException implements Exception {
  final WearableErrorType type;
  final String message;
  final String? technicalDetails;
  final bool isRetryable;

  const WearableException({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.isRetryable = false,
  });
}

enum WearableErrorType {
  networkError,
  authenticationError,
  rateLimitError,
  invalidDataError,
  serverError,
}
```

---

### 6.3 Performance Considerations

1. **Batch API requests**
   - Fitbit allows fetching up to 100 days at once
   - Minimize API calls to avoid rate limits

2. **Incremental sync**
   - Only fetch data since last successful sync
   - Don't re-fetch entire history every time

3. **Database transactions**
   - Insert multiple sleep records in single transaction
   - Faster and ensures data consistency

4. **Caching**
   - Cache Fitbit API responses for 5 minutes
   - Prevent duplicate API calls during same session

---

### 6.4 Testing Strategy

**Unit Tests:**
- [ ] `FitbitDataMapper` transformation logic
- [ ] `SleepDataValidator` validation rules
- [ ] Token expiration detection
- [ ] Error handling branches

**Integration Tests:**
- [ ] OAuth flow (mock Fitbit API)
- [ ] Data sync (mock API responses)
- [ ] Database insertion
- [ ] Token refresh logic

**Manual Tests:**
- [ ] Real Fitbit account connection
- [ ] Sync with actual sleep data
- [ ] Token expiration scenario
- [ ] Network offline scenario
- [ ] App reinstall (credentials persist?)

---

## 7. Summary & Next Steps

### What You Have Now:
- ✅ Basic OAuth authentication test code
- ✅ Fitbit API credentials
- ✅ `SleepData` domain model (partial)
- ✅ Database schema ready for wearable data

### What You Need:
1. **Credential persistence** (database table + repository)
2. **Data sync service** (fetch from Fitbit → store in DB)
3. **Token management** (refresh, validation)
4. **Error handling** (graceful failures)
5. **User interface** (settings screen for connections)
6. **Background sync** (automated daily sync)

### Recommended First Steps:
1. **Create directory structure** (`lib/core/wearables/`)
2. **Implement database migration v7** (add wearable tables)
3. **Build credential storage** (repository + datasource)
4. **Create settings UI** (connect/disconnect Fitbit)
5. **Implement manual sync** (button → fetch data → show in app)

### Estimated Timeline:
- **MVP (manual sync):** 2-3 weeks
- **Production-ready (auto-sync):** 4-6 weeks
- **Multi-provider support:** +2-3 weeks

---

## 8. Questions & Decisions Needed

**Questions for you to answer:**

1. **Provider Priority:** Start with Fitbit only, or design for multi-provider from the start?
   - **Recommendation:** Fitbit first, abstract interfaces from the start

2. **Sync Frequency:** How often should we auto-sync?
   - **Recommendation:** Once daily at 8 AM (user configurable later)

3. **Conflict Resolution:** Wearable data always wins, or ask user?
   - **Recommendation:** Wearable wins (simpler), add user choice in v2

4. **Data Retention:** Import all historical Fitbit data, or just last 30 days?
   - **Recommendation:** Last 90 days initially, "import more" button for full history

5. **Permissions:** Request all Fitbit scopes (sleep, activity, heart rate), or selective?
   - **Recommendation:** Sleep + heart rate only to start (smaller scope = better UX)

6. **Offline Mode:** What happens when user has no internet for a week?
   - **Recommendation:** Queue sync, retry when online, show last sync time

---

**This report provides a complete blueprint for wearable integration. Ready to start implementation? Let me know which phase to begin with!**