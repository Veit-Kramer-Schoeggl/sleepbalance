# Light Module - Implementation Plan

## Overview
Implement the Light Therapy module as the first complete intervention module. This module helps users optimize light exposure throughout the day to support healthy circadian rhythms and improve sleep quality. Proper light timing is one of the most powerful tools for regulating the sleep-wake cycle.

**Core Principle:** Light is the primary regulator of circadian rhythm. Bright light in the morning advances the sleep-wake cycle and promotes alertness, while avoiding bright light in the evening supports natural melatonin production.

## Prerequisites
- ✅ **Phase 1-5 completed:** Full MVVM + Provider setup working
- ✅ **Phase 5 patterns:** SettingsViewModel, error handling, current user access
- ✅ **Database:** `intervention_activities` and `user_module_configurations` tables exist
- ✅ **Shared infrastructure:** Base models defined in Phase 6
- 📚 **Read:** LIGHT_README.md for feature requirements
- 📚 **Read:** SHARED_README.md for common patterns

## Goals
- Create Light module data models with proper constraints
- Implement Light repository following established patterns
- Build Light ViewModel with Phase 5 error handling
- Create Standard mode configuration screen (single morning session)
- Create Advanced mode configuration screen (multiple sessions, time slider)
- Integrate notification scheduling
- Enable activity tracking
- **Expected outcome:** Light module fully functional, pattern for other modules established

---

## Step L.1: Database Migration - Light Module Tables

**File:** `lib/core/database/migrations/migration_v5.dart`
**Purpose:** Add Light module-specific constraints and indexes
**Dependencies:** migration_v4 (user and intervention tables)

**CRITICAL:** Create this migration BEFORE creating models!

**Add to file header:**
```dart
// ignore_for_file: constant_identifier_names
/// Migration V5: Light module optimization
///
/// Adds indexes and constraints for light intervention tracking
library;
```

**SQL Migration:**
```sql
-- Add indexes for light module queries
CREATE INDEX IF NOT EXISTS idx_intervention_activities_light
ON intervention_activities(user_id, module_id, activity_date)
WHERE module_id = 'light';

-- Add check constraint for light types in module_specific_data
-- (This is a documentation constraint - SQLite has limited constraint support)

-- Add trigger to validate light activity completion
CREATE TRIGGER IF NOT EXISTS validate_light_completion
BEFORE INSERT ON intervention_activities
WHEN NEW.module_id = 'light'
BEGIN
  SELECT RAISE(ABORT, 'Light duration must be 5-120 minutes')
  WHERE NEW.duration_minutes NOT BETWEEN 5 AND 120;
END;
```

**Update `database_helper.dart`:**
- Increment `DATABASE_VERSION` to 5
- Add MIGRATION_V5 to onCreate
- Add case 5 to onUpgrade

**Why:** Optimizes queries, enforces data integrity constraints specific to Light module

---

## Step L.2: Create Light Configuration Model

**File:** `lib/modules/light/domain/models/light_config.dart`
**Purpose:** Structured configuration stored in `user_module_configurations.configuration` JSON
**Dependencies:** None (plain Dart class)

**Class: LightConfig**

**Fields:**
```dart
class LightConfig {
  // Standard mode settings
  final String targetTime;              // HH:mm format (e.g., '07:30')
  final int targetDurationMinutes;      // Default: 30, range: 15-60
  final String lightType;               // 'natural_sunlight', 'light_box', 'blue_light', 'red_light'

  // Advanced mode settings
  final List<LightSession> sessions;    // Multiple sessions per day (advanced mode only)

  // Notification settings (module-level override)
  final bool morningReminderEnabled;    // Default: true
  final String morningReminderTime;     // HH:mm
  final bool eveningDimReminderEnabled; // Default: true
  final String eveningDimTime;          // HH:mm (e.g., '20:00')
  final bool blueBlockerReminderEnabled;// Default: true
  final String blueBlockerTime;         // HH:mm (e.g., '21:00')

  // Mode flag
  final String mode;                    // 'standard' or 'advanced'
}

class LightSession {
  final String id;                      // UUID
  final String sessionTime;             // HH:mm
  final int durationMinutes;            // 5-120
  final String lightType;               // Type for this session
  final bool isEnabled;                 // Can disable individual sessions
}
```

**Methods:**
- Constructor with default values
- `factory LightConfig.fromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()`
- `LightConfig copyWith({...})`
- **Static:**
  - `static LightConfig get standardDefault` - Morning light, 30 min
  - `static LightConfig get advancedDefault` - Morning + evening red light

**Validation:**
```dart
String? validate() {
  if (targetDurationMinutes < 5 || targetDurationMinutes > 120) {
    return 'Duration must be between 5 and 120 minutes';
  }
  // ... more validation
  return null; // null = valid
}
```

**Why:** Type-safe configuration, easy to serialize/deserialize

---

## Step L.3: Create Light Activity Model

**File:** `lib/modules/light/domain/models/light_activity.dart`
**Purpose:** Extends InterventionActivity with Light-specific helpers
**Dependencies:** `intervention_activity` (from shared)

**Class: LightActivity extends InterventionActivity**

**Module-Specific Data (stored in JSON):**
- `light_type`: String - Type of light used
- `location`: String? - Where session occurred
- `weather`: String? - For natural sunlight tracking
- `device_used`: String? - Light box model, etc.

**Constructor:**
```dart
LightActivity({
  required super.id,
  required super.userId,
  required super.activityDate,
  required super.wasCompleted,
  super.completedAt,
  super.durationMinutes,
  super.timeOfDay,
  super.intensity,
  super.notes,
  super.createdAt,
  String? lightType,
  String? location,
  String? weather,
  String? deviceUsed,
}) : super(
  moduleId: 'light',
  moduleSpecificData: {
    if (lightType != null) 'light_type': lightType,
    if (location != null) 'location': location,
    if (weather != null) 'weather': weather,
    if (deviceUsed != null) 'device_used': deviceUsed,
  },
);
```

**Getters:**
```dart
String? get lightType => moduleSpecificData?['light_type'];
String? get location => moduleSpecificData?['location'];
String? get weather => moduleSpecificData?['weather'];
String? get deviceUsed => moduleSpecificData?['device_used'];
```

**Methods:**
- `factory LightActivity.fromJson(Map<String, dynamic> json)` - Calls super
- `Map<String, dynamic> toJson()` - Override to ensure moduleId = 'light'
- `factory LightActivity.fromDatabase(Map<String, dynamic> map)` - Use DatabaseDateUtils
- `Map<String, dynamic> toDatabase()` - Use DatabaseDateUtils

**Why:** Type-safe access to Light-specific data while using shared base class

---

## Step L.4: Create Light Repository Interface

**File:** `lib/modules/light/domain/repositories/light_module_repository.dart`
**Purpose:** Abstract interface for Light module data operations
**Dependencies:** Models, `user_module_config` (shared)

**Abstract Class: LightModuleRepository**

**Methods:**
```dart
abstract class LightModuleRepository {
  // Configuration management
  Future<UserModuleConfig?> getUserConfig(String userId);
  Future<void> saveConfig(UserModuleConfig config);
  Future<bool> isModuleEnabled(String userId);
  Future<void> enableModule(String userId, LightConfig defaultConfig);
  Future<void> disableModule(String userId);

  // Activity tracking
  Future<List<LightActivity>> getActivitiesForDate(String userId, DateTime date);
  Future<List<LightActivity>> getActivitiesBetween(String userId, DateTime start, DateTime end);
  Future<void> logActivity(LightActivity activity);
  Future<void> updateActivity(LightActivity activity);
  Future<void> deleteActivity(String activityId);

  // Analytics
  Future<int> getCompletionCount(String userId, DateTime start, DateTime end);
  Future<double> getCompletionRate(String userId, DateTime start, DateTime end);
  Future<Map<String, int>> getLightTypeDistribution(String userId, DateTime start, DateTime end);
}
```

**Why:** Clean abstraction enabling testing and future data source changes

---

## Step L.5: Create Light Data Source

**File:** `lib/modules/light/data/datasources/light_module_local_datasource.dart`
**Purpose:** SQLite operations for Light module
**Dependencies:** `sqflite`, `database_helper`, `database_constants`, models

**Class: LightModuleLocalDataSource**

**Constructor:**
```dart
LightModuleLocalDataSource({required Database database})
```

**Methods:**

**Config Operations:**
```dart
Future<UserModuleConfig?> getConfigForUser(String userId) async {
  final results = await _database.query(
    TABLE_USER_MODULE_CONFIGURATIONS,
    where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_MODULE_ID = ?',
    whereArgs: [userId, 'light'],
  );

  if (results.isEmpty) return null;

  return UserModuleConfig.fromDatabase(results.first);
}

Future<void> upsertConfig(UserModuleConfig config) async {
  await _database.insert(
    TABLE_USER_MODULE_CONFIGURATIONS,
    config.toDatabase(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

**Activity Operations:**
```dart
Future<List<LightActivity>> getActivitiesByDate(String userId, DateTime date) async {
  final dateStr = DatabaseDateUtils.toIso8601String(date);

  final results = await _database.query(
    TABLE_INTERVENTION_ACTIVITIES,
    where: '$INTERVENTION_ACTIVITIES_USER_ID = ? AND $INTERVENTION_ACTIVITIES_MODULE_ID = ? AND $INTERVENTION_ACTIVITIES_ACTIVITY_DATE = ?',
    whereArgs: [userId, 'light', dateStr],
    orderBy: '$INTERVENTION_ACTIVITIES_CREATED_AT DESC',
  );

  return results.map((map) => LightActivity.fromDatabase(map)).toList();
}

Future<void> insertActivity(LightActivity activity) async {
  await _database.insert(
    TABLE_INTERVENTION_ACTIVITIES,
    activity.toDatabase(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

**Analytics Operations:**
```dart
Future<int> getCompletionCountBetween(String userId, DateTime start, DateTime end) async {
  final startStr = DatabaseDateUtils.toIso8601String(start);
  final endStr = DatabaseDateUtils.toIso8601String(end);

  final result = await _database.rawQuery('''
    SELECT COUNT(*) as count
    FROM $TABLE_INTERVENTION_ACTIVITIES
    WHERE $INTERVENTION_ACTIVITIES_USER_ID = ?
      AND $INTERVENTION_ACTIVITIES_MODULE_ID = 'light'
      AND $INTERVENTION_ACTIVITIES_WAS_COMPLETED = 1
      AND $INTERVENTION_ACTIVITIES_ACTIVITY_DATE BETWEEN ? AND ?
  ''', [userId, startStr, endStr]);

  return Sqflite.firstIntValue(result) ?? 0;
}
```

**Pattern:** See `ActionLocalDataSource` and `SleepRecordLocalDataSource` for reference

---

## Step L.6: Implement Light Repository

**File:** `lib/modules/light/data/repositories/light_module_repository_impl.dart`
**Purpose:** Concrete implementation delegating to datasource
**Dependencies:** Repository interface, datasource

**Class: LightModuleRepositoryImpl implements LightModuleRepository**

**Implementation:**
```dart
class LightModuleRepositoryImpl implements LightModuleRepository {
  final LightModuleLocalDataSource _dataSource;

  LightModuleRepositoryImpl({required LightModuleLocalDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<UserModuleConfig?> getUserConfig(String userId) async {
    return await _dataSource.getConfigForUser(userId);
  }

  // ... all other methods delegate to _dataSource
}
```

**Why:** Clean separation of interface and implementation

---

## Step L.7: Create Light ViewModel

**File:** `lib/modules/light/presentation/viewmodels/light_module_viewmodel.dart`
**Purpose:** Manage Light module state, handle configuration, track activities
**Dependencies:** `provider`, repository, models

**Class: LightModuleViewModel extends ChangeNotifier**

**Fields:**
```dart
final LightModuleRepository _repository;
UserModuleConfig? _config;
LightConfig? _lightConfig;
List<LightActivity> _activities = [];
bool _isEnabled = false;
bool _isLoading = false;
String? _errorMessage;
```

**✅ CRITICAL - Follow Phase 5 Error Handling Pattern:**
```dart
Future<void> loadConfig(String userId) async {
  try {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _config = await _repository.getUserConfig(userId);

    if (_config != null) {
      _lightConfig = LightConfig.fromJson(_config!.configuration);
      _isEnabled = _config!.isEnabled;
    } else {
      _lightConfig = LightConfig.standardDefault;
      _isEnabled = false;
    }

  } catch (e) {
    _errorMessage = 'Failed to load configuration: $e';
    debugPrint('LightModuleViewModel: Error in loadConfig: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**All Methods Use Same Pattern:**
- `Future<void> saveConfig(String userId, LightConfig newConfig)`
- `Future<void> loadActivities(String userId, DateTime date)`
- `Future<void> logActivity(String userId, LightActivity activity)`
- `Future<void> toggleModule(String userId)`
- `Future<void> scheduleNotifications(String userId, LightConfig config)`
- `Future<void> cancelNotifications()`

**Notification Scheduling:**
```dart
Future<void> scheduleNotifications(String userId, LightConfig config) async {
  // Cancel existing notifications first
  await cancelNotifications();

  if (!_isEnabled) return;

  // Schedule morning reminder
  if (config.morningReminderEnabled) {
    await _notificationService.scheduleNotification(
      id: 'light_morning',
      title: 'Light Therapy Reminder',
      body: 'Time for your morning bright light session!',
      scheduledTime: _parseTimeOfDay(config.morningReminderTime),
    );
  }

  // Schedule evening dim reminder
  if (config.eveningDimReminderEnabled) {
    await _notificationService.scheduleNotification(
      id: 'light_evening_dim',
      title: 'Dim Lights Reminder',
      body: 'Start dimming lights to support melatonin production',
      scheduledTime: _parseTimeOfDay(config.eveningDimTime),
    );
  }

  // Schedule blue blocker reminder
  if (config.blueBlockerReminderEnabled) {
    await _notificationService.scheduleNotification(
      id: 'light_blue_blocker',
      title: 'Blue Blocker Reminder',
      body: 'Put on blue blocking glasses',
      scheduledTime: _parseTimeOfDay(config.blueBlockerTime),
    );
  }
}
```

**Reference:** See `SettingsViewModel` for identical error handling pattern

---

## Step L.8: Create Light Configuration Screen - Standard Mode

**File:** `lib/modules/light/presentation/screens/light_config_standard_screen.dart`
**Purpose:** Simple configuration UI for single morning light session
**Dependencies:** `provider`, ViewModel, models, widgets

**Class: LightConfigStandardScreen extends StatefulWidget**

**✅ Get Current User ID (Phase 5 Pattern):**
```dart
@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final settingsViewModel = context.read<SettingsViewModel>();
    final userId = settingsViewModel.currentUser?.id;

    if (userId != null) {
      final lightViewModel = context.read<LightModuleViewModel>();
      lightViewModel.loadConfig(userId);
    } else {
      debugPrint('Warning: No current user found in Light Config');
    }
  });
}
```

**Build Method:**
```dart
@override
Widget build(BuildContext context) {
  final viewModel = context.watch<LightModuleViewModel>();
  final settingsViewModel = context.watch<SettingsViewModel>();
  final userId = settingsViewModel.currentUser?.id;
  final config = viewModel.lightConfig ?? LightConfig.standardDefault;

  // Handle loading/error states
  if (viewModel.isLoading) {
    return Scaffold(
      appBar: AppBar(title: Text('Light Therapy')),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  if (viewModel.errorMessage != null) {
    return Scaffold(
      appBar: AppBar(title: Text('Light Therapy')),
      body: Center(child: Text('Error: ${viewModel.errorMessage}')),
    );
  }

  if (userId == null) {
    return Scaffold(
      appBar: AppBar(title: Text('Light Therapy')),
      body: Center(child: Text('No user logged in')),
    );
  }

  // Main configuration form
  return BackgroundWrapper(
    imagePath: 'assets/images/main_background.png',
    overlayOpacity: 0.3,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Light Therapy - Standard'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Module Enable/Disable
            SwitchListTile(
              title: Text('Enable Light Therapy'),
              subtitle: Text('Get morning light for better sleep'),
              value: viewModel.isEnabled,
              onChanged: (value) => viewModel.toggleModule(userId),
            ),

            if (viewModel.isEnabled) ...[
              SizedBox(height: 24),

              // Target Time
              ListTile(
                title: Text('Morning Light Time'),
                subtitle: Text(config.targetTime),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _parseTime(config.targetTime),
                  );
                  if (time != null) {
                    final newConfig = config.copyWith(
                      targetTime: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    );
                    viewModel.saveConfig(userId, newConfig);
                  }
                },
              ),

              // Duration
              ListTile(
                title: Text('Duration'),
                subtitle: Text('${config.targetDurationMinutes} minutes'),
              ),
              Slider(
                value: config.targetDurationMinutes.toDouble(),
                min: 15,
                max: 60,
                divisions: 9,
                label: '${config.targetDurationMinutes} min',
                onChanged: (value) {
                  final newConfig = config.copyWith(
                    targetDurationMinutes: value.toInt(),
                  );
                  viewModel.saveConfig(userId, newConfig);
                },
              ),

              // Light Type
              ListTile(
                title: Text('Light Type'),
                subtitle: Text(_getLightTypeDisplay(config.lightType)),
              ),
              DropdownButton<String>(
                value: config.lightType,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'natural_sunlight', child: Text('Natural Sunlight')),
                  DropdownMenuItem(value: 'light_box', child: Text('Light Box (10,000 lux)')),
                  DropdownMenuItem(value: 'blue_light', child: Text('Blue Light Therapy')),
                  DropdownMenuItem(value: 'red_light', child: Text('Red Light (evening)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    final newConfig = config.copyWith(lightType: value);
                    viewModel.saveConfig(userId, newConfig);
                  }
                },
              ),

              SizedBox(height: 24),
              Text('Notifications', style: Theme.of(context).textTheme.titleMedium),

              // Morning Reminder
              SwitchListTile(
                title: Text('Morning Reminder'),
                subtitle: Text('at ${config.morningReminderTime}'),
                value: config.morningReminderEnabled,
                onChanged: (value) {
                  final newConfig = config.copyWith(
                    morningReminderEnabled: value,
                  );
                  viewModel.saveConfig(userId, newConfig);
                },
              ),

              // Advanced Mode Link
              SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: viewModel,
                        child: LightConfigAdvancedScreen(),
                      ),
                    ),
                  );
                },
                child: Text('Switch to Advanced Mode'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
```

**Reference:** See `ActionScreen` for complete ViewModel consumption example

---

## Step L.9: Register Light Module Providers

**File:** `lib/main.dart`
**Purpose:** Add Light module to Provider tree
**Action:** Add to providers list

**✅ Provider Registration Order (Phase 5):**
Services → DataSources → Repositories → ViewModels

**Add AFTER SettingsViewModel:**
```dart
// ============================================================================
// Light Module - Intervention System
// ============================================================================

// DataSource layer - database access
Provider<LightModuleLocalDataSource>(
  create: (context) => LightModuleLocalDataSource(
    database: context.read<DatabaseHelper>().database,
  ),
),

// Repository layer - abstracts data access
Provider<LightModuleRepository>(
  create: (context) => LightModuleRepositoryImpl(
    dataSource: context.read<LightModuleLocalDataSource>(),
  ),
),

// ViewModel layer - state management
// Registered globally for easy access across screens
ChangeNotifierProvider<LightModuleViewModel>(
  create: (context) => LightModuleViewModel(
    repository: context.read<LightModuleRepository>(),
  ),
),
```

---

## Testing Checklist

### Manual Tests:
- [ ] Navigate to Settings → Manage Modules → Light Therapy
- [ ] Toggle module enabled, verify saves to database
- [ ] Set target time, verify persists after app restart
- [ ] Adjust duration slider, verify updates immediately
- [ ] Change light type dropdown, verify saves
- [ ] Enable notifications, check permission requested
- [ ] Wait for notification time, verify notification fires
- [ ] Log activity for today, check database
- [ ] View activity in Night Review (correlation)

### Unit Tests:
- [ ] Test LightConfig fromJson/toJson with all fields
- [ ] Test LightConfig.validate() catches invalid durations
- [ ] Test LightActivity moduleSpecificData parsing
- [ ] Test LightModuleViewModel saveConfig flow
- [ ] Test notification scheduling logic
- [ ] Test repository methods with mock datasource

### Integration Tests:
- [ ] Full workflow: Enable → Configure → Schedule → Log → Correlate
- [ ] Standard to Advanced mode switch preserves settings
- [ ] Disable module cancels notifications

### Database Validation:
```sql
-- Check module config
SELECT * FROM user_module_configurations WHERE module_id = 'light';

-- Check logged activities
SELECT * FROM intervention_activities WHERE module_id = 'light';

-- Check correlation with sleep
SELECT
  ia.activity_date,
  ia.was_completed,
  ia.duration_minutes,
  sr.deep_sleep_duration,
  sr.total_sleep_time
FROM intervention_activities ia
LEFT JOIN sleep_records sr
  ON sr.user_id = ia.user_id
  AND sr.sleep_date = ia.activity_date
WHERE ia.module_id = 'light'
ORDER BY ia.activity_date DESC;
```

---

## Rollback Strategy

- Light module is isolated, can disable without affecting other features
- Remove navigation link from Settings if needed
- Database tables remain, just unused
- Comment out provider registrations to disable

---

## Next Steps

After Light Module Complete:
- **Pattern Established:** Other modules (Sport, Meditation, etc.) follow same structure
- Extract common components to `lib/modules/shared/presentation/widgets/`
- Implement remaining 6 modules using Light as template
- Add correlation analysis service for all modules

---

## Notes

**Why Light Module First?**
- Simplest intervention (just time and duration tracking)
- Clear notifications (morning, evening, blue blocker)
- Easy to track (binary completion + duration)
- No complex calculations or external dependencies
- Establishes pattern for all other modules

**Module Pattern Established:**
1. Database migration with constraints FIRST
2. Domain models: Config + Activity + extensions
3. Repository: Interface + Datasource + Implementation
4. ViewModel: ChangeNotifier with CRUD (Phase 5 error handling!)
5. Screen: Configuration UI (access current user via SettingsViewModel)
6. Provider registration in correct order
7. Testing: Unit, integration, database validation

**Notification System:**
- Uses `core/notifications/` infrastructure from Phase 1
- Module-specific scheduling in ViewModel
- Cancels on disable
- Module-level override respects user preferences

**Correlation with Sleep:**
- `intervention_activities.activity_date` joins with `sleep_records.sleep_date`
- Analysis: Did light therapy on Day N improve sleep on Night N?
- Foundation for advanced correlation analysis in later phases

**Standard vs Advanced Mode:**
- Standard: Single morning session, minimal configuration
- Advanced: Multiple sessions, different light types, time slider
- Easy upgrade path for users
- Shared configuration model supports both

**Estimated Time:** 10-12 hours
- Database migration: 30 minutes
- Models (Config + Activity): 90 minutes
- Repository (Interface + Datasource + Impl): 120 minutes
- ViewModel (with proper error handling): 120 minutes
- Standard mode screen: 90 minutes
- Advanced mode screen: 120 minutes (if implementing)
- Provider registration: 15 minutes
- Notification integration: 60 minutes
- Testing: 90 minutes
