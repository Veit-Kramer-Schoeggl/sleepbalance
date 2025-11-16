# Phase 2: Wearables Data Sync - Implementation Plan

**Date:** 2025-11-16
**Status:** Ready to Begin
**Prerequisites:** Phase 1 Complete (OAuth & Credential Storage)

---

## Executive Summary

Phase 2 builds on Phase 1's OAuth foundation to implement actual sleep data synchronization from Fitbit to the app's local database. Users will be able to manually trigger a sync, which fetches the last 7 days of sleep data, transforms it to our SleepRecord format, and saves it with intelligent conflict resolution.

**Goal:** Enable manual sync of Fitbit sleep data to populate Night Review screen.

**Estimated Time:** 14-20 hours (2-3 days focused work)

---

## Table of Contents

1. [Phase 1 Foundation Review](#1-phase-1-foundation-review)
2. [Phase 2 Scope & Deliverables](#2-phase-2-scope--deliverables)
3. [Architecture Overview](#3-architecture-overview)
4. [Fitbit API Integration](#4-fitbit-api-integration)
5. [Data Transformation](#5-data-transformation)
6. [Conflict Resolution Strategy](#6-conflict-resolution-strategy)
7. [Error Handling](#7-error-handling)
8. [Implementation Steps](#8-implementation-steps)
9. [Testing Strategy](#9-testing-strategy)
10. [Success Criteria](#10-success-criteria)

---

## 1. Phase 1 Foundation Review

### What We Built in Phase 1

**Completed Components:**
- ✅ OAuth 2.0 authentication flow (Fitbit)
- ✅ Credential storage (access token, refresh token, expiration)
- ✅ Database tables (`wearable_connections`, `wearable_sync_history`)
- ✅ Domain models (`WearableCredentials`, `WearableSyncRecord`)
- ✅ Repository pattern (auth repository + implementation)
- ✅ Test UI for connection management

**Available for Phase 2:**
- `WearableAuthRepository` - Get credentials, update tokens, log sync history
- `WearableConnectionViewModel` - Manage connection state
- `FitbitSecrets` - OAuth client credentials
- Database migration v7 - Tables ready for sync history

### Lessons Learned from Phase 1

**What Worked Well:**
1. **Clean Architecture** - Repository pattern with domain/data separation scales well
2. **Database Constants** - Using centralized constants (`database_constants.dart`) prevented typos
3. **Following Existing Patterns** - Mirroring `SleepRecord` patterns ensured consistency
4. **Incremental Testing** - Build and test after each major step caught issues early
5. **Provider Pattern** - Using `ChangeNotifierProxyProvider` for dependencies worked smoothly

**Principles to Continue:**
- Use database constants throughout
- Follow existing datasource/repository patterns
- Test compilation frequently with `flutter analyze`
- Document code thoroughly with inline comments
- Separate concerns: domain → data → presentation

---

## 2. Phase 2 Scope & Deliverables

### In Scope

**Core Functionality:**
- Manual sync trigger (user clicks "Sync Now" button)
- Fetch sleep data from Fitbit API (last 7 days)
- Transform Fitbit response to `SleepRecord` format
- Save to `sleep_records` table with conflict resolution
- Update last sync timestamp in `wearable_connections`
- Log sync attempts in `wearable_sync_history`
- Display sync status in UI (last sync time, success/error)

**Sleep Metrics to Sync:**
- Sleep date, start time, end time
- Total sleep time
- Deep sleep duration
- Light sleep duration
- REM sleep duration
- Awake duration

**Technical Requirements:**
- Automatic token refresh when expired
- Error handling (network, auth, API errors)
- Smart merge (preserve user's quality notes)
- Data validation before saving
- Structured error logging

### Out of Scope (Future Phases)

**Phase 3 Candidates:**
- ❌ Automatic background sync (scheduled sync)
- ❌ Heart rate data (requires separate API endpoint)
- ❌ HRV data (requires separate API endpoint)
- ❌ Breathing rate data
- ❌ Multiple sleep sessions per day (naps support)
- ❌ Full sleep history import (beyond 7 days)
- ❌ User prompt on conflict (just auto-merge for now)

**Future Features:**
- ❌ Apple Health integration
- ❌ Google Fit integration
- ❌ Data export functionality
- ❌ Sync scheduling/frequency settings

---

## 3. Architecture Overview

### Component Structure

```
lib/core/wearables/
├── domain/
│   ├── repositories/
│   │   ├── wearable_auth_repository.dart           ✅ EXISTS (Phase 1)
│   │   └── wearable_data_sync_repository.dart      ✨ NEW (Phase 2)
│   └── services/
│       └── sleep_data_mapper.dart                  ✨ NEW (Phase 2)
│
├── data/
│   ├── datasources/
│   │   ├── wearable_credentials_local_datasource.dart  ✅ EXISTS
│   │   └── fitbit_api_datasource.dart              ✨ NEW (Phase 2)
│   └── repositories/
│       ├── wearable_auth_repository_impl.dart      ✅ EXISTS
│       └── wearable_data_sync_repository_impl.dart ✨ NEW (Phase 2)
│
└── presentation/
    ├── viewmodels/
    │   ├── wearable_connection_viewmodel.dart      ✅ EXISTS
    │   └── wearable_sync_viewmodel.dart            ✨ NEW (Phase 2)
    ├── screens/
    │   └── wearable_connection_test_screen.dart    🔄 UPDATE (add sync button)
    └── widgets/
        └── sync_status_card.dart                   ✨ NEW (Phase 2)
```

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ USER ACTION: Clicks "Sync Now" button                      │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PRESENTATION LAYER                                          │
│ WearableSyncViewModel.syncFitbitData()                     │
│ - Set loading state                                         │
│ - Handle UI state (idle → syncing → success/error)         │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ DOMAIN LAYER                                                │
│ WearableDataSyncRepository.syncSleepData(userId, dates)    │
│ - Orchestrate the sync process                             │
│ - Call datasources and services                            │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ DATA LAYER - Step 1: Get Credentials                       │
│ WearableAuthRepository.getConnection(userId, fitbit)       │
│ - Retrieve stored OAuth tokens                             │
│ - Check token expiration                                   │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ DATA LAYER - Step 2: Token Refresh (if needed)             │
│ FitbitConnector.refreshToken()                             │
│ - Refresh if expired or expiring soon                      │
│ - Update database with new token                           │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ DATA LAYER - Step 3: Fetch Data                            │
│ FitbitApiDataSource.fetchSleepData(credentials, dates)     │
│ - Make HTTP GET request to Fitbit API                      │
│ - Return raw JSON response with summary data               │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ DOMAIN LAYER - Step 4: Transform Data                      │
│ SleepDataMapper.mapToSleepRecord(apiResponse, userId)      │
│ - Extract main sleep session (filter naps)                 │
│ - Map Fitbit fields → SleepRecord fields                   │
│ - Validate data ranges                                     │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ DATA LAYER - Step 5: Conflict Resolution                   │
│ SleepRecordRepository.getRecordForDate(userId, date)       │
│ - Check if record already exists                           │
│ - Determine merge strategy (see Section 6)                 │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ DATA LAYER - Step 6: Save to Database                      │
│ SleepRecordRepository.saveRecord(mergedRecord)             │
│ - Insert or replace sleep record                           │
│ - Handle database errors                                   │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ DATA LAYER - Step 7: Update Metadata                       │
│ WearableAuthRepository.updateLastSyncTime(userId, now)     │
│ - Update last_sync_at timestamp in wearable_connections    │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ DATA LAYER - Step 8: Log Sync History                      │
│ WearableAuthRepository.recordSyncAttempt(syncRecord)       │
│ - Insert sync record with stats (fetched, inserted, etc.)  │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ PRESENTATION LAYER: UI Update                               │
│ ViewModel.notifyListeners()                                │
│ - Update UI state (loading → success)                      │
│ - Show "Last synced: 2 minutes ago"                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Fitbit API Integration

### Understanding the Fitbit API

**Challenge:** The `fitbitter` package we use for OAuth returns granular 30-second interval data, but we need daily summaries.

**Solution:** Make raw HTTP requests directly to Fitbit's REST API to get summary data.

### API Endpoint

**Get Sleep Data for a Specific Date:**
```
GET https://api.fitbit.com/1.2/user/{user-id}/sleep/date/{date}.json
```

**Example:**
```
GET https://api.fitbit.com/1.2/user/ABC123/sleep/date/2025-11-15.json
Authorization: Bearer {access-token}
```

### API Response Structure

```json
{
  "sleep": [
    {
      "dateOfSleep": "2025-11-15",
      "duration": 25920000,
      "efficiency": 92,
      "startTime": "2025-11-15T23:15:30.000",
      "endTime": "2025-11-16T07:30:30.000",
      "isMainSleep": true,
      "logType": "auto_detected",
      "minutesAsleep": 420,
      "minutesAwake": 12,
      "minutesToFallAsleep": 8,
      "timeInBed": 495,

      "levels": {
        "summary": {
          "deep": { "count": 3, "minutes": 88 },
          "light": { "count": 12, "minutes": 240 },
          "rem": { "count": 5, "minutes": 92 },
          "wake": { "count": 15, "minutes": 12 }
        },
        "data": [ /* 30-second intervals - ignore for Phase 2 */ ]
      }
    }
  ],
  "summary": {
    "totalMinutesAsleep": 420,
    "totalSleepRecords": 1,
    "totalTimeInBed": 495
  }
}
```

### Implementation: FitbitApiDataSource

**File:** `lib/core/wearables/data/datasources/fitbit_api_datasource.dart`

**Key Methods:**

```dart
class FitbitApiDataSource {
  final Dio _dio;

  FitbitApiDataSource({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch sleep data for a specific date
  ///
  /// Returns raw API response as Map<String, dynamic>.
  /// Throws WearableException on errors.
  Future<Map<String, dynamic>> fetchSleepData({
    required String userId,
    required String accessToken,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final url = 'https://api.fitbit.com/1.2/user/$userId/sleep/date/$dateStr.json';

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Handle errors (see Section 7)
      throw _handleDioError(e);
    }
  }

  /// Fetch sleep data for a date range (for batch sync)
  Future<List<Map<String, dynamic>>> fetchSleepDataRange({
    required String userId,
    required String accessToken,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Fitbit API limitation: max 100 days per request
    final results = <Map<String, dynamic>>[];

    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      final data = await fetchSleepData(
        userId: userId,
        accessToken: accessToken,
        date: current,
      );
      results.add(data);
      current = current.add(const Duration(days: 1));
    }

    return results;
  }
}
```

**Dependencies:**
- `dio: ^5.0.0` (already in project for HTTP requests)
- `intl` package for date formatting (already in project)

### Token Refresh Integration

**Before every API call, ensure token is valid:**

```dart
Future<WearableCredentials> _ensureValidToken(
  WearableCredentials credentials,
) async {
  // Check if token expires within 5 minutes
  if (credentials.tokenExpiresAt != null) {
    final expiresIn = credentials.tokenExpiresAt!.difference(DateTime.now());
    if (expiresIn.inMinutes > 5) {
      return credentials; // Token still valid
    }
  }

  // Token expired or expiring soon - refresh
  final fitbitCreds = FitbitCredentials(
    userID: credentials.userExternalId!,
    fitbitAccessToken: credentials.accessToken,
    fitbitRefreshToken: credentials.refreshToken!,
  );

  final refreshed = await FitbitConnector.refreshToken(
    clientID: FitbitSecrets.clientId,
    clientSecret: FitbitSecrets.clientSecret,
    fitbitCredentials: fitbitCreds,
  );

  // Update database with new token
  await _authRepository.updateAccessToken(
    credentials.userId,
    WearableProvider.fitbit,
    refreshed.fitbitAccessToken,
    DateTime.now().add(const Duration(hours: 8)), // Fitbit tokens last 8 hours
  );

  // Return updated credentials for immediate use
  return credentials.copyWith(
    accessToken: refreshed.fitbitAccessToken,
    tokenExpiresAt: DateTime.now().add(const Duration(hours: 8)),
  );
}
```

---

## 5. Data Transformation

### Fitbit API → SleepRecord Mapping

**File:** `lib/core/wearables/domain/services/sleep_data_mapper.dart`

### Field Mapping Table

| Fitbit API Field | SleepRecord Field | Transformation | Notes |
|-----------------|-------------------|----------------|-------|
| `dateOfSleep` | `sleepDate` | Parse ISO date | Required |
| `startTime` | `bedTime`, `sleepStartTime` | Parse ISO timestamp | Use same value for both |
| `endTime` | `sleepEndTime`, `wakeTime` | Parse ISO timestamp | Use same value for both |
| `minutesAsleep` | `totalSleepTime` | Direct (minutes) | Required |
| `levels.summary.deep.minutes` | `deepSleepDuration` | Direct (minutes) | Nullable |
| `levels.summary.light.minutes` | `lightSleepDuration` | Direct (minutes) | Nullable |
| `levels.summary.rem.minutes` | `remSleepDuration` | Direct (minutes) | Nullable |
| `levels.summary.wake.minutes` | `awakeDuration` | Direct (minutes) | Nullable |
| N/A | `dataSource` | Hardcode `'fitbit'` | Required |
| N/A | `createdAt`, `updatedAt` | `DateTime.now()` | Required |

**Fields NOT Mapped in Phase 2:**
- Heart rate metrics (`avgHeartRate`, `minHeartRate`, `maxHeartRate`) - Requires separate API call
- HRV data (`avgHrv`, `avgHeartRateVariability`) - Requires separate API call
- Breathing rate (`avgBreathingRate`) - Requires separate API call
- User quality rating (`qualityRating`, `qualityNotes`) - Preserved from existing records

### Implementation

```dart
class SleepDataMapper {
  /// Transform Fitbit API response to SleepRecord
  ///
  /// Handles main sleep detection (filters out naps).
  /// Returns null if no valid sleep data found.
  SleepRecord? mapToSleepRecord({
    required Map<String, dynamic> apiResponse,
    required String userId,
  }) {
    // Extract sleep sessions from response
    final sleepSessions = apiResponse['sleep'] as List<dynamic>?;
    if (sleepSessions == null || sleepSessions.isEmpty) {
      return null; // No sleep data
    }

    // Find main sleep session (ignore naps)
    final mainSleep = _findMainSleep(sleepSessions);
    if (mainSleep == null) {
      return null; // No main sleep found
    }

    // Extract sleep levels summary
    final levels = mainSleep['levels'] as Map<String, dynamic>?;
    final summary = levels?['summary'] as Map<String, dynamic>?;

    // Parse timestamps
    final sleepDate = DateTime.parse(mainSleep['dateOfSleep'] as String);
    final startTime = DateTime.parse(mainSleep['startTime'] as String);
    final endTime = DateTime.parse(mainSleep['endTime'] as String);

    // Create SleepRecord
    return SleepRecord(
      id: UuidGenerator.generate(),
      userId: userId,
      sleepDate: sleepDate,
      bedTime: startTime,
      sleepStartTime: startTime,
      sleepEndTime: endTime,
      wakeTime: endTime,
      totalSleepTime: mainSleep['minutesAsleep'] as int?,
      deepSleepDuration: summary?['deep']?['minutes'] as int?,
      lightSleepDuration: summary?['light']?['minutes'] as int?,
      remSleepDuration: summary?['rem']?['minutes'] as int?,
      awakeDuration: summary?['wake']?['minutes'] as int?,
      // Heart rate fields - null for Phase 2
      avgHeartRate: null,
      minHeartRate: null,
      maxHeartRate: null,
      avgHrv: null,
      avgHeartRateVariability: null,
      avgBreathingRate: null,
      // User quality fields - preserved during merge
      qualityRating: null,
      qualityNotes: null,
      // Metadata
      dataSource: 'fitbit',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Find main sleep session (not a nap)
  Map<String, dynamic>? _findMainSleep(List<dynamic> sessions) {
    // Prefer session marked as main sleep
    for (var session in sessions) {
      if (session['isMainSleep'] == true) {
        return session as Map<String, dynamic>;
      }
    }

    // Fallback: longest sleep session
    if (sessions.isNotEmpty) {
      return sessions.reduce((a, b) {
        final aDuration = a['duration'] as int? ?? 0;
        final bDuration = b['duration'] as int? ?? 0;
        return aDuration > bDuration ? a : b;
      }) as Map<String, dynamic>;
    }

    return null;
  }

  /// Validate sleep record data
  ///
  /// Returns error message if invalid, null if valid.
  String? validateSleepRecord(SleepRecord record) {
    // Total sleep can't exceed 24 hours
    if (record.totalSleepTime != null && record.totalSleepTime! > 1440) {
      return 'Total sleep time exceeds 24 hours';
    }

    // Sleep phases can't exceed total sleep
    if (record.totalSleepTime != null) {
      final phasesTotal = (record.deepSleepDuration ?? 0) +
                          (record.lightSleepDuration ?? 0) +
                          (record.remSleepDuration ?? 0);
      if (phasesTotal > record.totalSleepTime!) {
        return 'Sleep phases total exceeds total sleep time';
      }
    }

    // Sleep end must be after sleep start
    if (record.sleepStartTime != null && record.sleepEndTime != null) {
      if (record.sleepEndTime!.isBefore(record.sleepStartTime!)) {
        return 'Sleep end time is before start time';
      }
    }

    return null; // Valid
  }
}
```

---

## 6. Conflict Resolution Strategy

### The Problem

**Database Constraint:** `UNIQUE(user_id, sleep_date)` - Only ONE sleep record per day per user.

**Existing Behavior:**
```dart
// Current SleepRecordLocalDataSource
await database.insert(
  TABLE_SLEEP_RECORDS,
  record.toDatabase(),
  conflictAlgorithm: ConflictAlgorithm.replace, // Overwrites completely!
);
```

### Scenarios to Handle

**Scenario 1: First Sync - No Existing Record**
- User syncs Fitbit for the first time
- No conflict - simply insert

**Scenario 2: Re-Sync - Existing Fitbit Record**
- User synced yesterday, syncs again today
- Fitbit data may have been updated (Fitbit can retroactively correct sleep stages)
- Strategy: Replace with new Fitbit data

**Scenario 3: Sync After Manual Entry**
- User manually entered sleep data (bedtime, quality notes)
- Later connects Fitbit and syncs
- Strategy: Use Fitbit's objective data + preserve user's subjective data

**Scenario 4: Re-Sync After Manual Edits**
- User synced Fitbit
- User adds quality notes ("Woke up refreshed")
- User re-syncs Fitbit (should preserve notes!)
- Strategy: Merge - Fitbit data + user notes

### Recommended Strategy: Smart Merge

**Decision Tree:**

```
Does record exist for this date?
├─ NO → Insert Fitbit data
└─ YES → Check dataSource
    ├─ dataSource == 'fitbit' → Replace with new Fitbit data
    ├─ dataSource == 'manual' → Merge (Fitbit metrics + manual notes)
    └─ dataSource == other → Replace with Fitbit data (default)
```

### Implementation

**Add to WearableDataSyncRepository:**

```dart
Future<void> _saveSleepRecordWithMerge({
  required SleepRecord fitbitRecord,
  required String userId,
}) async {
  // Check for existing record
  final existing = await _sleepRecordRepository.getRecordForDate(
    userId,
    fitbitRecord.sleepDate,
  );

  if (existing == null) {
    // No conflict - insert new record
    await _sleepRecordRepository.saveRecord(fitbitRecord);
    return;
  }

  // Record exists - determine merge strategy
  final recordToSave = _mergeRecords(existing, fitbitRecord);
  await _sleepRecordRepository.saveRecord(recordToSave);
}

SleepRecord _mergeRecords(SleepRecord existing, SleepRecord fitbit) {
  if (existing.dataSource == 'fitbit') {
    // Re-sync from Fitbit - use new data completely
    return fitbit;
  } else if (existing.dataSource == 'manual') {
    // Merge: Fitbit's objective data + user's subjective data
    return fitbit.copyWith(
      qualityRating: existing.qualityRating,
      qualityNotes: existing.qualityNotes,
    );
  } else {
    // Unknown source - default to Fitbit data
    return fitbit;
  }
}
```

**Result:** User's quality notes are never lost, even on re-sync!

### Alternative Strategies (Future Consideration)

**Option 2: User Prompt on Conflict**
- Show dialog: "Sleep data for Nov 15 already exists. Replace?"
- More control, but adds friction

**Option 3: Fitbit Always Wins**
- Simplest implementation
- Risk: User edits get lost

**Option 4: Manual Always Wins**
- Never overwrite manual entries
- Risk: Stale Fitbit data

**Conclusion:** Smart Merge (Option 1) provides best UX for Phase 2.

---

## 7. Error Handling

### Error Categories

**1. Network Errors**
- No internet connection
- Request timeout
- DNS failure

**2. Authentication Errors**
- Token expired (handle with auto-refresh)
- Token revoked (user disconnected account on Fitbit.com)
- Invalid credentials

**3. API Errors**
- Rate limit exceeded (150 req/hour per user)
- Server error (5xx)
- Bad request (4xx)

**4. Data Validation Errors**
- Malformed response
- Missing required fields
- Invalid values (negative sleep time, etc.)

### Custom Exception Class

**File:** `lib/core/wearables/domain/exceptions/wearable_exception.dart`

```dart
class WearableException implements Exception {
  final WearableErrorType type;
  final String userMessage;
  final String? technicalDetails;
  final bool canRetry;

  const WearableException({
    required this.type,
    required this.userMessage,
    this.technicalDetails,
    this.canRetry = false,
  });

  @override
  String toString() {
    if (technicalDetails != null) {
      return '$userMessage ($technicalDetails)';
    }
    return userMessage;
  }
}

enum WearableErrorType {
  networkError,
  authenticationError,
  rateLimitError,
  serverError,
  dataValidationError,
}
```

### Error Handling in FitbitApiDataSource

```dart
WearableException _handleDioError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return WearableException(
      type: WearableErrorType.networkError,
      userMessage: 'Network timeout. Please check your internet connection.',
      technicalDetails: e.message,
      canRetry: true,
    );
  }

  if (e.response?.statusCode == 401) {
    return WearableException(
      type: WearableErrorType.authenticationError,
      userMessage: 'Authentication failed. Please reconnect your Fitbit.',
      technicalDetails: 'Token expired or revoked',
      canRetry: false,
    );
  }

  if (e.response?.statusCode == 429) {
    return WearableException(
      type: WearableErrorType.rateLimitError,
      userMessage: 'Too many requests. Please try again in an hour.',
      technicalDetails: 'Rate limit: 150 requests/hour',
      canRetry: true,
    );
  }

  if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
    return WearableException(
      type: WearableErrorType.serverError,
      userMessage: 'Fitbit servers are currently unavailable. Try again later.',
      technicalDetails: 'HTTP ${e.response?.statusCode}',
      canRetry: true,
    );
  }

  return WearableException(
    type: WearableErrorType.networkError,
    userMessage: 'Failed to fetch sleep data',
    technicalDetails: e.message,
    canRetry: true,
  );
}
```

### Logging Strategy

**Use Flutter's debugPrint for development:**

```dart
try {
  final data = await _datasource.fetchSleepData(...);
} catch (e, stackTrace) {
  debugPrint('WearableDataSyncRepository: Error syncing sleep data');
  debugPrint('Error: $e');
  debugPrint('Stack trace: $stackTrace');

  // Record in sync history
  await _authRepository.recordSyncAttempt(WearableSyncRecord(
    // ... fields
    status: SyncStatus.failed,
    errorMessage: e.toString(),
  ));

  rethrow; // Let ViewModel handle UI updates
}
```

**Security Note:** NEVER log access tokens or refresh tokens!

---

## 8. Implementation Steps

### Step 1: Create Domain Interfaces (2 hours)

**File 1:** `lib/core/wearables/domain/repositories/wearable_data_sync_repository.dart`

```dart
abstract class WearableDataSyncRepository {
  /// Sync sleep data from Fitbit for a date range
  ///
  /// Fetches data, transforms it, handles conflicts, and saves to database.
  /// Updates last sync time and logs sync attempt.
  ///
  /// Throws WearableException on errors.
  Future<SyncResult> syncSleepData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get last successful sync date for a provider
  Future<DateTime?> getLastSyncDate(String userId, WearableProvider provider);
}

class SyncResult {
  final int recordsFetched;
  final int recordsInserted;
  final int recordsUpdated;
  final int recordsSkipped;

  const SyncResult({
    required this.recordsFetched,
    required this.recordsInserted,
    required this.recordsUpdated,
    required this.recordsSkipped,
  });
}
```

**File 2:** `lib/core/wearables/domain/exceptions/wearable_exception.dart`

(See Section 7 for full code)

---

### Step 2: Create Data Mapper (2 hours)

**File:** `lib/core/wearables/domain/services/sleep_data_mapper.dart`

(See Section 5 for full code)

**Tests to Write:**
- Map valid Fitbit response
- Handle missing optional fields
- Filter naps (only main sleep)
- Validate data ranges
- Handle malformed responses

---

### Step 3: Create Fitbit API Datasource (3 hours)

**File:** `lib/core/wearables/data/datasources/fitbit_api_datasource.dart`

(See Section 4 for full code)

**Key Features:**
- Fetch sleep data for single date
- Fetch sleep data for date range (batch)
- Handle Dio errors
- Return raw JSON responses

**Tests to Write:**
- Successful API call
- Handle 401 (auth error)
- Handle 429 (rate limit)
- Handle 5xx (server error)
- Handle network timeout

---

### Step 4: Create Repository Implementation (4 hours)

**File:** `lib/core/wearables/data/repositories/wearable_data_sync_repository_impl.dart`

```dart
class WearableDataSyncRepositoryImpl implements WearableDataSyncRepository {
  final WearableAuthRepository _authRepository;
  final SleepRecordRepository _sleepRecordRepository;
  final FitbitApiDataSource _apiDataSource;
  final SleepDataMapper _mapper;

  WearableDataSyncRepositoryImpl({
    required WearableAuthRepository authRepository,
    required SleepRecordRepository sleepRecordRepository,
    required FitbitApiDataSource apiDataSource,
    required SleepDataMapper mapper,
  })  : _authRepository = authRepository,
        _sleepRecordRepository = sleepRecordRepository,
        _apiDataSource = apiDataSource,
        _mapper = mapper;

  @override
  Future<SyncResult> syncSleepData({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final syncStartTime = DateTime.now();
    int fetched = 0;
    int inserted = 0;
    int updated = 0;
    int skipped = 0;

    try {
      // Step 1: Get credentials
      final credentials = await _authRepository.getConnection(
        userId,
        WearableProvider.fitbit,
      );

      if (credentials == null || !credentials.isActive) {
        throw WearableException(
          type: WearableErrorType.authenticationError,
          userMessage: 'Fitbit not connected. Please connect first.',
          canRetry: false,
        );
      }

      // Step 2: Ensure token is valid (refresh if needed)
      final validCredentials = await _ensureValidToken(credentials);

      // Step 3: Fetch data from API
      final responses = await _apiDataSource.fetchSleepDataRange(
        userId: validCredentials.userExternalId!,
        accessToken: validCredentials.accessToken,
        startDate: startDate,
        endDate: endDate,
      );

      fetched = responses.length;

      // Step 4: Transform and save each record
      for (var response in responses) {
        final fitbitRecord = _mapper.mapToSleepRecord(
          apiResponse: response,
          userId: userId,
        );

        if (fitbitRecord == null) {
          skipped++;
          continue; // No sleep data for this date
        }

        // Validate
        final validationError = _mapper.validateSleepRecord(fitbitRecord);
        if (validationError != null) {
          debugPrint('Skipping invalid record: $validationError');
          skipped++;
          continue;
        }

        // Step 5: Check for existing record and merge
        final existing = await _sleepRecordRepository.getRecordForDate(
          userId,
          fitbitRecord.sleepDate,
        );

        if (existing == null) {
          inserted++;
        } else {
          updated++;
        }

        final mergedRecord = _mergeRecords(existing, fitbitRecord);

        // Step 6: Save
        await _sleepRecordRepository.saveRecord(mergedRecord);
      }

      // Step 7: Update last sync time
      await _authRepository.updateLastSyncTime(
        userId,
        WearableProvider.fitbit,
        DateTime.now(),
      );

      // Step 8: Log success
      await _authRepository.recordSyncAttempt(WearableSyncRecord(
        id: UuidGenerator.generate(),
        userId: userId,
        provider: WearableProvider.fitbit,
        syncDateFrom: startDate,
        syncDateTo: endDate,
        syncStartedAt: syncStartTime,
        syncCompletedAt: DateTime.now(),
        status: SyncStatus.success,
        recordsFetched: fetched,
        recordsInserted: inserted,
        recordsUpdated: updated,
        recordsSkipped: skipped,
        errorCode: null,
        errorMessage: null,
      ));

      return SyncResult(
        recordsFetched: fetched,
        recordsInserted: inserted,
        recordsUpdated: updated,
        recordsSkipped: skipped,
      );
    } catch (e) {
      // Log failure
      await _authRepository.recordSyncAttempt(WearableSyncRecord(
        id: UuidGenerator.generate(),
        userId: userId,
        provider: WearableProvider.fitbit,
        syncDateFrom: startDate,
        syncDateTo: endDate,
        syncStartedAt: syncStartTime,
        syncCompletedAt: DateTime.now(),
        status: SyncStatus.failed,
        recordsFetched: fetched,
        recordsInserted: inserted,
        recordsUpdated: updated,
        recordsSkipped: skipped,
        errorCode: e is WearableException ? e.type.name : 'unknown',
        errorMessage: e.toString(),
      ));

      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastSyncDate(
    String userId,
    WearableProvider provider,
  ) async {
    final connection = await _authRepository.getConnection(userId, provider);
    return connection?.lastSyncAt;
  }

  // Private helper methods
  Future<WearableCredentials> _ensureValidToken(
    WearableCredentials credentials,
  ) async {
    // (See Section 4 for implementation)
  }

  SleepRecord _mergeRecords(SleepRecord? existing, SleepRecord fitbit) {
    // (See Section 6 for implementation)
  }
}
```

---

### Step 5: Create Sync ViewModel (2 hours)

**File:** `lib/core/wearables/presentation/viewmodels/wearable_sync_viewmodel.dart`

```dart
class WearableSyncViewModel extends ChangeNotifier {
  final WearableDataSyncRepository _syncRepository;
  final String userId;

  WearableSyncViewModel({
    required WearableDataSyncRepository syncRepository,
    required this.userId,
  }) : _syncRepository = syncRepository;

  // State
  SyncState _state = SyncState.idle;
  DateTime? _lastSyncDate;
  String? _errorMessage;
  SyncResult? _lastResult;

  // Getters
  SyncState get state => _state;
  DateTime? get lastSyncDate => _lastSyncDate;
  String? get errorMessage => _errorMessage;
  SyncResult? get lastResult => _lastResult;

  bool get isSyncing => _state == SyncState.syncing;
  bool get canRetry => _state == SyncState.error &&
                       (_errorMessage?.contains('retry') ?? false);

  /// Load last sync date on init
  Future<void> loadLastSyncDate() async {
    _lastSyncDate = await _syncRepository.getLastSyncDate(
      userId,
      WearableProvider.fitbit,
    );
    notifyListeners();
  }

  /// Sync last N days of sleep data
  Future<void> syncRecentData({int days = 7}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    await syncDateRange(startDate, endDate);
  }

  /// Sync specific date range
  Future<void> syncDateRange(DateTime startDate, DateTime endDate) async {
    if (_state == SyncState.syncing) {
      return; // Already syncing
    }

    _state = SyncState.syncing;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      final result = await _syncRepository.syncSleepData(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      _state = SyncState.success;
      _lastResult = result;
      _lastSyncDate = DateTime.now();
    } on WearableException catch (e) {
      _state = SyncState.error;
      _errorMessage = e.userMessage;
      debugPrint('WearableSyncViewModel: Sync failed - $e');
    } catch (e) {
      _state = SyncState.error;
      _errorMessage = 'Unexpected error occurred';
      debugPrint('WearableSyncViewModel: Unexpected error - $e');
    } finally {
      notifyListeners();
    }
  }

  /// Clear error state
  void clearError() {
    _state = SyncState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}

enum SyncState {
  idle,
  syncing,
  success,
  error,
}
```

---

### Step 6: Update UI (3 hours)

**Update:** `lib/core/wearables/presentation/screens/wearable_connection_test_screen.dart`

**Add after connection card:**

```dart
// Sync section (only show if connected)
if (isConnected) ...[
  const SizedBox(height: 24),
  const Divider(),
  const SizedBox(height: 16),

  Text(
    'Sync Sleep Data',
    style: Theme.of(context).textTheme.titleLarge,
  ),
  const SizedBox(height: 8),

  Consumer<WearableSyncViewModel>(
    builder: (context, syncViewModel, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last sync info
          if (syncViewModel.lastSyncDate != null)
            Text(
              'Last synced: ${_formatDateTime(syncViewModel.lastSyncDate!)}',
              style: TextStyle(color: Colors.grey[600]),
            ),

          const SizedBox(height: 12),

          // Sync button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: syncViewModel.isSyncing
                  ? null
                  : () => syncViewModel.syncRecentData(days: 7),
              icon: syncViewModel.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                syncViewModel.isSyncing
                    ? 'Syncing...'
                    : 'Sync Last 7 Days',
              ),
            ),
          ),

          // Success message
          if (syncViewModel.state == SyncState.success &&
              syncViewModel.lastResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Synced ${syncViewModel.lastResult!.recordsInserted} new records, '
                        'updated ${syncViewModel.lastResult!.recordsUpdated}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error message
          if (syncViewModel.state == SyncState.error)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        syncViewModel.errorMessage ?? 'Sync failed',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    if (syncViewModel.canRetry)
                      TextButton(
                        onPressed: () => syncViewModel.syncRecentData(days: 7),
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  ),
],
```

**Initialize sync ViewModel in initState:**

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Load connections
    final settingsViewModel = context.read<SettingsViewModel>();
    final userId = settingsViewModel.currentUser?.id;
    if (userId != null) {
      context.read<WearableConnectionViewModel>().loadConnections();
      context.read<WearableSyncViewModel>().loadLastSyncDate();
    }
  });
}
```

---

### Step 7: Register Providers (1 hour)

**Update:** `lib/main.dart`

**Add imports:**

```dart
import 'core/wearables/data/datasources/fitbit_api_datasource.dart';
import 'core/wearables/data/repositories/wearable_data_sync_repository_impl.dart';
import 'core/wearables/domain/repositories/wearable_data_sync_repository.dart';
import 'core/wearables/domain/services/sleep_data_mapper.dart';
import 'core/wearables/presentation/viewmodels/wearable_sync_viewmodel.dart';
```

**Add providers (after wearables data layer section):**

```dart
// Sleep Data Mapper (utility service)
Provider<SleepDataMapper>(
  create: (_) => SleepDataMapper(),
),

// Fitbit API DataSource
Provider<FitbitApiDataSource>(
  create: (_) => FitbitApiDataSource(),
),

// Wearable Data Sync Repository
Provider<WearableDataSyncRepository>(
  create: (context) => WearableDataSyncRepositoryImpl(
    authRepository: context.read<WearableAuthRepository>(),
    sleepRecordRepository: context.read<SleepRecordRepository>(),
    apiDataSource: context.read<FitbitApiDataSource>(),
    mapper: context.read<SleepDataMapper>(),
  ),
),
```

**Add ViewModel (in ViewModels section):**

```dart
// Wearable Sync ViewModel
ChangeNotifierProxyProvider<SettingsViewModel, WearableSyncViewModel>(
  create: (context) => WearableSyncViewModel(
    syncRepository: context.read<WearableDataSyncRepository>(),
    userId: context.read<SettingsViewModel>().currentUser?.id ?? '',
  ),
  update: (context, settingsViewModel, previous) =>
      previous ??
      WearableSyncViewModel(
        syncRepository: context.read<WearableDataSyncRepository>(),
        userId: settingsViewModel.currentUser?.id ?? '',
      ),
),
```

---

### Step 8: Testing (4 hours)

**Manual Testing Checklist:**

- [ ] **First Sync**
  - Connect Fitbit account
  - Click "Sync Last 7 Days"
  - Verify records appear in Night Review
  - Check database: `sleep_records` table populated
  - Check database: `wearable_sync_history` table has success record

- [ ] **Re-Sync Same Data**
  - Sync again immediately
  - Verify no duplicates in database
  - Verify `recordsUpdated` count is correct

- [ ] **Manual Entry Preservation**
  - Manually add quality notes to a synced record (via Night Review)
  - Re-sync Fitbit
  - Verify quality notes are preserved

- [ ] **Token Refresh**
  - Wait for token to expire (or manually expire in database)
  - Trigger sync
  - Verify token refreshes automatically
  - Verify sync succeeds with new token

- [ ] **Error Scenarios**
  - Disconnect internet → Sync → Verify error message
  - Revoke Fitbit access → Sync → Verify auth error
  - Reconnect internet → Retry → Verify success

- [ ] **Edge Cases**
  - Sync date with no sleep data → Verify skips gracefully
  - Multiple syncs in quick succession → Verify no conflicts

**Unit Tests to Write:**

- [ ] `SleepDataMapper` tests (map valid response, handle nulls, validate)
- [ ] `FitbitApiDataSource` error handling tests
- [ ] `WearableDataSyncRepositoryImpl` merge logic tests

---

## 9. Testing Strategy

### Unit Tests

**SleepDataMapper Tests:**
```dart
test('maps valid Fitbit response to SleepRecord', () {
  final response = {
    'sleep': [
      {
        'dateOfSleep': '2025-11-15',
        'startTime': '2025-11-15T23:00:00.000',
        'endTime': '2025-11-16T07:00:00.000',
        'minutesAsleep': 420,
        'isMainSleep': true,
        'levels': {
          'summary': {
            'deep': {'minutes': 90},
            'light': {'minutes': 240},
            'rem': {'minutes': 90},
          },
        },
      },
    ],
  };

  final record = mapper.mapToSleepRecord(
    apiResponse: response,
    userId: 'user-123',
  );

  expect(record, isNotNull);
  expect(record!.totalSleepTime, equals(420));
  expect(record.deepSleepDuration, equals(90));
  expect(record.dataSource, equals('fitbit'));
});
```

### Integration Tests

**Full Sync Flow:**
```dart
testWidgets('full sync flow updates UI correctly', (tester) async {
  // Setup mocks
  final mockSyncRepo = MockWearableDataSyncRepository();
  when(mockSyncRepo.syncSleepData(...)).thenAnswer((_) async => SyncResult(...));

  // Build widget
  await tester.pumpWidget(/* ... */);

  // Tap sync button
  await tester.tap(find.text('Sync Last 7 Days'));
  await tester.pump();

  // Verify loading state
  expect(find.text('Syncing...'), findsOneWidget);

  // Wait for completion
  await tester.pumpAndSettle();

  // Verify success state
  expect(find.text('Synced 7 new records'), findsOneWidget);
});
```

---

## 10. Success Criteria

### Functional Requirements

Phase 2 is complete when:

1. ✅ User can click "Sync Now" button in test screen
2. ✅ App fetches last 7 days of sleep data from Fitbit API
3. ✅ Sleep data transforms correctly to SleepRecord format
4. ✅ Records save to `sleep_records` table
5. ✅ Synced data appears in Night Review screen immediately
6. ✅ Re-syncing same dates updates data (doesn't duplicate)
7. ✅ User's quality notes are preserved on re-sync
8. ✅ Last sync timestamp displays correctly
9. ✅ Token expiration handled automatically (refresh)
10. ✅ Clear error messages for network/auth issues

### Technical Requirements

11. ✅ All code compiles without errors (`flutter analyze` clean)
12. ✅ No crashes during normal operation
13. ✅ Sync history logged in `wearable_sync_history` table
14. ✅ Error cases gracefully handled (no silent failures)
15. ✅ Code follows existing architectural patterns

### User Experience

16. ✅ Sync completes within 10 seconds for 7 days
17. ✅ Loading indicator shows during sync
18. ✅ Success message shows records synced count
19. ✅ Error messages are actionable (suggest retry)
20. ✅ No data loss (manual entries preserved)

---

## Appendix A: File Checklist

### Files to Create

- [ ] `lib/core/wearables/domain/repositories/wearable_data_sync_repository.dart`
- [ ] `lib/core/wearables/domain/services/sleep_data_mapper.dart`
- [ ] `lib/core/wearables/domain/exceptions/wearable_exception.dart`
- [ ] `lib/core/wearables/data/datasources/fitbit_api_datasource.dart`
- [ ] `lib/core/wearables/data/repositories/wearable_data_sync_repository_impl.dart`
- [ ] `lib/core/wearables/presentation/viewmodels/wearable_sync_viewmodel.dart`

### Files to Update

- [ ] `lib/core/wearables/presentation/screens/wearable_connection_test_screen.dart` - Add sync UI
- [ ] `lib/main.dart` - Register new providers

### Tests to Create

- [ ] `test/core/wearables/domain/services/sleep_data_mapper_test.dart`
- [ ] `test/core/wearables/data/datasources/fitbit_api_datasource_test.dart`
- [ ] `test/core/wearables/data/repositories/wearable_data_sync_repository_impl_test.dart`

---

## Appendix B: Dependencies

**Already in Project:**
- `dio` - HTTP client for API requests
- `intl` - Date formatting
- `provider` - State management
- `sqflite` - Local database
- `fitbitter` - Fitbit OAuth (for token refresh)

**No new dependencies required!**

---

## Appendix C: Future Enhancements (Phase 3+)

**Automatic Background Sync:**
- Use `workmanager` package for background tasks
- Sync once per day at user-specified time
- Handle device sleep/wake cycles

**Heart Rate Data:**
- Fetch from Fitbit Heart Rate API
- Map to `avgHeartRate`, `minHeartRate`, `maxHeartRate`
- Requires additional API call per date

**Multi-Provider Support:**
- Apple Health integration (iOS HealthKit)
- Google Fit integration (Android)
- Abstract data source interface

**Advanced Conflict Resolution:**
- User prompt dialog on conflicts
- "View Changes" diff view
- Undo last sync feature

---

**Ready to begin implementation? Start with Step 1!**
