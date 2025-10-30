# PHASE 3: Night Review Refactoring

## Overview
Refactor Night Review screen to use MVVM + Provider pattern, integrate with sleep_records database table, add subjective quality rating, and implement baseline comparisons.

## Prerequisites
- **Phase 1 completed:** Database infrastructure with constants
- **Phase 2 completed:** MVVM pattern validated with Action Center
- Understanding of repository pattern and ViewModel
- **IMPORTANT:** Review Action Center implementation as reference

## Goals
- Create database migrations FIRST (migration_v3.dart)
- Create SleepRecord and SleepBaseline models with proper date handling
- Implement repository pattern following Action Center example
- Create NightReviewViewModel with comprehensive error handling
- Add quality rating widget (3-point scale: bad/average/good)
- Refactor NightScreen to StatelessWidget consuming ViewModel
- Display "today vs your average" comparisons
- **Expected outcome:** 0 analyzer warnings, all tests passing

---

## Step 3.0: Create Database Migration (DO THIS FIRST!)

**File:** `lib/core/database/migrations/migration_v3.dart`
**Purpose:** Define sleep_records and user_sleep_baselines tables
**Dependencies:** None

**CRITICAL:** Create this migration BEFORE creating models! This establishes the database schema.

**Add to file header:**
```dart
// ignore_for_file: constant_identifier_names
/// Migration V3: Sleep records and baselines tables
///
/// Creates tables for storing nightly sleep data from wearables
/// and computed personal baseline averages.
library;
```

**Class: MigrationV3**

**Static constant: MIGRATION_V3**
- SQL string creating `sleep_records` table with all fields
- SQL string creating `user_sleep_baselines` table
- Add indexes for frequently queried columns: (user_id, sleep_date)

**Next Steps:**
1. Update `lib/shared/constants/database_constants.dart`:
   - Add `TABLE_SLEEP_RECORDS = 'sleep_records'`
   - Add `TABLE_USER_SLEEP_BASELINES = 'user_sleep_baselines'`
   - Add all column name constants
2. Update `lib/core/database/database_helper.dart`:
   - Increment `DATABASE_VERSION` to 3
   - Add MIGRATION_V3 to `_onCreate` method
   - Add version 3 case to `_onUpgrade` switch statement
3. **Uninstall app before testing** to force database recreation (existing V2 won't auto-migrate)

**Why:** Following Phase 1/2 pattern - migrations first, then models, prevents SQL string hardcoding

---

## Step 3.1: Create Domain Model - SleepRecord

**File:** `lib/features/night_review/domain/models/sleep_record.dart`
**Purpose:** Model for nightly sleep data from wearables (aggregated metrics)
**Dependencies:** `json_annotation`

**CRITICAL - Two Conversion Methods Required:**
- **fromJson/toJson:** For API communication (if future backend integration)
- **fromDatabase/toDatabase:** For SQLite operations (must handle DateTime conversion)

**Class: SleepRecord**

**Fields:**
- `String id` - UUID primary key
- `String userId` - Foreign key
- `DateTime sleepDate` - The night (e.g., 2025-10-29)
- `DateTime? bedTime` - When user went to bed (nullable)
- `DateTime? sleepStartTime` - Sleep onset (nullable)
- `DateTime? sleepEndTime` - Wake up time (nullable)
- `DateTime? wakeTime` - Out of bed time (nullable)
- `int? totalSleepTime` - Minutes (nullable)
- `int? deepSleepDuration` - Minutes (nullable)
- `int? remSleepDuration` - Minutes (nullable)
- `int? lightSleepDuration` - Minutes (nullable)
- `int? awakeDuration` - Minutes awake during night (nullable)
- `double? avgHeartRate` - BPM (nullable)
- `double? minHeartRate` - BPM (nullable)
- `double? maxHeartRate` - BPM (nullable)
- `double? avgHrv` - RMSSD in milliseconds (nullable)
- `double? avgBreathingRate` - Breaths per minute (nullable)
- `String? qualityRating` - 'bad', 'average', 'good', or null
- `String? qualityNotes` - User notes (nullable)
- `String dataSource` - 'apple_health', 'google_fit', 'manual'
- `DateTime createdAt`
- `DateTime updatedAt`

**Methods:**
- `SleepRecord({required fields})` - Constructor
- `factory SleepRecord.fromJson(Map<String, dynamic> json)` - Deserialize (API)
- `Map<String, dynamic> toJson()` - Serialize (API)
- **`factory SleepRecord.fromDatabase(Map<String, dynamic> map)`** - Deserialize from SQLite
  - Use `DatabaseDateUtils.parseDateTime()` for all DateTime fields
  - Use `DatabaseDateUtils.parseDateTimeNullable()` for nullable DateTime fields
- **`Map<String, dynamic> toDatabase()`** - Serialize to SQLite
  - Use `DatabaseDateUtils.toIso8601String()` for all DateTime fields
  - Use `DatabaseDateUtils.toIso8601StringNullable()` for nullable DateTime fields
- `SleepRecord copyWith({...})` - Immutable update
- `int? get sleepEfficiency` - Calculated: (totalSleepTime / timeInBed) * 100
- `Duration? get timeInBed` - bedTime to wakeTime duration

**Annotations:**
- `@JsonSerializable()`

**After Creating Model:**
1. Run `dart run build_runner build` to generate `sleep_record.g.dart`
2. Verify no analyzer warnings
3. Reference Action Center's `DailyAction` model for pattern

**Why:** Replaces unused existing `SleepData` model, aligns with database schema. Proper DateTime handling critical for SQLite storage (ISO 8601 TEXT format).

---

## Step 3.2: Create Domain Model - SleepBaseline

**File:** `lib/features/night_review/domain/models/sleep_baseline.dart`
**Purpose:** Store computed personal averages for comparison
**Dependencies:** `json_annotation`

**Class: SleepBaseline**

**Fields:**
- `String id` - UUID
- `String userId` - Foreign key
- `String baselineType` - '7_day', '30_day', 'all_time'
- `String metricName` - 'avg_deep_sleep', 'avg_total_sleep', etc.
- `double metricValue` - The calculated average
- `DateTime dataRangeStart` - Start of calculation period
- `DateTime dataRangeEnd` - End of calculation period
- `DateTime computedAt` - When baseline was calculated

**Methods:**
- Constructor, fromJson, toJson, copyWith
- **`factory SleepBaseline.fromDatabase(Map<String, dynamic> map)`** - Use DatabaseDateUtils
- **`Map<String, dynamic> toDatabase()`** - Use DatabaseDateUtils

**After Creating Model:**
1. Run `dart run build_runner build` to generate `sleep_baseline.g.dart`
2. Verify no analyzer warnings

**Why:** Enables "You slept better than your 7-day average" comparisons

---

## Step 3.3: Create Domain Model - SleepComparison

**File:** `lib/features/night_review/domain/models/sleep_comparison.dart`
**Purpose:** DTO for displaying "today vs average" comparison
**Dependencies:** `sleep_record`, `sleep_baseline`

**Class: SleepComparison**

**Fields:**
- `SleepRecord todayRecord` - Tonight's sleep
- `Map<String, double> baselines` - Key = metric name, Value = baseline value
- `Map<String, double> differences` - Key = metric name, Value = difference from baseline

**Methods:**
- `SleepComparison({required todayRecord, required baselines})`
- `SleepComparison.calculate(SleepRecord record, List<SleepBaseline> baselinesList)` - Factory constructor that computes differences
- `bool isAboveAverage(String metricName)` - Helper
- `String getDifferenceText(String metricName)` - Helper: "+10 min" or "-5 min"

**Why:** Simplifies UI logic for showing comparisons

---

## Step 3.4: Create Repository Interface

**File:** `lib/features/night_review/domain/repositories/sleep_record_repository.dart`
**Purpose:** Abstract interface for sleep record operations
**Dependencies:** `sleep_record`, `sleep_baseline`

**Abstract Class: SleepRecordRepository**

**Methods:**
- `Future<SleepRecord?> getRecordForDate(String userId, DateTime date)` - Get record for specific night
- `Future<List<SleepRecord>> getRecordsBetween(String userId, DateTime start, DateTime end)` - Date range query
- `Future<List<SleepRecord>> getRecentRecords(String userId, int days)` - Last N days
- `Future<void> saveRecord(SleepRecord record)` - Insert or update
- `Future<void> deleteRecord(String recordId)` - Remove record
- `Future<void> updateQualityRating(String recordId, String rating, String? notes)` - Update subjective rating
- `Future<List<SleepBaseline>> getBaselines(String userId, String baselineType)` - Get all baselines for type
- `Future<double?> getBaselineValue(String userId, String baselineType, String metricName)` - Get specific baseline

**Why:** Abstracts data access for sleep records and baselines

---

## Step 3.5: Create Local Data Source

**File:** `lib/features/night_review/data/datasources/sleep_record_local_datasource.dart`
**Purpose:** SQLite operations for sleep records and baselines
**Dependencies:** `sqflite`, `database_helper`, `database_constants`, models

**Class: SleepRecordLocalDataSource**

**Constructor:**
- `SleepRecordLocalDataSource({required Database database})`

**Methods:**

**`Future<SleepRecord?> getRecordByDate(String userId, DateTime date)`**
- Convert date to ISO 8601 string for query: `DatabaseDateUtils.toIso8601String(date)`
- Query: `SELECT * FROM ${DatabaseConstants.TABLE_SLEEP_RECORDS} WHERE user_id = ? AND sleep_date = ?`
- **IMPORTANT:** Convert Map to SleepRecord using **`fromDatabase`** (NOT fromJson!)
- Return record or null if empty

**`Future<List<SleepRecord>> getRecordsByDateRange(String userId, DateTime start, DateTime end)`**
- Convert start/end dates to ISO 8601 strings
- Query WHERE sleep_date BETWEEN start AND end
- **IMPORTANT:** Convert List<Map> to List<SleepRecord> using **`fromDatabase`**
- Order by sleep_date DESC

**`Future<void> insertRecord(SleepRecord record)`**
- Convert to Map using **`toDatabase()`** (NOT toJson!)
- INSERT OR REPLACE into sleep_records

**`Future<void> updateRecord(SleepRecord record)`**
- Convert to Map using **`toDatabase()`**
- UPDATE where id = record.id

**`Future<void> deleteRecord(String recordId)`**
- DELETE from sleep_records WHERE id = ?
- Use parameterized queries to prevent SQL injection

**`Future<void> updateQualityFields(String recordId, String rating, String? notes)`**
- UPDATE sleep_records SET quality_rating = ?, quality_notes = ?, updated_at = ? WHERE id = ?
- Updated_at should be DateTime.now() converted to ISO 8601

**`Future<List<SleepBaseline>> getBaselinesByType(String userId, String baselineType)`**
- Query user_sleep_baselines WHERE user_id = ? AND baseline_type = ?
- Convert to List<SleepBaseline> using **`fromDatabase`**

**`Future<double?> getSpecificBaseline(String userId, String baselineType, String metricName)`**
- Query for single metric_value
- Return double or null

**Pattern Reference:** See `ActionLocalDataSource` for database query patterns with constants

---

## Step 3.6: Implement Repository

**File:** `lib/features/night_review/data/repositories/sleep_record_repository_impl.dart`
**Purpose:** Concrete implementation delegating to data source
**Dependencies:** Repository interface, datasource, models

**Class: SleepRecordRepositoryImpl implements SleepRecordRepository**

**Constructor:**
- `SleepRecordRepositoryImpl({required SleepRecordLocalDataSource dataSource})`

**Fields:**
- `final SleepRecordLocalDataSource _dataSource`

**Methods:**
- All methods delegate to `_dataSource` with same signatures
- `getRecentRecords(userId, days)` calls `getRecordsByDateRange` with calculated start/end dates

---

## Step 3.7: Wire Up Providers in main.dart

**File:** `lib/main.dart`
**Purpose:** Register Night Review data layer components with Provider
**Dependencies:** DataSource and Repository

**CRITICAL - Provider Dependency Order (from Phase 2):**
Datasources MUST be registered BEFORE repositories!

**Add to MultiProvider:**
```dart
// Night Review - Sleep Records DataSource
Provider<SleepRecordLocalDataSource>(
  create: (context) => SleepRecordLocalDataSource(
    database: context.read<DatabaseHelper>().database,
  ),
),

// Night Review - Sleep Records Repository
Provider<SleepRecordRepository>(
  create: (context) => SleepRecordRepositoryImpl(
    dataSource: context.read<SleepRecordLocalDataSource>(),
  ),
),
```

**Note:** This only registers the data layer. ViewModel and Screen refactoring will be handled separately.

**Pattern:** Same as ActionLocalDataSource and ActionRepository registration

---

## Testing Checklist

### Unit Tests (Data Layer Only):
- [ ] Test SleepRecord fromJson/toJson with all fields
- [ ] Test SleepRecord fromDatabase/toDatabase with DateTime conversion
- [ ] Test sleepEfficiency calculation
- [ ] Test SleepComparison.calculate with mock data
- [ ] Test SleepBaseline fromDatabase/toDatabase with DatabaseDateUtils
- [ ] Test Repository methods delegate correctly to DataSource
- [ ] Test DataSource with mock Database

### Database Validation:
```sql
-- Insert test sleep record
INSERT INTO sleep_records (id, user_id, sleep_date, total_sleep_time, deep_sleep_duration, rem_sleep_duration, light_sleep_duration, created_at, updated_at)
VALUES ('test-uuid', 'user123', '2025-10-29', 420, 85, 95, 240, datetime('now'), datetime('now'));

-- Insert test baseline
INSERT INTO user_sleep_baselines (id, user_id, baseline_type, metric_name, metric_value, data_range_start, data_range_end, computed_at)
VALUES ('baseline-uuid', 'user123', '7_day', 'avg_deep_sleep', 80.0, '2025-10-22', '2025-10-29', datetime('now'));

-- Verify quality rating update
UPDATE sleep_records SET quality_rating = 'good' WHERE id = 'test-uuid';
SELECT quality_rating FROM sleep_records WHERE id = 'test-uuid';
```

---

## Rollback Strategy

Same as Phase 2:
- Keep original NightScreen as backup
- Can toggle implementations
- Or full rollback via git

---

## Next Steps

After Phase 3:
- Proceed to **PHASE_4.md:** Settings & User Profile
- User model needed for associating data with actual user IDs

---

## Notes

**Why Night Review second?**
- More complex than Action Center (multiple related tables)
- Tests nullable fields and date handling
- Introduces comparison logic

**Baseline Calculation:**
- For now, baselines are manually inserted or mock data
- Phase 6 will add automated baseline calculation service

**Wearable Integration:**
- For now, sleep records are manually inserted
- Future: Add actual Apple Health / Google Fit sync in core/wearables/

**UI Implementation:**
- ViewModel and Screen refactoring will be done separately
- See `NIGHT_REVIEW_IMPLEMENTATION_PLAN.md` for UI layer details
- This phase focuses on data layer only

**Estimated Time:** 3-4 hours (Data Layer Only)
- Migration and constants: 30 minutes
- Models: 90 minutes
- DataSource: 60 minutes
- Repository: 30 minutes
- Testing: 30 minutes
