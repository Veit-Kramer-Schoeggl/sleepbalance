# Mealtime Module - Implementation Plan

## Overview
Implement the Mealtime Module to help users optimize eating schedule for better sleep quality. Based on sleep science principles, the module encourages earlier eating patterns and discourages late-night consumption.

**Core Principle:** Eating earlier in the day supports better sleep. Late-night eating can disrupt sleep quality and circadian rhythms. Meal timing optimization aligns eating with the body's natural rhythms.

## Prerequisites
- ✅ **Light & Sport modules completed:** TimeSliderWidget available
- ✅ **Settings:** User's wake/bed times accessible via SettingsViewModel
- 📚 **Read:** MEALTIME_README.md

## Goals
- Create meal scheduling system with automatic timing based on sleep schedule
- Implement eating window for intermittent fasting support
- Build time slider with meal-specific color coding
- Track meal timing adherence
- Auto-adjust meal times when sleep schedule changes
- **Expected outcome:** Mealtime module with intelligent scheduling and time slider

---

## Step MT.1: Database Migration - Mealtime Scheduling

**File:** `lib/core/database/migrations/migration_v11.dart`

**SQL Migration:**
```sql
-- No separate mealtime table needed
-- Uses intervention_activities with module_id = 'mealtime'

-- Index for mealtime activities
CREATE INDEX IF NOT EXISTS idx_intervention_activities_mealtime
ON intervention_activities(user_id, module_id, activity_date, time_of_day)
WHERE module_id = 'mealtime';

-- Validate meal timing constraints
CREATE TRIGGER IF NOT EXISTS validate_mealtime_activity
BEFORE INSERT ON intervention_activities
WHEN NEW.module_id = 'mealtime'
BEGIN
  -- Meals should not be logged during sleep hours
  -- (This is a soft validation - warning only, not blocking)
  SELECT CASE
    WHEN json_extract(NEW.module_specific_data, '$.meal_type') IS NULL
    THEN RAISE(ABORT, 'Mealtime activities must specify meal_type')
  END;
END;
```

**Why:** Uses existing intervention_activities table with module-specific data

---

## Step MT.2: Mealtime Configuration Model

**File:** `lib/modules/mealtime/domain/models/mealtime_config.dart`

**Class: MealtimeConfig**

**Fields:**
```dart
class MealtimeConfig {
  // Standard mode: 3 meals, auto-calculated from sleep schedule
  final int numberOfMeals;            // Default: 3
  final List<MealSchedule> meals;     // Scheduled meal times

  // Eating window (for intermittent fasting)
  final bool useEatingWindow;         // Default: false
  final String? eatingWindowStart;    // HH:mm (nullable)
  final String? eatingWindowEnd;      // HH:mm (nullable)
  final int? eatingWindowHours;       // Calculated duration

  // Auto-adjustment settings
  final bool autoAdjustToSleep;       // Default: true (recalculate when wake/bed time changes)

  // Notification settings
  final bool mealRemindersEnabled;
  final int reminderMinutesBefore;    // Default: 15

  final String mode;                  // 'standard' or 'intermittent_fasting'
}

class MealSchedule {
  final String id;
  final String mealType;              // 'breakfast', 'lunch', 'dinner', 'snack_1', 'snack_2', etc.
  final String scheduledTime;         // HH:mm
  final bool isEnabled;
  final bool notificationEnabled;
}
```

**Static Methods:**
```dart
/// Generate standard 3-meal schedule based on wake/bed times
static MealtimeConfig generateStandard(TimeOfDay wakeTime, TimeOfDay bedTime) {
  // Breakfast: 1 hour after wake
  final breakfastTime = _addHours(wakeTime, 1);

  // Lunch: Midpoint between breakfast and dinner
  // Dinner: 5 hours before bed (circadian-friendly)
  final dinnerTime = _subtractHours(bedTime, 5);

  final lunchTime = _midpoint(breakfastTime, dinnerTime);

  return MealtimeConfig(
    numberOfMeals: 3,
    meals: [
      MealSchedule(
        id: 'breakfast',
        mealType: 'breakfast',
        scheduledTime: _formatTime(breakfastTime),
        isEnabled: true,
        notificationEnabled: true,
      ),
      MealSchedule(
        id: 'lunch',
        mealType: 'lunch',
        scheduledTime: _formatTime(lunchTime),
        isEnabled: true,
        notificationEnabled: true,
      ),
      MealSchedule(
        id: 'dinner',
        mealType: 'dinner',
        scheduledTime: _formatTime(dinnerTime),
        isEnabled: true,
        notificationEnabled: true,
      ),
    ],
    useEatingWindow: false,
    autoAdjustToSleep: true,
    mealRemindersEnabled: true,
    reminderMinutesBefore: 15,
    mode: 'standard',
  );
}

/// Generate intermittent fasting schedule with eating window
static MealtimeConfig generateIntermittentFasting(
  TimeOfDay wakeTime,
  TimeOfDay bedTime,
  int windowHours,
) {
  // Eating window starts 2 hours after wake
  final windowStart = _addHours(wakeTime, 2);
  final windowEnd = _addHours(windowStart, windowHours);

  // Space meals evenly within window
  // For 8-hour window: 2 meals (noon and 6 PM)
  // For 6-hour window: 2 meals (1 PM and 5 PM)

  final meals = _distributeMealsInWindow(windowStart, windowEnd, 2);

  return MealtimeConfig(
    numberOfMeals: meals.length,
    meals: meals,
    useEatingWindow: true,
    eatingWindowStart: _formatTime(windowStart),
    eatingWindowEnd: _formatTime(windowEnd),
    eatingWindowHours: windowHours,
    autoAdjustToSleep: true,
    mealRemindersEnabled: true,
    reminderMinutesBefore: 15,
    mode: 'intermittent_fasting',
  );
}
```

**Validation:**
```dart
String? validate(TimeOfDay bedTime) {
  for (final meal in meals) {
    final mealTime = _parseTime(meal.scheduledTime);
    final hoursBefore = _calculateHoursBefore(mealTime, bedTime);

    // Last meal should be at least 3 hours before bed
    if (meal.mealType.contains('dinner') || meals.last.id == meal.id) {
      if (hoursBefore < 3) {
        return '${meal.mealType} is too close to bedtime (should be 3+ hours before)';
      }
    }
  }
  return null; // Valid
}
```

---

## Step MT.3: Mealtime Activity Model

**File:** `lib/modules/mealtime/domain/models/mealtime_activity.dart`

**Class: MealtimeActivity extends InterventionActivity**

**Module-Specific Data (JSON):**
```dart
{
  'meal_type': string,                // 'breakfast', 'lunch', 'dinner', 'snack'
  'scheduled_time': string,           // HH:mm - what time it was supposed to be
  'actual_time': string?,             // HH:mm - what time user actually ate
  'time_difference_minutes': int?,    // Difference from scheduled
  'location': string?,                // 'home', 'restaurant', 'work', 'other'
  'skipped': bool,                    // Did user skip this meal
  'skip_reason': string?,             // If skipped: 'not_hungry', 'too_busy', 'forgot'
  'eating_window_adhered': bool?,     // If intermittent fasting: stayed in window?
}
```

**Getters:**
```dart
String get mealType => moduleSpecificData?['meal_type'] ?? 'unknown';
String get scheduledTime => moduleSpecificData?['scheduled_time'] ?? '00:00';
String? get actualTime => moduleSpecificData?['actual_time'];
int? get timeDifferenceMinutes => moduleSpecificData?['time_difference_minutes'];
bool get skipped => moduleSpecificData?['skipped'] ?? false;
bool? get eatingWindowAdhered => moduleSpecificData?['eating_window_adhered'];

bool get wasOnTime {
  if (timeDifferenceMinutes == null) return false;
  return timeDifferenceMinutes!.abs() <= 30; // Within 30 min = on time
}
```

---

## Step MT.4: Time Slider Color Scheme for Meals

**File:** `lib/modules/mealtime/presentation/utils/mealtime_color_scheme.dart`

**Class: MealtimeColorScheme**

**Purpose:** Color feedback based on meal timing relative to sleep schedule

**Method:**
```dart
Color getColorForTime(TimeOfDay time, TimeOfDay wakeTime, TimeOfDay bedTime) {
  final hoursSinceWake = _calculateHoursSince(wakeTime, time);
  final hoursBeforeBed = _calculateHoursBefore(time, bedTime);

  // Immediately after waking or during sleep: Dark red (bad)
  if (hoursSinceWake < 0.5) return Colors.red[900]!;

  // 0.5-1 hour after wake: Red/orange (suboptimal - should wait a bit)
  if (hoursSinceWake < 1) return Colors.deepOrange;

  // 1-2 hours after wake: Light green (good for breakfast)
  if (hoursSinceWake < 2) return Colors.lightGreen;

  // Midday (4-8 hours after wake): Green (optimal for lunch)
  if (hoursSinceWake >= 4 && hoursSinceWake <= 8) {
    return Colors.green[700]!;
  }

  // Late afternoon (8-10 hours after wake): Light green (good for dinner)
  if (hoursSinceWake >= 8 && hoursSinceWake <= 10) {
    return Colors.lightGreen;
  }

  // Evening hours before bed:
  if (hoursBeforeBed >= 5) return Colors.lightGreen;    // 5+ hours: good
  if (hoursBeforeBed >= 3) return Colors.yellow;        // 3-5 hours: neutral
  if (hoursBeforeBed >= 2) return Colors.orange;        // 2-3 hours: suboptimal
  if (hoursBeforeBed >= 1) return Colors.deepOrange;    // 1-2 hours: bad
  return Colors.red[900]!;                              // <1 hour: very bad
}
```

**Why:** Color feedback guides users away from late-night eating

---

## Step MT.5: Mealtime Repository Interface

**File:** `lib/modules/mealtime/domain/repositories/mealtime_repository.dart`

**Import & Interface:**
```dart
import '../../../shared/domain/repositories/intervention_repository.dart';
import '../models/mealtime_activity.dart';

/// Mealtime repository interface
/// Extends InterventionRepository with meal adherence and timing analysis
abstract class MealtimeRepository extends InterventionRepository {
  // Meal adherence and timing methods
  Future<double> getMealAdherenceRate(String userId, DateTime start, DateTime end);
  Future<int> getOnTimeMealCount(String userId, DateTime start, DateTime end);
  Future<Map<String, int>> getMealTypeDistribution(String userId, DateTime start, DateTime end);
}
```

**Inherited from base:** `getUserConfig`, `saveConfig`, `getActivitiesForDate`, `getActivitiesBetween`, `logActivity`, `updateActivity`, `deleteActivity`, `getCompletionCount`, `getCompletionRate`

---

## Step MT.6: Mealtime ViewModel with Auto-Adjustment

**File:** `lib/modules/mealtime/presentation/viewmodels/mealtime_module_viewmodel.dart`

**Class: MealtimeModuleViewModel extends ChangeNotifier**

**Additional Methods:**
```dart
/// Recalculate meal times when sleep schedule changes
Future<void> recalculateMealTimes(String userId, TimeOfDay newWakeTime, TimeOfDay newBedTime) async {
  if (_mealtimeConfig == null || !_mealtimeConfig!.autoAdjustToSleep) {
    return; // User disabled auto-adjustment
  }

  try {
    _isLoading = true;
    notifyListeners();

    // Generate new meal schedule
    final newConfig = _mealtimeConfig!.mode == 'standard'
        ? MealtimeConfig.generateStandard(newWakeTime, newBedTime)
        : MealtimeConfig.generateIntermittentFasting(
            newWakeTime,
            newBedTime,
            _mealtimeConfig!.eatingWindowHours ?? 8,
          );

    // Preserve user's custom settings (notifications, etc.)
    final updatedConfig = newConfig.copyWith(
      mealRemindersEnabled: _mealtimeConfig!.mealRemindersEnabled,
      reminderMinutesBefore: _mealtimeConfig!.reminderMinutesBefore,
    );

    await saveConfig(userId, updatedConfig);

    // Reschedule notifications
    await scheduleNotifications(userId, updatedConfig);

  } catch (e) {
    _errorMessage = 'Failed to recalculate meal times: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

/// Validate meal timing and show warning if too late
String? validateMealTiming(MealSchedule meal, TimeOfDay bedTime) {
  final mealTime = _parseTime(meal.scheduledTime);
  final hoursBefore = _calculateHoursBefore(mealTime, bedTime);

  if (meal.mealType.contains('dinner') || meal.mealType.contains('snack')) {
    if (hoursBefore < 3) {
      return 'Warning: ${meal.mealType} is only ${hoursBefore.toStringAsFixed(1)} hours before bed. Recommended: 3+ hours.';
    }
  }

  return null; // OK
}

/// Log meal adherence
Future<void> logMeal(
  String userId,
  String mealType,
  String scheduledTime,
  {String? actualTime, bool skipped = false, String? skipReason}
) async {
  try {
    final timeDiff = actualTime != null
        ? _calculateTimeDifference(scheduledTime, actualTime)
        : null;

    final activity = MealtimeActivity(
      id: _generateUuid(),
      userId: userId,
      activityDate: DateTime.now(),
      wasCompleted: !skipped,
      completedAt: skipped ? null : DateTime.now(),
      timeOfDay: _getTimeOfDay(actualTime ?? scheduledTime),
      mealType: mealType,
      scheduledTime: scheduledTime,
      actualTime: actualTime,
      timeDifferenceMinutes: timeDiff,
      skipped: skipped,
      skipReason: skipReason,
    );

    await _repository.logActivity(activity);
    await loadActivities(userId, DateTime.now());

  } catch (e) {
    _errorMessage = 'Failed to log meal: $e';
  }
}
```

---

## Step MT.7: Mealtime Configuration Screen with Time Slider

**File:** `lib/modules/mealtime/presentation/screens/mealtime_config_screen.dart`

**UI Components:**
```dart
// Mode selector
SegmentedButton<String>(
  segments: [
    ButtonSegment(value: 'standard', label: Text('Standard')),
    ButtonSegment(value: 'intermittent_fasting', label: Text('Intermittent Fasting')),
  ],
  selected: {config.mode},
  onSelectionChanged: (value) {
    // Switch modes
  },
),

// Standard mode: Meal count selector
if (config.mode == 'standard')
  Column(
    children: [
      Text('Number of Meals Per Day'),
      Slider(
        value: config.numberOfMeals.toDouble(),
        min: 1,
        max: 6,
        divisions: 5,
        label: config.numberOfMeals.toString(),
        onChanged: (value) {
          // Regenerate meal schedule with new meal count
        },
      ),
    ],
  ),

// Intermittent fasting mode: Eating window selector
if (config.mode == 'intermittent_fasting')
  Column(
    children: [
      Text('Eating Window Duration'),
      Slider(
        value: (config.eatingWindowHours ?? 8).toDouble(),
        min: 4,
        max: 12,
        divisions: 8,
        label: '${config.eatingWindowHours} hours',
        onChanged: (value) {
          // Regenerate with new window size
        },
      ),

      // Show eating window times
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('Window Start'),
              Text(config.eatingWindowStart ?? '--:--', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          Icon(Icons.arrow_forward),
          Column(
            children: [
              Text('Window End'),
              Text(config.eatingWindowEnd ?? '--:--', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ],
      ),
    ],
  ),

// Time slider visualization
TimeSliderWidget(
  sessions: config.meals.map((meal) => TimeMarker(
    time: meal.scheduledTime,
    label: meal.mealType,
    icon: _getMealIcon(meal.mealType),
  )).toList(),
  sleepWindow: SleepWindow(
    bedTime: settingsViewModel.currentUser?.targetBedTime,
    wakeTime: settingsViewModel.currentUser?.targetWakeTime,
  ),
  // Show eating window if intermittent fasting
  eatingWindow: config.useEatingWindow
      ? EatingWindow(
          start: config.eatingWindowStart!,
          end: config.eatingWindowEnd!,
        )
      : null,
  colorSchemeCalculator: (time, marker) {
    return MealtimeColorScheme().getColorForTime(
      time,
      settingsViewModel.currentUser!.targetWakeTime,
      settingsViewModel.currentUser!.targetBedTime,
    );
  },
  onTimeChanged: (marker, newTime) {
    // Update meal time
    // Validate against bed time
    final meal = _findMeal(marker);
    final warning = viewModel.validateMealTiming(
      meal,
      settingsViewModel.currentUser!.targetBedTime,
    );
    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(warning), backgroundColor: Colors.orange),
      );
    }
  },
),

// Individual meal cards
ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  itemCount: config.meals.length,
  itemBuilder: (context, index) {
    final meal = config.meals[index];
    return MealCard(
      meal: meal,
      onTimeChanged: (newTime) {
        // Update this meal's time
      },
      onNotificationToggled: (enabled) {
        // Toggle notification for this meal
      },
    );
  },
),

// Auto-adjust toggle
SwitchListTile(
  title: Text('Auto-adjust to Sleep Schedule'),
  subtitle: Text('Recalculate meal times when you change your wake/bed times'),
  value: config.autoAdjustToSleep,
  onChanged: (value) {
    final newConfig = config.copyWith(autoAdjustToSleep: value);
    viewModel.saveConfig(userId, newConfig);
  },
),
```

---

## Step MT.8: Meal Logging Screen

**File:** `lib/modules/mealtime/presentation/screens/meal_logging_screen.dart`

**Purpose:** Quick meal adherence logging

**UI Components:**
```dart
// Today's meals
ListView.builder(
  itemCount: config.meals.length,
  itemBuilder: (context, index) {
    final meal = config.meals[index];
    final logged = viewModel.getMealActivity(meal.mealType, DateTime.now());

    return Card(
      child: ListTile(
        leading: _getMealIcon(meal.mealType),
        title: Text(meal.mealType),
        subtitle: Text('Scheduled: ${meal.scheduledTime}'),
        trailing: logged != null
            ? Icon(logged.skipped ? Icons.cancel : Icons.check_circle, color: Colors.green)
            : ElevatedButton(
                child: Text('Log'),
                onPressed: () {
                  _showLogMealDialog(meal);
                },
              ),
      ),
    );
  },
),
```

**Log Meal Dialog:**
```dart
void _showLogMealDialog(MealSchedule meal) {
  showDialog(
    context: context,
    builder: (context) {
      String? actualTime = meal.scheduledTime;
      bool skipped = false;

      return AlertDialog(
        title: Text('Log ${meal.mealType}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('I skipped this meal'),
              value: skipped,
              onChanged: (value) {
                setState(() => skipped = value);
              },
            ),
            if (!skipped)
              ListTile(
                title: Text('Actual Time'),
                subtitle: Text(actualTime ?? '--:--'),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _parseTime(meal.scheduledTime),
                  );
                  if (time != null) {
                    setState(() {
                      actualTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Save'),
            onPressed: () {
              viewModel.logMeal(
                userId,
                meal.mealType,
                meal.scheduledTime,
                actualTime: skipped ? null : actualTime,
                skipped: skipped,
              );
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
```

---

## Testing Checklist

### Manual Tests:
- [ ] Enable Mealtime module, verify standard 3-meal schedule generated
- [ ] Change wake time in Settings, verify meals auto-adjust
- [ ] Switch to intermittent fasting mode, verify eating window shown
- [ ] Adjust eating window duration, verify window and meal times update
- [ ] Try to schedule dinner 1 hour before bed, see warning
- [ ] Log meal on time, verify marked as completed
- [ ] Log meal 45 min late, verify time difference calculated
- [ ] Skip a meal, verify marked as skipped with reason
- [ ] View meal adherence over week, verify streak tracking

### Time Slider Tests:
- [ ] Meal at 8 PM (bed at 10 PM): Orange/red (too close)
- [ ] Meal at 5 PM (bed at 10 PM): Green (optimal: 5h before)
- [ ] Meal at noon: Dark green (optimal midday)
- [ ] Eating window highlighted in slider (if intermittent fasting)

### Auto-Adjustment Tests:
- [ ] Set wake time to 6 AM, verify breakfast at 7 AM
- [ ] Change wake time to 8 AM, verify breakfast moves to 9 AM
- [ ] Set bed time to 10 PM, verify dinner at 5 PM (5h before)
- [ ] Change bed time to 11 PM, verify dinner moves to 6 PM

### Database Tests:
```sql
-- Check mealtime activities
SELECT
  activity_date,
  time_of_day,
  module_specific_data->>'meal_type' as meal,
  module_specific_data->>'scheduled_time' as scheduled,
  module_specific_data->>'actual_time' as actual,
  module_specific_data->>'time_difference_minutes' as diff,
  was_completed
FROM intervention_activities
WHERE module_id = 'mealtime'
ORDER BY activity_date DESC, time_of_day;

-- Check meal adherence rate
SELECT
  module_specific_data->>'meal_type' as meal_type,
  COUNT(*) as total,
  SUM(CASE WHEN was_completed = 1 THEN 1 ELSE 0 END) as completed,
  ROUND(100.0 * SUM(CASE WHEN was_completed = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) as adherence_rate
FROM intervention_activities
WHERE module_id = 'mealtime'
  AND user_id = 'test-user-id'
  AND activity_date >= date('now', '-7 days')
GROUP BY module_specific_data->>'meal_type';
```

---

## Notes

**Mealtime Module Uniqueness:**
- First module with "eating window" concept (intermittent fasting support)
- Auto-adjustment based on sleep schedule (dynamic scheduling)
- Time slider shows meals + eating window overlay
- Strong integration with SettingsViewModel (subscribes to sleep schedule changes)

**Auto-Adjustment Implementation:**
- Listen to SettingsViewModel for sleep schedule changes
- Recalculate meal times automatically
- Notify user of changes
- Option to disable auto-adjustment for manual control

**Intermittent Fasting Support:**
- Eating window highlighted on time slider
- Meals spaced evenly within window
- Track adherence to window (eating outside triggers warning)
- Common windows: 16:8 (8h eating), 18:6 (6h eating), 20:4 (4h eating)

**Integration with Nutrition Module:**
- Mealtime: When to eat (timing)
- Nutrition: What to eat (content)
- Complementary modules, often used together

**Notification Strategy:**
- Meal reminders 15 min before scheduled time
- Per-meal notification override
- Module-level notification control

**Estimated Time:** 12-14 hours
- Database migration: 30 minutes
- Models (Config + Activity + Schedule): 90 minutes
- Color scheme for time slider: 60 minutes
- Repository + Datasource: 90 minutes
- ViewModel with auto-adjustment: 120 minutes
- Configuration screen with time slider: 150 minutes
- Meal logging screen: 90 minutes
- Auto-adjustment listener: 60 minutes
- Testing: 90 minutes
