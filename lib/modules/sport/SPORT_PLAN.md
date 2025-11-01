# Sport & Exercise Module - Implementation Plan

## Overview
Implement the Sport & Exercise module to help users optimize physical activity timing, intensity, and frequency for enhanced sleep quality. Exercise is a powerful sleep enhancer when timed appropriately, but poor timing can disrupt sleep.

**Core Principle:** Exercise timing and intensity significantly affect sleep quality. Morning and early afternoon exercise promotes better sleep, while intense evening exercise can delay sleep onset.

## Prerequisites
- ✅ **Light Module completed:** Pattern established, shared components available
- ✅ **Phase 5 patterns:** SettingsViewModel, error handling, current user access
- ✅ **Database:** `intervention_activities` and `user_module_configurations` tables exist
- ✅ **Shared components:** TimeSliderWidget, base models
- 📚 **Read:** SPORT_README.md for feature requirements

## Goals
- Create Sport module data models with intensity classification
- Implement wearable integration hooks (optional data from Apple Health/Google Fit)
- Build configuration screen with intensity-based time slider
- Enable automatic activity detection from wearables
- Track manual activity logging
- Implement optimal timing warnings
- **Expected outcome:** Sport module fully functional, wearable integration ready

---

## Step S.1: Database Migration - Sport Module Tables

**File:** `lib/core/database/migrations/migration_v6.dart`

**SQL Migration:**
```sql
-- Add indexes for sport module queries
CREATE INDEX IF NOT EXISTS idx_intervention_activities_sport
ON intervention_activities(user_id, module_id, activity_date, intensity)
WHERE module_id = 'sport';

-- Add check constraint for sport intensity levels
CREATE TRIGGER IF NOT EXISTS validate_sport_intensity
BEFORE INSERT ON intervention_activities
WHEN NEW.module_id = 'sport'
BEGIN
  SELECT RAISE(ABORT, 'Sport intensity must be low, medium, or high')
  WHERE NEW.intensity NOT IN ('low', 'medium', 'high');

  SELECT RAISE(ABORT, 'Sport duration must be 5-240 minutes')
  WHERE NEW.duration_minutes NOT BETWEEN 5 AND 240;
END;
```

---

## Step S.2: Create Sport Configuration Model

**File:** `lib/modules/sport/domain/models/sport_config.dart`

**Class: SportConfig**

**Fields:**
```dart
class SportConfig {
  // Standard mode: Morning HIIT
  final String targetTime;              // HH:mm
  final int targetDurationMinutes;      // Default: 30
  final String activityType;            // 'hiit', 'cardio', 'strength', 'walking', etc.
  final String intensity;               // 'low', 'medium', 'high'

  // Advanced mode
  final List<SportSession> sessions;    // Multiple sessions per day
  final bool wearableIntegrationEnabled;// Auto-detect from Apple Health/Google Fit

  // Notification settings
  final bool sessionReminderEnabled;
  final int reminderMinutesBefore;      // Default: 15
  final bool eveningWarningEnabled;     // Warn about late high-intensity exercise

  final String mode;                    // 'standard' or 'advanced'
}

class SportSession {
  final String id;
  final String sessionTime;             // HH:mm
  final int durationMinutes;
  final String activityType;
  final String intensity;               // Affects time slider color coding
  final List<int> daysOfWeek;           // 0=Monday, 6=Sunday
  final bool isEnabled;
}
```

**Static Defaults:**
- `standardDefault`: Morning HIIT, 30 min, high intensity
- `advancedDefault`: Morning HIIT + afternoon walk

**Validation:**
- High-intensity exercises must be > 4 hours before bedtime (uses user's bed time from Settings)
- Medium-intensity must be > 3 hours before bedtime
- Low-intensity safe anytime

---

## Step S.3: Create Sport Activity Model

**File:** `lib/modules/sport/domain/models/sport_activity.dart`

**Class: SportActivity extends InterventionActivity**

**Module-Specific Data (JSON):**
- `activity_type`: String - Type of exercise
- `heart_rate_avg`: double? - From wearable
- `heart_rate_max`: double? - From wearable
- `calories_burned`: int? - From wearable
- `distance_meters`: double? - For running/cycling
- `location`: String? - Indoor/outdoor/gym
- `wearable_source`: String? - 'apple_health', 'google_fit', 'manual'
- `weather`: String? - For outdoor activities

**Getters:**
```dart
String get activityType => moduleSpecificData?['activity_type'] ?? 'unknown';
double? get heartRateAvg => moduleSpecificData?['heart_rate_avg'];
int? get caloriesBurned => moduleSpecificData?['calories_burned'];
String get wearableSource => moduleSpecificData?['wearable_source'] ?? 'manual';
```

**Why:** Supports both manual logging and wearable data import

---

## Step S.4: Wearable Integration Service Interface

**File:** `lib/modules/sport/domain/services/sport_wearable_service.dart`

**Abstract Class: SportWearableService**

**Methods:**
```dart
abstract class SportWearableService {
  /// Fetch workouts from wearable for given date
  Future<List<WearableWorkout>> getWorkoutsForDate(DateTime date);

  /// Check if wearable permission granted
  Future<bool> hasPermission();

  /// Request wearable access permission
  Future<bool> requestPermission();

  /// Convert wearable workout to SportActivity
  SportActivity convertToActivity(String userId, WearableWorkout workout);
}

class WearableWorkout {
  final String type;                    // 'running', 'cycling', 'swimming', etc.
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double? heartRateAvg;
  final double? heartRateMax;
  final int? caloriesBurned;
  final double? distanceMeters;
  final String source;                  // 'apple_health' or 'google_fit'
}
```

**Implementation:** Deferred to later phase, returns empty list for now

**Why:** Establishes contract for future wearable integration

---

## Step S.5: Create Sport Repository Interface

**File:** `lib/modules/sport/domain/repositories/sport_module_repository.dart`

**Abstract Class: SportModuleRepository**

**Methods:**
```dart
abstract class SportModuleRepository {
  // Configuration
  Future<UserModuleConfig?> getUserConfig(String userId);
  Future<void> saveConfig(UserModuleConfig config);
  Future<bool> isModuleEnabled(String userId);
  Future<void> enableModule(String userId, SportConfig defaultConfig);
  Future<void> disableModule(String userId);

  // Activity tracking
  Future<List<SportActivity>> getActivitiesForDate(String userId, DateTime date);
  Future<List<SportActivity>> getActivitiesBetween(String userId, DateTime start, DateTime end);
  Future<void> logActivity(SportActivity activity);
  Future<void> updateActivity(SportActivity activity);
  Future<void> deleteActivity(String activityId);

  // Analytics
  Future<int> getTotalMinutesExercised(String userId, DateTime start, DateTime end);
  Future<Map<String, int>> getActivityTypeDistribution(String userId, DateTime start, DateTime end);
  Future<Map<String, int>> getIntensityDistribution(String userId, DateTime start, DateTime end);
  Future<int> getHighIntensityCount(String userId, DateTime start, DateTime end);
}
```

---

## Step S.6: Sport ViewModel with Timing Validation

**File:** `lib/modules/sport/presentation/viewmodels/sport_module_viewmodel.dart`

**Class: SportModuleViewModel extends ChangeNotifier**

**Additional Methods (beyond standard):**
```dart
/// Validate session timing against sleep schedule
String? validateSessionTiming(SportSession session, DateTime bedTime) {
  final sessionDateTime = _parseTime(session.sessionTime);
  final bedDateTime = _parseTime('${bedTime.hour}:${bedTime.minute}');

  final hoursBefore = bedDateTime.difference(sessionDateTime).inHours;

  if (session.intensity == 'high' && hoursBefore < 4) {
    return 'High-intensity exercise should be at least 4 hours before bedtime';
  }

  if (session.intensity == 'medium' && hoursBefore < 3) {
    return 'Medium-intensity exercise should be at least 3 hours before bedtime';
  }

  return null; // Valid timing
}

/// Auto-import activities from wearable
Future<void> syncWearableActivities(String userId, DateTime date) async {
  try {
    _isLoading = true;
    notifyListeners();

    // Get workouts from wearable service
    final workouts = await _wearableService.getWorkoutsForDate(date);

    // Convert and save each workout
    for (final workout in workouts) {
      final activity = _wearableService.convertToActivity(userId, workout);
      await _repository.logActivity(activity);
    }

    // Reload activities to show imported data
    await loadActivities(userId, date);

  } catch (e) {
    _errorMessage = 'Failed to sync wearable data: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

---

## Step S.7: Sport Configuration Screen with Time Validation

**File:** `lib/modules/sport/presentation/screens/sport_config_screen.dart`

**UI Components:**

**Time Slider Integration:**
```dart
// Use shared TimeSliderWidget with sport-specific color scheme
TimeSliderWidget(
  sessions: config.sessions.map((s) => TimeMarker(
    time: s.sessionTime,
    label: s.activityType,
    color: _getIntensityColor(s.intensity),
  )).toList(),
  sleepWindow: SleepWindow(
    bedTime: settingsViewModel.currentUser?.targetBedTime,
    wakeTime: settingsViewModel.currentUser?.targetWakeTime,
  ),
  colorScheme: SportColorScheme(), // High intensity = red in evening
  onTimeChanged: (marker, newTime) {
    // Update session time
    // Validate timing
    final warning = viewModel.validateSessionTiming(
      session,
      settingsViewModel.currentUser!.targetBedTime,
    );
    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(warning), backgroundColor: Colors.orange),
      );
    }
  },
)
```

**Intensity Selector:**
```dart
SegmentedButton<String>(
  segments: [
    ButtonSegment(value: 'low', label: Text('Low'), icon: Icon(Icons.directions_walk)),
    ButtonSegment(value: 'medium', label: Text('Medium'), icon: Icon(Icons.directions_run)),
    ButtonSegment(value: 'high', label: Text('High'), icon: Icon(Icons.fitness_center)),
  ],
  selected: {session.intensity},
  onSelectionChanged: (Set<String> newSelection) {
    // Update intensity and revalidate timing
  },
)
```

**Wearable Sync Button:**
```dart
if (config.wearableIntegrationEnabled)
  ElevatedButton.icon(
    icon: Icon(Icons.watch),
    label: Text('Sync from Apple Watch'),
    onPressed: () async {
      await viewModel.syncWearableActivities(userId, DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced ${viewModel.activities.length} activities')),
      );
    },
  ),
```

---

## Testing Checklist

### Manual Tests:
- [ ] Enable Sport module, set morning HIIT
- [ ] Try to schedule high-intensity exercise at 10 PM, see warning
- [ ] Log manual activity with duration and type
- [ ] Change intensity level, verify time slider updates color scheme
- [ ] Enable wearable integration (shows permission request)
- [ ] Sync wearable data (empty list for now, no error)
- [ ] View activity correlation with sleep data

### Timing Validation Tests:
- [ ] High-intensity at 6 PM (bed time 10 PM): Should show warning (< 4 hours)
- [ ] High-intensity at 5 PM (bed time 10 PM): Should be OK (= 5 hours)
- [ ] Medium-intensity at 8 PM (bed time 10 PM): Should be OK (= 2 hours is risky but below threshold)
- [ ] Low-intensity at 9:30 PM: Should be OK (safe anytime)

### Database Tests:
```sql
-- Check sport activities with intensity
SELECT
  activity_date,
  time_of_day,
  intensity,
  duration_minutes,
  module_specific_data->>'activity_type' as type,
  was_completed
FROM intervention_activities
WHERE module_id = 'sport'
ORDER BY activity_date DESC;

-- Correlation: High-intensity morning vs sleep quality
SELECT
  ia.activity_date,
  ia.time_of_day,
  ia.intensity,
  sr.deep_sleep_duration,
  sr.total_sleep_time
FROM intervention_activities ia
JOIN sleep_records sr
  ON sr.user_id = ia.user_id
  AND sr.sleep_date = ia.activity_date
WHERE ia.module_id = 'sport'
  AND ia.intensity = 'high'
  AND ia.time_of_day = 'morning'
ORDER BY ia.activity_date DESC;
```

---

## Notes

**Sport Module Complexity:**
- More complex than Light due to intensity levels and timing validation
- Wearable integration adds another layer (but deferred to later)
- Time slider must show different colors based on intensity

**Timing Validation Rules:**
- Based on research: high-intensity exercise raises core body temp and adrenaline
- Takes ~4 hours for high-intensity effects to subside
- Low-intensity (walking, stretching) safe anytime
- Validation uses user's bed time from SettingsViewModel

**Wearable Integration Strategy:**
- Phase 1 (this plan): Define interfaces, manual logging only
- Phase 2 (future): Implement Apple Health integration for iOS
- Phase 3 (future): Implement Google Fit integration for Android
- Automatic import prevents double-logging, enriches data with HR/calories

**Estimated Time:** 12-14 hours
- Database migration: 30 minutes
- Models (Config + Activity + Wearable): 120 minutes
- Repository + Datasource: 120 minutes
- Wearable service interface: 60 minutes
- ViewModel with timing validation: 150 minutes
- Configuration screen with time slider: 150 minutes
- Timing validation UI: 90 minutes
- Testing: 90 minutes
