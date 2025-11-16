# Temperature Module - Implementation Plan

## Overview
Implement the Temperature Exposure module to guide users in using cold and heat strategically for sleep enhancement. Temperature timing has significant effects on alertness (cold in morning) and sleep readiness (heat in evening).

**Core Principle:** Temperature exposure at the right time influences circadian rhythm and sleep quality. Cold exposure in morning increases alertness; heat exposure in evening promotes relaxation and sleep onset through subsequent body cooling.

## Prerequisites
- ✅ **Light & Sport modules completed:** Pattern established
- ✅ **Shared components:** TimeSliderWidget available
- 📚 **Read:** TEMPERATURE_README.md

## Goals
- Implement dual-type intervention (cold vs heat with different optimal times)
- Create context-sensitive time slider (green zones different for cold vs heat)
- Add safety validation (duration limits, contraindication warnings)
- Track temperature intensity and method
- **Expected outcome:** Temperature module with smart timing guidance

---

## Step T.1: Database Migration

**File:** `lib/core/database/migrations/migration_v7.dart`

**SQL Migration:**
```sql
-- Index for temperature module
CREATE INDEX IF NOT EXISTS idx_intervention_activities_temperature
ON intervention_activities(user_id, module_id, activity_date)
WHERE module_id = 'temperature';

-- Validate temperature type and duration
CREATE TRIGGER IF NOT EXISTS validate_temperature_activity
BEFORE INSERT ON intervention_activities
WHEN NEW.module_id = 'temperature'
BEGIN
  -- Temperature type must be 'cold' or 'heat'
  SELECT RAISE(ABORT, 'Temperature type must be cold or heat')
  WHERE json_extract(NEW.module_specific_data, '$.temperature_type') NOT IN ('cold', 'heat');

  -- Duration limits: cold 2-20 min, heat 10-60 min
  SELECT RAISE(ABORT, 'Cold exposure: 2-20 minutes, Heat exposure: 10-60 minutes')
  WHERE (
    (json_extract(NEW.module_specific_data, '$.temperature_type') = 'cold' AND NEW.duration_minutes NOT BETWEEN 2 AND 20)
    OR
    (json_extract(NEW.module_specific_data, '$.temperature_type') = 'heat' AND NEW.duration_minutes NOT BETWEEN 10 AND 60)
  );
END;
```

**Why:** Enforces safety constraints at database level

---

## Step T.2: Temperature Configuration Model

**File:** `lib/modules/temperature/domain/models/temperature_config.dart`

**Class: TemperatureConfig**

**Fields:**
```dart
class TemperatureConfig {
  // Standard mode: Morning cold shower
  final String targetTime;              // HH:mm
  final int targetDurationMinutes;      // Default: 5 (cold)
  final String temperatureType;         // 'cold' or 'heat'
  final String method;                  // 'shower', 'ice_bath', 'sauna', 'hot_bath', etc.

  // Advanced mode: Both cold and heat sessions
  final List<TemperatureSession> sessions;

  // Safety settings
  final bool showSafetyWarnings;        // Default: true
  final List<String> contraindications; // User-reported conditions

  // Notification settings
  final bool sessionReminderEnabled;
  final int reminderMinutesBefore;

  final String mode;                    // 'standard' or 'advanced'
}

class TemperatureSession {
  final String id;
  final String sessionTime;
  final int durationMinutes;
  final String temperatureType;         // 'cold' or 'heat'
  final String method;
  final String intensity;               // 'mild', 'moderate', 'intense'
  final bool isEnabled;
}
```

**Static Defaults:**
```dart
static TemperatureConfig get standardDefault => TemperatureConfig(
  targetTime: '07:30',
  targetDurationMinutes: 5,
  temperatureType: 'cold',
  method: 'shower',
  mode: 'standard',
  showSafetyWarnings: true,
  contraindications: [],
);

static TemperatureConfig get advancedDefault {
  // Morning cold + evening heat
  return TemperatureConfig(
    sessions: [
      TemperatureSession(
        sessionTime: '07:30',
        temperatureType: 'cold',
        method: 'shower',
        durationMinutes: 5,
      ),
      TemperatureSession(
        sessionTime: '19:00',  // 2-4 hours before bed
        temperatureType: 'heat',
        method: 'hot_bath',
        durationMinutes: 20,
      ),
    ],
    mode: 'advanced',
  );
}
```

---

## Step T.3: Temperature Activity Model

**File:** `lib/modules/temperature/domain/models/temperature_activity.dart`

**Class: TemperatureActivity extends InterventionActivity**

**Module-Specific Data (JSON):**
```dart
{
  'temperature_type': 'cold' | 'heat',
  'method': 'shower' | 'ice_bath' | 'cold_plunge' | 'sauna' | 'hot_bath' | 'hot_tub',
  'temperature_celsius': double?,       // Actual temperature if measured
  'subjective_intensity': 'mild' | 'moderate' | 'intense',
  'location': 'home' | 'gym' | 'spa' | 'outdoor',
  'adverse_effects': string?,           // Dizziness, discomfort, etc.
}
```

**Getters:**
```dart
String get temperatureType => moduleSpecificData?['temperature_type'] ?? 'unknown';
String get method => moduleSpecificData?['method'] ?? 'unknown';
double? get temperatureCelsius => moduleSpecificData?['temperature_celsius'];
String? get adverseEffects => moduleSpecificData?['adverse_effects'];
bool get isCold => temperatureType == 'cold';
bool get isHeat => temperatureType == 'heat';
```

---

## Step T.4: Color Scheme Helper for Temperature

**File:** `lib/modules/temperature/presentation/utils/temperature_color_scheme.dart`

**Class: TemperatureColorScheme**

**Purpose:** Calculate color feedback based on temperature type and time

**Method:**
```dart
Color getColorForTime(TimeOfDay time, String temperatureType, TimeOfDay bedTime, TimeOfDay wakeTime) {
  final hoursSinceMorning = _calculateHoursSince(wakeTime, time);
  final hoursBeforeBed = _calculateHoursBefore(time, bedTime);

  if (temperatureType == 'cold') {
    // Cold: Green in morning, yellow midday, orange/red evening
    if (hoursSinceMorning < 3) return Colors.green[700]!;      // 0-3h after wake: optimal
    if (hoursSinceMorning < 6) return Colors.lightGreen;       // 3-6h: good
    if (hoursSinceMorning < 10) return Colors.yellow;          // 6-10h: neutral
    if (hoursBeforeBed > 4) return Colors.orange;              // >4h before bed: suboptimal
    return Colors.red;                                          // <4h before bed: bad

  } else { // heat
    // Heat: Red/orange in morning, yellow midday, green evening (2-4h before bed)
    if (hoursBeforeBed >= 2 && hoursBeforeBed <= 4) {
      return Colors.green[700]!;                                // 2-4h before bed: optimal
    }
    if (hoursBeforeBed >= 4 && hoursBeforeBed <= 6) {
      return Colors.lightGreen;                                 // 4-6h: good
    }
    if (hoursSinceMorning < 4) return Colors.red;              // Morning: bad
    if (hoursSinceMorning < 8) return Colors.orange;           // Late morning: suboptimal
    return Colors.yellow;                                       // Midday: neutral
  }
}
```

**Why:** Context-sensitive feedback - same time has different colors for cold vs heat

---

## Step T.5: Temperature Repository Interface

**File:** `lib/modules/temperature/domain/repositories/temperature_repository.dart`

**Import & Interface:**
```dart
import '../../../shared/domain/repositories/intervention_repository.dart';
import '../models/temperature_activity.dart';

/// Temperature repository interface
/// Extends InterventionRepository with dual-type (cold/heat) operations
abstract class TemperatureRepository extends InterventionRepository {
  // Temperature-specific methods only
  Future<Map<String, int>> getTypeDistribution(String userId, DateTime start, DateTime end);
  Future<List<InterventionActivity>> getActivitiesByType(String userId, String temperatureType, DateTime start, DateTime end);
}
```

**Inherited from base:** `getUserConfig`, `saveConfig`, `getActivitiesForDate`, `getActivitiesBetween`, `logActivity`, `updateActivity`, `deleteActivity`, `getCompletionCount`, `getCompletionRate`

---

## Step T.6: Temperature ViewModel with Safety Checks

**File:** `lib/modules/temperature/presentation/viewmodels/temperature_module_viewmodel.dart`

**Class: TemperatureModuleViewModel extends ChangeNotifier**

**Additional Safety Methods:**
```dart
/// Check if user has contraindications
bool hasSafetyWarnings() {
  if (_temperatureConfig == null) return false;
  return _temperatureConfig!.contraindications.isNotEmpty;
}

/// Validate session duration based on type
String? validateDuration(String temperatureType, int durationMinutes) {
  if (temperatureType == 'cold') {
    if (durationMinutes < 2) return 'Cold exposure: minimum 2 minutes';
    if (durationMinutes > 20) return 'Cold exposure: maximum 20 minutes for safety';
  } else {
    if (durationMinutes < 10) return 'Heat exposure: minimum 10 minutes for effect';
    if (durationMinutes > 60) return 'Heat exposure: maximum 60 minutes for safety';
  }
  return null; // Valid
}

/// Show safety warning dialog data
Map<String, dynamic> getSafetyWarning(String temperatureType) {
  if (temperatureType == 'cold') {
    return {
      'title': 'Cold Exposure Safety',
      'warnings': [
        'Start gradually - 30 seconds cold, then increase',
        'Stop if you feel dizzy or uncomfortable',
        'Not recommended for: cardiovascular disease, Raynaud\'s syndrome, pregnancy',
        'Consult doctor if you have any health concerns',
      ],
    };
  } else {
    return {
      'title': 'Heat Exposure Safety',
      'warnings': [
        'Stay hydrated before and after',
        'Stop if you feel faint or nauseous',
        'Not recommended for: pregnancy, heart conditions, low blood pressure',
        'Cool down gradually after session',
      ],
    };
  }
}
```

---

## Step T.6: Temperature Configuration Screen

**File:** `lib/modules/temperature/presentation/screens/temperature_config_screen.dart`

**UI Components:**

**Type Selector with Safety Warning:**
```dart
// Temperature type selector
SegmentedButton<String>(
  segments: [
    ButtonSegment(
      value: 'cold',
      label: Text('Cold'),
      icon: Icon(Icons.ac_unit),
    ),
    ButtonSegment(
      value: 'heat',
      label: Text('Heat'),
      icon: Icon(Icons.local_fire_department),
    ),
  ],
  selected: {_selectedType},
  onSelectionChanged: (Set<String> newSelection) {
    setState(() {
      _selectedType = newSelection.first;
    });

    // Show safety warning on first selection
    if (config.showSafetyWarnings) {
      _showSafetyDialog(newSelection.first);
    }
  },
),
```

**Time Slider with Type-Sensitive Colors:**
```dart
TimeSliderWidget(
  sessions: config.sessions.map((s) => TimeMarker(
    time: s.sessionTime,
    label: '${s.temperatureType} - ${s.method}',
    icon: s.temperatureType == 'cold' ? Icons.ac_unit : Icons.local_fire_department,
  )).toList(),
  sleepWindow: SleepWindow(
    bedTime: settingsViewModel.currentUser?.targetBedTime,
    wakeTime: settingsViewModel.currentUser?.targetWakeTime,
  ),
  colorSchemeCalculator: (time, marker) {
    final session = _findSession(marker);
    return TemperatureColorScheme().getColorForTime(
      time,
      session.temperatureType,
      bedTime,
      wakeTime,
    );
  },
  onTimeChanged: (marker, newTime) {
    // Update session time
  },
)
```

**Contraindication Checklist:**
```dart
ExpansionTile(
  title: Text('Safety Checklist'),
  subtitle: Text('Select any conditions that apply to you'),
  children: [
    CheckboxListTile(
      title: Text('Cardiovascular disease'),
      value: config.contraindications.contains('cardiovascular'),
      onChanged: (value) {
        _toggleContraindication('cardiovascular');
      },
    ),
    CheckboxListTile(
      title: Text('Pregnancy'),
      value: config.contraindications.contains('pregnancy'),
      onChanged: (value) {
        _toggleContraindication('pregnancy');
      },
    ),
    CheckboxListTile(
      title: Text('Raynaud\'s syndrome'),
      value: config.contraindications.contains('raynauds'),
      onChanged: (value) {
        _toggleContraindication('raynauds');
      },
    ),
    // ... more conditions
  ],
),
```

---

## Testing Checklist

### Manual Tests:
- [ ] Select cold exposure, verify morning time slider shows green
- [ ] Select heat exposure for same time, verify shows red/orange
- [ ] Change heat exposure to evening (2h before bed), verify green
- [ ] Try to set cold shower duration to 25 minutes, see validation error
- [ ] Try to set heat sauna duration to 5 minutes, see validation error
- [ ] Enable safety warnings, verify dialog appears on first use
- [ ] Check contraindications, verify saved to config
- [ ] Log activity with adverse effects note

### Color Scheme Tests:
- [ ] Cold at 7 AM (wake 7 AM): Dark green (optimal)
- [ ] Cold at 9 PM (bed 10 PM): Red (bad)
- [ ] Heat at 8 PM (bed 10 PM): Green (optimal: 2h before bed)
- [ ] Heat at 7 AM (wake 7 AM): Red (bad)

### Database Tests:
```sql
-- Check temperature activities by type
SELECT
  activity_date,
  time_of_day,
  module_specific_data->>'temperature_type' as type,
  module_specific_data->>'method' as method,
  duration_minutes,
  was_completed
FROM intervention_activities
WHERE module_id = 'temperature'
ORDER BY activity_date DESC;

-- Correlation: Morning cold vs sleep quality
SELECT
  ia.activity_date,
  ia.module_specific_data->>'temperature_type' as temp_type,
  sr.deep_sleep_duration,
  sr.total_sleep_time
FROM intervention_activities ia
JOIN sleep_records sr ON sr.user_id = ia.user_id AND sr.sleep_date = ia.activity_date
WHERE ia.module_id = 'temperature'
ORDER BY ia.activity_date DESC;
```

---

## Notes

**Temperature Module Uniqueness:**
- First module with dual-type intervention (cold vs heat)
- Context-sensitive time slider (same time, different colors based on type)
- Strong emphasis on safety (contraindications, duration limits)
- Database-level validation of type and duration

**Color Scheme Complexity:**
- Cold: Morning optimal, evening bad
- Heat: Evening (2-4h before bed) optimal, morning bad
- Opposite patterns require smart UI feedback

**Safety Implementation:**
- Contraindication checklist saved to user config
- Duration validation in ViewModel and database trigger
- First-use safety dialogs (dismissible)
- Adverse effects tracking for future warnings

**Estimated Time:** 12-14 hours
- Database migration with triggers: 45 minutes
- Models with dual-type support: 90 minutes
- Color scheme calculator: 90 minutes
- Repository + Datasource: 90 minutes
- ViewModel with safety validation: 120 minutes
- Configuration screen with type-sensitive slider: 150 minutes
- Safety UI (dialogs, checklist): 90 minutes
- Testing: 90 minutes
