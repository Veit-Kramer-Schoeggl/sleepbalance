# PHASE 3: Night Review Refactoring

## Overview
Refactor Night Review screen to use MVVM + Provider pattern, integrate with sleep_records database table, add subjective quality rating, and implement baseline comparisons.

## Prerequisites
- **Phase 1 completed:** Database infrastructure
- **Phase 2 completed:** MVVM pattern validated with Action Center
- Understanding of repository pattern and ViewModel

## Goals
- Create SleepRecord model for nightly sleep data
- Create SleepBaseline model for personal averages
- Implement repository pattern for sleep records
- Create NightReviewViewModel with date navigation
- Add quality rating widget (3-point scale: bad/average/good)
- Refactor NightScreen to consume ViewModel
- Display "today vs your average" comparisons

---

## Step 3.1: Create Domain Model - SleepRecord

**File:** `lib/features/night_review/domain/models/sleep_record.dart`
**Purpose:** Model for nightly sleep data from wearables (aggregated metrics)
**Dependencies:** `json_annotation`

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
- `factory SleepRecord.fromJson(Map<String, dynamic> json)` - Deserialize
- `Map<String, dynamic> toJson()` - Serialize
- `SleepRecord copyWith({...})` - Immutable update
- `int? get sleepEfficiency` - Calculated: (totalSleepTime / timeInBed) * 100
- `Duration? get timeInBed` - bedTime to wakeTime duration

**Annotations:**
- `@JsonSerializable()`

**Why:** Replaces unused existing `SleepData` model, aligns with database schema

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
- Query sleep_records WHERE user_id AND sleep_date
- Convert Map to SleepRecord using fromJson
- Return record or null

**`Future<List<SleepRecord>> getRecordsByDateRange(String userId, DateTime start, DateTime end)`**
- Query WHERE sleep_date BETWEEN start AND end
- Convert List<Map> to List<SleepRecord>
- Order by sleep_date DESC

**`Future<void> insertRecord(SleepRecord record)`**
- Convert to Map
- INSERT OR REPLACE into sleep_records

**`Future<void> updateRecord(SleepRecord record)`**
- Convert to Map
- UPDATE where id = record.id

**`Future<void> deleteRecord(String recordId)`**
- DELETE from sleep_records WHERE id

**`Future<void> updateQualityFields(String recordId, String rating, String? notes)`**
- UPDATE sleep_records SET quality_rating, quality_notes WHERE id

**`Future<List<SleepBaseline>> getBaselinesByType(String userId, String baselineType)`**
- Query user_sleep_baselines WHERE user_id AND baseline_type
- Convert to List<SleepBaseline>

**`Future<double?> getSpecificBaseline(String userId, String baselineType, String metricName)`**
- Query for single metric_value
- Return double or null

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

## Step 3.7: Create ViewModel

**File:** `lib/features/night_review/presentation/viewmodels/night_review_viewmodel.dart`
**Purpose:** Manage Night Review state, date navigation, sleep data loading
**Dependencies:** `provider`, repository, models

**Class: NightReviewViewModel extends ChangeNotifier**

**Constructor:**
- `NightReviewViewModel({required SleepRecordRepository repository})`

**Fields:**
- `final SleepRecordRepository _repository`
- `DateTime _currentDate = DateTime.now()`
- `SleepRecord? _sleepRecord` - Current night's data (nullable)
- `SleepComparison? _comparison` - Comparison with baseline (nullable)
- `bool _isLoading = false`
- `bool _isCalendarExpanded = false` - Migrated from NightScreen state
- `String? _errorMessage`

**Getters:**
- `DateTime get currentDate`
- `SleepRecord? get sleepRecord`
- `SleepComparison? get comparison`
- `bool get isLoading`
- `bool get isCalendarExpanded`
- `String? get errorMessage`
- `bool get hasData => sleepRecord != null`

**Methods:**

**`Future<void> loadSleepData(String userId)`**
- Set loading true
- Fetch sleep record for currentDate
- Fetch baselines (7-day)
- If record exists: Calculate comparison
- Handle errors
- Set loading false, notify listeners

**`Future<void> changeDate(DateTime newDate)`**
- Set _currentDate = newDate
- Reload sleep data
- Notify listeners

**`Future<void> goToPreviousDay()`**
- changeDate(currentDate.subtract(1 day))

**`Future<void> goToNextDay()`**
- changeDate(currentDate.add(1 day))

**`void toggleCalendarExpansion()`**
- Flip _isCalendarExpanded
- Notify listeners

**`Future<void> saveQualityRating(String rating, String? notes)`**
- If no record exists: Show error
- Call repository.updateQualityRating
- Reload data
- Notify listeners

**`void clearError()`**
- Set errorMessage null, notify

---

## Step 3.8: Create Quality Rating Widget

**File:** `lib/features/night_review/presentation/widgets/quality_rating_widget.dart`
**Purpose:** 3-point scale input for subjective sleep quality
**Dependencies:** `flutter/material.dart`

**Class: QualityRatingWidget extends StatelessWidget**

**Constructor:**
- `QualityRatingWidget({required String? currentRating, required Function(String) onRatingSelected})`

**Build Method:**
- Display 3 buttons horizontally: "Bad" | "Average" | "Good"
- Highlight selected rating
- Call onRatingSelected callback when tapped

**Styling:**
- Bad: Red background when selected
- Average: Yellow background when selected
- Good: Green background when selected

**Why:** User provides subjective input to complement objective wearable data

---

## Step 3.9: Refactor NightScreen

**File:** `lib/features/night_review/presentation/screens/night_screen.dart`
**Purpose:** Transform to StatelessWidget consuming NightReviewViewModel
**Dependencies:** `provider`, viewmodel, widgets

**Changes:**

### Remove (DELETE):
- `_NightScreenState` class (lines 14-94)
- `_currentDate` and `_isCalendarExpanded` state (lines 15-16) - Moved to ViewModel
- All setState() calls

### Convert:
- `NightScreen extends StatefulWidget` → `NightScreen extends StatelessWidget`

### New Structure:

**`class NightScreen extends StatelessWidget`**

**Build Method:**
```
ChangeNotifierProvider(
  create: (_) => NightReviewViewModel(
    repository: context.read<SleepRecordRepository>(),
  )..loadSleepData('hardcoded-user-id'),
  child: _NightScreenContent(),
)
```

**`class _NightScreenContent extends StatelessWidget`**

**Build Method:**
- `final viewModel = context.watch<NightReviewViewModel>()`
- Show loading spinner if `viewModel.isLoading`
- Show error if `viewModel.errorMessage != null`
- **DateNavigationHeader:**
  - currentDate: `viewModel.currentDate`
  - onPreviousDay: `viewModel.goToPreviousDay`
  - onNextDay: `viewModel.goToNextDay`
  - onDateTap: `viewModel.toggleCalendarExpansion`
- **ExpandableCalendar:**
  - selectedDate: `viewModel.currentDate`
  - isExpanded: `viewModel.isCalendarExpanded`
  - onDateSelected: `viewModel.changeDate`
- **Content Area:**
  - If `viewModel.hasData`:
    - Display sleep phases breakdown
    - Display biometric data (heart rate, HRV, breathing rate)
    - Display comparison: "Your 7-day average: X min. Tonight: Y min (+Z)"
    - Show QualityRatingWidget
  - Else: Show "No sleep data for this night"

---

## Testing Checklist

### Manual Tests:
- [ ] Launch app, navigate to Night Review
- [ ] Should show "No sleep data" (database empty)
- [ ] Manually insert test sleep record via SQLite
- [ ] Restart app, sleep data should display
- [ ] Tap date arrows, should navigate dates
- [ ] Tap date header, calendar should expand/collapse
- [ ] Select date in calendar, data for that date should load
- [ ] Tap quality rating button, should save to database
- [ ] Check database, quality_rating field should update

### Unit Tests:
- [ ] Test SleepRecord fromJson/toJson with all nullable fields
- [ ] Test sleepEfficiency calculation
- [ ] Test SleepComparison.calculate with mock data
- [ ] Test ViewModel date navigation methods
- [ ] Test ViewModel loadSleepData handles null records

### Integration Tests:
- [ ] Insert sleep record → Display in UI → Update quality → Verify in DB

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

**Estimated Time:** 5-7 hours
- Models: 90 minutes
- Repository: 90 minutes
- ViewModel: 90 minutes
- Quality rating widget: 30 minutes
- Screen refactoring: 90 minutes
- Testing: 60 minutes
