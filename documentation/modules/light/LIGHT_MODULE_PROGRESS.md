# Light Module Implementation Progress

## Phase 2: Build Light Module Inline (NOT extracting shared components yet)

**Goal:** Implement complete Light module with all functionality inline. TimeSlider and ColorScheme logic stay in Light module for validation before extracting to shared in Phase 3.

---

## ✅ COMPLETED (Steps L.1-L.7)

### L.1: Database Migration V6 ✅
**File:** `lib/core/database/migrations/migration_v6.dart`
- Created Light-specific index on intervention_activities
- Added validation triggers for Light duration (5-120 minutes)
- Updated `DATABASE_VERSION` to 6 in `lib/shared/constants/database_constants.dart`
- Registered in `lib/core/database/database_helper.dart` onCreate and onUpgrade
- **Status:** Verified with `flutter analyze` - 0 issues

### L.2: LightConfig Model ✅
**File:** `lib/modules/light/domain/models/light_config.dart`
- LightConfig class with Standard/Advanced modes
- Standard fields: targetTime, targetDurationMinutes, lightType
- Notification fields: morningReminderEnabled/Time, eveningDimEnabled/Time, blueBlockerEnabled/Time
- Advanced fields: List<LightSession> sessions
- Methods: fromJson, toJson, copyWith, validate()
- Factory: standardDefault(), advancedDefault()
- **Status:** Verified - 0 issues

### L.3: LightActivity Model ✅
**File:** `lib/modules/light/domain/models/light_activity.dart`
- Extends InterventionActivity with light-specific data
- moduleSpecificData stores: light_type, location, weather, device_used
- Typed getters: lightType, location, weather, deviceUsed
- Methods: fromInterventionActivity, fromDatabase, fromJson, copyWithLight, getDescription()
- Helpers: isOutdoorSession, usedTherapeuticDevice
- **Status:** Verified - 0 issues

### L.4: LightRepository Interface ✅
**File:** `lib/modules/light/domain/repositories/light_repository.dart`
- Extends InterventionRepository
- Adds: getLightTypeDistribution(userId, startDate, endDate) → Map<String, int>
- Inherits 9 methods from InterventionRepository
- **Status:** Verified - 0 issues

### L.5: LightModuleLocalDataSource ✅
**File:** `lib/modules/light/data/datasources/light_module_local_datasource.dart`
- Configuration ops: getConfigForUser, upsertConfig
- Activity ops: getActivitiesByDate, getActivitiesBetween, insertActivity, updateActivity, deleteActivity
- Analytics ops: getCompletionCountBetween, getCompletionRateBetween, getLightTypeDistribution
- Uses sqflite Database, DatabaseDateUtils, database_constants
- **Status:** Verified - 0 issues

### L.6: LightModuleRepositoryImpl ✅
**File:** `lib/modules/light/data/repositories/light_module_repository_impl.dart`
- Implements LightRepository
- Delegates all 10 methods to LightModuleLocalDataSource
- Clean abstraction layer between domain and data
- **Status:** Verified - 0 issues

### L.7: LightModuleViewModel ✅
**File:** `lib/modules/light/presentation/viewmodels/light_module_viewmodel.dart`
- Extends ChangeNotifier
- State: _config, _lightConfig, _activities, _isEnabled, _isLoading, _errorMessage
- Methods: loadConfig, saveConfig, toggleModule, loadActivities, logActivity, updateActivity, deleteActivity
- Notification methods: scheduleNotifications, cancelNotifications (STUBBED - NotificationService not implemented yet)
- Follows Phase 5 error handling: try/catch/finally with _isLoading and _errorMessage
- Helper: clearError()
- **Status:** Verified - 1 warning (_parseTimeOfDay unused, will be used when notifications implemented)

---

## 🔄 REMAINING TASKS (Steps L.8-L.14)

### L.8: LightConfigStandardScreen UI (NEXT - 90 minutes)
**File:** `lib/modules/light/presentation/screens/light_config_standard_screen.dart`

**What to create:**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleepbalance/modules/light/presentation/viewmodels/light_module_viewmodel.dart';
import 'package:sleepbalance/modules/light/domain/models/light_config.dart';
import 'package:sleepbalance/features/settings/presentation/viewmodels/settings_viewmodel.dart';

class LightConfigStandardScreen extends StatefulWidget {
  const LightConfigStandardScreen({Key? key}) : super(key: key);

  @override
  State<LightConfigStandardScreen> createState() => _LightConfigStandardScreenState();
}

class _LightConfigStandardScreenState extends State<LightConfigStandardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsViewModel = context.read<SettingsViewModel>();
      final userId = settingsViewModel.currentUser?.id;
      if (userId != null) {
        context.read<LightModuleViewModel>().loadConfig(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Light Therapy')),
      body: Consumer<LightModuleViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          final config = viewModel.lightConfig;
          if (config == null) {
            return Center(child: Text('No configuration loaded'));
          }

          return ListView(
            children: [
              // Enable/Disable Switch
              SwitchListTile(
                title: Text('Enable Light Therapy'),
                value: viewModel.isEnabled,
                onChanged: (value) async {
                  final userId = context.read<SettingsViewModel>().currentUser?.id;
                  if (userId != null) {
                    await viewModel.toggleModule(userId);
                  }
                },
              ),

              if (viewModel.isEnabled) ...[
                Divider(),

                // Light Type Dropdown
                ListTile(
                  title: Text('Light Type'),
                  trailing: DropdownButton<String>(
                    value: config.lightType,
                    items: [
                      DropdownMenuItem(value: 'natural_sunlight', child: Text('Natural Sunlight')),
                      DropdownMenuItem(value: 'light_box', child: Text('Light Box (10,000 lux)')),
                      DropdownMenuItem(value: 'blue_light', child: Text('Blue Light Therapy')),
                      DropdownMenuItem(value: 'red_light', child: Text('Red Light Therapy')),
                    ],
                    onChanged: (value) => _updateConfig(lightType: value),
                  ),
                ),

                // Target Time Picker
                ListTile(
                  title: Text('Target Time'),
                  subtitle: Text(config.targetTime ?? '07:30'),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _parseTime(config.targetTime ?? '07:30'),
                    );
                    if (time != null) {
                      _updateConfig(targetTime: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                    }
                  },
                ),

                // Duration Slider
                ListTile(
                  title: Text('Duration: ${config.targetDurationMinutes ?? 30} minutes'),
                  subtitle: Slider(
                    value: (config.targetDurationMinutes ?? 30).toDouble(),
                    min: 15,
                    max: 60,
                    divisions: 9,
                    label: '${config.targetDurationMinutes ?? 30} min',
                    onChanged: (value) => _updateConfig(duration: value.toInt()),
                  ),
                ),

                Divider(),
                ListTile(
                  title: Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
                ),

                // Morning Reminder
                SwitchListTile(
                  title: Text('Morning Reminder'),
                  subtitle: Text(config.morningReminderTime),
                  value: config.morningReminderEnabled,
                  onChanged: (value) => _updateConfig(morningReminderEnabled: value),
                ),

                // Evening Dim Reminder
                SwitchListTile(
                  title: Text('Evening Dim Reminder'),
                  subtitle: Text(config.eveningDimTime),
                  value: config.eveningDimReminderEnabled,
                  onChanged: (value) => _updateConfig(eveningDimEnabled: value),
                ),

                // Blue Blocker Reminder
                SwitchListTile(
                  title: Text('Blue Blocker Reminder'),
                  subtitle: Text(config.blueBlockerTime),
                  value: config.blueBlockerReminderEnabled,
                  onChanged: (value) => _updateConfig(blueBlockerEnabled: value),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _updateConfig({
    String? targetTime,
    int? duration,
    String? lightType,
    bool? morningReminderEnabled,
    bool? eveningDimEnabled,
    bool? blueBlockerEnabled,
  }) async {
    final viewModel = context.read<LightModuleViewModel>();
    final userId = context.read<SettingsViewModel>().currentUser?.id;

    if (viewModel.lightConfig == null || userId == null) return;

    final updatedConfig = viewModel.lightConfig!.copyWith(
      targetTime: targetTime,
      targetDurationMinutes: duration,
      lightType: lightType,
      morningReminderEnabled: morningReminderEnabled,
      eveningDimReminderEnabled: eveningDimEnabled,
      blueBlockerReminderEnabled: blueBlockerEnabled,
    );

    await viewModel.saveConfig(userId, updatedConfig);
  }
}
```

**Create directory first:** `mkdir -p lib/modules/light/presentation/screens`

---

### L.9: TimeSliderWidget (OPTIONAL - Skip for MVP)
**File:** `lib/modules/light/presentation/widgets/time_slider_widget.dart`
**Note:** Only needed for Advanced mode, which is not MVP. Can skip this step.

---

### L.10: Provider Registration (15 minutes)
**File:** `lib/main.dart`

**Add to MultiProvider:**
```dart
// Light Module - DataSource layer
Provider<LightModuleLocalDataSource>(
  create: (context) => LightModuleLocalDataSource(
    database: context.read<DatabaseHelper>().database,
  ),
),

// Light Module - Repository layer
Provider<LightRepository>(
  create: (context) => LightModuleRepositoryImpl(
    dataSource: context.read<LightModuleLocalDataSource>(),
  ),
),

// Light Module - ViewModel layer
ChangeNotifierProvider<LightModuleViewModel>(
  create: (context) => LightModuleViewModel(
    repository: context.read<LightRepository>(),
  ),
),
```

**Add imports:**
```dart
import 'package:sleepbalance/modules/light/data/datasources/light_module_local_datasource.dart';
import 'package:sleepbalance/modules/light/data/repositories/light_module_repository_impl.dart';
import 'package:sleepbalance/modules/light/domain/repositories/light_repository.dart';
import 'package:sleepbalance/modules/light/presentation/viewmodels/light_module_viewmodel.dart';
```

---

### L.11: LightModule Integration (15 minutes)
**File:** `lib/modules/light/domain/light_module.dart`

**Update getConfigurationScreen():**
```dart
import 'package:sleepbalance/modules/light/presentation/screens/light_config_standard_screen.dart';

@override
Widget getConfigurationScreen() {
  return const LightConfigStandardScreen();
}
```

---

### L.12: Unit Tests (60 minutes)

**Create 3 test files:**

1. `test/modules/light/domain/models/light_config_test.dart`
   - Test fromJson/toJson round-trip
   - Test validate() catches invalid durations, times, light types
   - Test standardDefault() creates valid config
   - Test copyWith() creates new instance
   - Test Standard to Advanced mode conversion

2. `test/modules/light/domain/models/light_activity_test.dart`
   - Test fromDatabase/toDatabase round-trip
   - Test moduleSpecificData parsing
   - Test getters (lightType, location, weather, deviceUsed)
   - Test getDescription() output
   - Test isOutdoorSession, usedTherapeuticDevice

3. `test/modules/light/presentation/viewmodels/light_module_viewmodel_test.dart`
   - Mock LightRepository
   - Test loadConfig() loads and parses config
   - Test saveConfig() validates and saves
   - Test toggleModule() changes enabled state
   - Test logActivity() inserts and refreshes
   - Test error handling sets errorMessage

**Run after creation:**
```bash
flutter test test/modules/light/
```

---

### L.13: Integration Tests (30 minutes)

**Create:** `test/modules/light/integration/light_module_integration_test.dart`

**Tests:**
1. Full workflow: Enable → Configure → Log activity → Verify database
2. Configuration persistence: Save → Reload → Verify identical
3. Activity tracking: Log → Query by date → Verify moduleSpecificData

**Run after creation:**
```bash
flutter test test/modules/light/integration/
```

---

### L.14: Manual Testing (60 minutes)

**Checklist:**
1. [ ] Run app: `flutter run`
2. [ ] Navigate: Settings → Light Therapy
3. [ ] Toggle module enabled/disabled
4. [ ] Set target time with time picker
5. [ ] Adjust duration slider (15-60 minutes)
6. [ ] Change light type dropdown
7. [ ] Toggle notification switches
8. [ ] Restart app, verify configuration persists
9. [ ] Run analyzer: `flutter analyze lib/modules/light/`
   - Expected: 0 errors, 1 warning (_parseTimeOfDay unused - OK)
10. [ ] Check database:
    ```sql
    SELECT * FROM user_module_configurations WHERE module_id = 'light';
    SELECT configuration FROM user_module_configurations WHERE module_id = 'light';
    ```
11. [ ] Verify JSON structure in configuration column

---

## Key Files Already Completed

```
lib/modules/light/
├── domain/
│   ├── models/
│   │   ├── light_config.dart ✅
│   │   └── light_activity.dart ✅
│   ├── repositories/
│   │   └── light_repository.dart ✅
│   └── light_module.dart (exists, needs update in L.11)
├── data/
│   ├── datasources/
│   │   └── light_module_local_datasource.dart ✅
│   └── repositories/
│       └── light_module_repository_impl.dart ✅
└── presentation/
    └── viewmodels/
        └── light_module_viewmodel.dart ✅
```



## Notes

1. **Notifications:** NotificationService not yet implemented. Methods are stubbed in ViewModel with TODOs. Can implement later.

2. **Advanced Mode:** TimeSliderWidget is optional for MVP. Standard mode is sufficient to validate the module.

3. **Extraction:** TimeSlider and ColorScheme logic will be extracted to shared in Phase 3 AFTER validation.

4. **Testing:** All files verified with `flutter analyze` - 0 errors except 1 harmless warning in ViewModel.

