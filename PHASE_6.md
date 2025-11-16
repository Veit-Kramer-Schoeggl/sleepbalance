# PHASE 6: Light Module Implementation (First Intervention)

## Overview
Implement the Light Therapy module as the first complete intervention module, establishing the pattern for all future modules. Includes module infrastructure, database operations, notification scheduling, configuration UI, and correlation with sleep data.

## Prerequisites
- **Phase 1-5 completed:** Full MVVM + Provider setup working
  - ✅ Phase 5 established SettingsViewModel pattern for app-wide state
  - ✅ SplashScreen loads current user at app startup
  - ✅ ActionScreen demonstrates local ViewModel creation pattern
- Database has intervention_activities and user_module_configurations tables
- Understanding of hybrid schema (typed + JSON columns)
- **Key learnings from Phase 5:**
  - Global ViewModels (like SettingsViewModel) are registered in main.dart for app-wide access
  - Feature-specific ViewModels can be created locally in screens
  - Always use `WidgetsBinding.instance.addPostFrameCallback` for async operations in initState
  - Current user ID accessible via `context.read<SettingsViewModel>().currentUser?.id`

## Goals
- Create shared module infrastructure (base classes, interfaces)
- Implement Light module models, repository, ViewModel
- Build Light configuration screen (user settings)
- Integrate with notification system (Phase 1 created notification infrastructure, now use it)
- Add module management to Settings screen
- Demonstrate full module workflow: enable → configure → track → correlate

---

## Step 6.1: Create Shared Module Infrastructure - Module Model

**File:** `lib/modules/shared/domain/models/module.dart`
**Purpose:** Define what a module is (matches modules table)
**Dependencies:** `json_annotation`

**Class: Module**

**Fields:**
- `String id` - Module ID (e.g., 'light', 'sport')
- `String name` - Internal name
- `String displayName` - Display name (e.g., 'Light Therapy')
- `String? description` - Module description (nullable)
- `String? icon` - Icon identifier (nullable)
- `bool isActive` - Is module active app-wide

**Methods:**
- Constructor, fromJson, toJson

**Why:** Represents modules from database, used for enabling/disabling

---

## Step 6.2: Create Shared Model - UserModuleConfig

**File:** `lib/modules/shared/domain/models/user_module_config.dart`
**Purpose:** User's configuration for a module
**Dependencies:** `json_annotation`

**Class: UserModuleConfig**

**Fields:**
- `String id` - UUID
- `String userId` - Foreign key
- `String moduleId` - Foreign key to modules table
- `bool isEnabled` - Has user enabled this module
- `Map<String, dynamic> configuration` - Module-specific JSON config
- `DateTime enrolledAt`
- `DateTime updatedAt`

**Methods:**
- Constructor, fromJson, toJson, copyWith
- `T? getConfigValue<T>(String key)` - Helper to extract from configuration JSON
- `UserModuleConfig updateConfig(String key, dynamic value)` - Helper to update configuration

**Why:** Stores user's module settings in flexible JSON format

---

## Step 6.3: Create Shared Model - InterventionActivity

**File:** `lib/modules/shared/domain/models/intervention_activity.dart`
**Purpose:** Base model for all intervention tracking (matches intervention_activities table)
**Dependencies:** `json_annotation`

**Class: InterventionActivity**

**Fields:**
- `String id` - UUID
- `String userId` - Foreign key
- `String moduleId` - Foreign key
- `DateTime activityDate` - The day of the intervention
- `bool wasCompleted` - Did user complete it
- `DateTime? completedAt` - When completed (nullable)
- `int? durationMinutes` - How long (nullable)
- `String? timeOfDay` - 'morning', 'afternoon', 'evening', 'night' (nullable)
- `String? intensity` - 'low', 'medium', 'high' (nullable)
- `Map<String, dynamic>? moduleSpecificData` - Module-specific JSON (nullable)
- `String? notes` - User notes (nullable)
- `DateTime createdAt`

**Methods:**
- Constructor, fromJson, toJson, copyWith

**Why:** Common base for all module activities, module-specific data goes in JSON field

---

## Step 6.4: Create Light Module - LightActivity Model

**File:** `lib/modules/light/domain/models/light_activity.dart`
**Purpose:** Extends InterventionActivity with Light-specific helpers
**Dependencies:** `intervention_activity`

**Class: LightActivity extends InterventionActivity**

**Constructor:**
```dart
LightActivity({
  required super.id,
  required super.userId,
  required super.activityDate,
  // ... all inherited fields
  String? lightType,  // Stored in moduleSpecificData
  String? location,   // Stored in moduleSpecificData
}) : super(
  moduleId: 'light',
  moduleSpecificData: {
    'light_type': lightType,
    'location': location,
  },
);
```

**Additional Getters:**
- `String? get lightType => moduleSpecificData?['light_type']`
- `String? get location => moduleSpecificData?['location']`

**Methods:**
- `factory LightActivity.fromJson(Map<String, dynamic> json)` - Calls super.fromJson
- Override toJson to ensure moduleId = 'light'

**Why:** Type-safe access to Light-specific data while using base class

---

## Step 6.5: Create Light Module - LightConfig Model

**File:** `lib/modules/light/domain/models/light_config.dart`
**Purpose:** Light module configuration (stored in user_module_configurations.configuration JSON)
**Dependencies:** None (plain Dart class)

**Class: LightConfig**

**Fields:**
- `String targetTime` - HH:mm format (e.g., '07:30')
- `int targetDurationMinutes` - Default: 30
- `String lightType` - 'natural_sunlight', 'light_box', 'blue_light', 'red_light'
- `bool morningReminderEnabled` - Default: true
- `String morningReminderTime` - HH:mm
- `bool eveningDimReminderEnabled` - Default: true
- `String eveningDimTime` - HH:mm (e.g., '20:00')
- `bool blueBlockerReminderEnabled` - Default: true
- `String blueBlockerTime` - HH:mm (e.g., '21:00')

**Methods:**
- Constructor with defaults
- `factory LightConfig.fromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()`
- `LightConfig copyWith({...})`

**Static defaults:**
- `static LightConfig get defaultConfig` - Returns config with sensible defaults

**Why:** Structured configuration, serializes to JSON for database storage

---

## Step 6.6: Create Light Repository Interface

**File:** `lib/modules/light/domain/repositories/light_module_repository.dart`
**Purpose:** Abstract interface for Light module data operations
**Dependencies:** Models

**Abstract Class: LightModuleRepository**

**Methods:**
- `Future<UserModuleConfig?> getUserConfig(String userId)` - Get user's light config
- `Future<void> saveConfig(UserModuleConfig config)` - Save config
- `Future<List<LightActivity>> getActivitiesForDate(String userId, DateTime date)` - Get activities
- `Future<List<LightActivity>> getActivitiesBetween(String userId, DateTime start, DateTime end)` - Date range
- `Future<void> logActivity(LightActivity activity)` - Save activity
- `Future<void> deleteActivity(String activityId)` - Remove activity
- `Future<bool> isModuleEnabled(String userId)` - Check if user enabled light module
- `Future<void> enableModule(String userId)` - Enable light module
- `Future<void> disableModule(String userId)` - Disable light module

**Why:** Abstracts data access for Light module

---

## Step 6.7: Create Light Data Source

**File:** `lib/modules/light/data/datasources/light_module_local_datasource.dart`
**Purpose:** SQLite operations for Light module
**Dependencies:** `sqflite`, `database_helper`, `database_constants`, models

**Class: LightModuleLocalDataSource**

**Constructor:**
- `LightModuleLocalDataSource({required Database database})`

**Methods:**

**`Future<UserModuleConfig?> getConfigForUser(String userId)`**
- Query user_module_configurations WHERE user_id AND module_id = 'light'
- Convert to UserModuleConfig or null

**`Future<void> upsertConfig(UserModuleConfig config)`**
- INSERT OR REPLACE user_module_configurations

**`Future<List<LightActivity>> getActivitiesByDate(String userId, DateTime date)`**
- Query intervention_activities WHERE user_id AND module_id = 'light' AND activity_date
- Convert to List<LightActivity>

**`Future<List<LightActivity>> getActivitiesByDateRange(String userId, DateTime start, DateTime end)`**
- Query with BETWEEN clause
- Convert to List<LightActivity>

**`Future<void> insertActivity(LightActivity activity)`**
- Convert to Map
- INSERT OR REPLACE intervention_activities

**`Future<void> deleteActivity(String activityId)`**
- DELETE FROM intervention_activities WHERE id

**`Future<bool> isEnabled(String userId)`**
- Query user_module_configurations.is_enabled
- Return boolean

**`Future<void> setEnabled(String userId, bool enabled)`**
- UPDATE user_module_configurations SET is_enabled

---

## Step 6.8: Implement Light Repository

**File:** `lib/modules/light/data/repositories/light_module_repository_impl.dart`
**Purpose:** Concrete implementation delegating to datasource
**Dependencies:** Repository interface, datasource

**Class: LightModuleRepositoryImpl implements LightModuleRepository**

**Constructor:**
- `LightModuleRepositoryImpl({required LightModuleLocalDataSource dataSource})`

**Methods:**
- All methods delegate to `_dataSource`

---

## Step 6.9: Create Light ViewModel

**File:** `lib/modules/light/presentation/viewmodels/light_module_viewmodel.dart`
**Purpose:** Manage Light module state, handle configuration, track activities
**Dependencies:** `provider`, repository, models

**Class: LightModuleViewModel extends ChangeNotifier**

**Constructor:**
- `LightModuleViewModel({required LightModuleRepository repository})`

**Fields:**
- `final LightModuleRepository _repository`
- `UserModuleConfig? _config`
- `LightConfig? _lightConfig` - Parsed from config.configuration JSON
- `List<LightActivity> _activities = []`
- `bool _isEnabled = false`
- `bool _isLoading = false`
- `String? _errorMessage`

**Getters:**
- All fields exposed via getters

**Methods:**

**✅ IMPORTANT - Follow Phase 5 Pattern:**
All async methods MUST use try-catch-finally pattern:
```dart
Future<void> someMethod() async {
  try {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Do work here

  } catch (e) {
    _errorMessage = 'Failed to ...: $e';
    debugPrint('LightModuleViewModel: Error in someMethod: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**`Future<void> loadConfig(String userId)`**
- Wrap in try-catch-finally (see pattern above)
- Fetch UserModuleConfig from repository
- Parse configuration JSON into LightConfig
- Set _lightConfig
- Check is_enabled
- Set _isLoading, handle errors, always notify listeners

**`Future<void> saveConfig(String userId, LightConfig newConfig)`**
- Wrap in try-catch-finally
- Create/update UserModuleConfig with new configuration JSON
- Save to repository
- Reload config
- Schedule notifications
- Set _isLoading, handle errors, always notify listeners

**`Future<void> loadActivities(String userId, DateTime date)`**
- Wrap in try-catch-finally
- Fetch activities for date
- Set _activities
- Set _isLoading, handle errors, always notify listeners

**`Future<void> logActivity(String userId, LightActivity activity)`**
- Wrap in try-catch-finally
- Save activity to repository
- Reload activities
- Set _isLoading, handle errors, always notify listeners

**`Future<void> toggleModule(String userId)`**
- Wrap in try-catch-finally
- If enabled: disable, cancel notifications
- If disabled: enable, schedule notifications
- Set _isLoading, handle errors, always notify listeners

**`Future<void> scheduleNotifications(String userId, LightConfig config)`**
- If morningReminderEnabled: Schedule notification at morningReminderTime
- If eveningDimReminderEnabled: Schedule at eveningDimTime
- If blueBlockerReminderEnabled: Schedule at blueBlockerTime
- Use NotificationService (from Phase 1)

**`Future<void> cancelNotifications()`**
- Cancel all Light module notifications
- Use NotificationService

**Reference:** See `SettingsViewModel` and `ActionViewModel` for identical error handling patterns!

---

## Step 6.10: Create Light Configuration Screen

**File:** `lib/modules/light/presentation/screens/light_config_screen.dart`
**Purpose:** UI for configuring Light module settings
**Dependencies:** `provider`, ViewModel, models, widgets

**Class: LightConfigScreen extends StatefulWidget**

**✅ IMPORTANT - Get Current User ID:**
Follow the Phase 5 pattern for accessing current user:
```dart
@override
void initState() {
  super.initState();

  // Use WidgetsBinding to avoid setState during build
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final settingsViewModel = context.read<SettingsViewModel>();
    final userId = settingsViewModel.currentUser?.id;

    if (userId != null) {
      final lightViewModel = context.read<LightModuleViewModel>();
      lightViewModel.loadConfig(userId);
    } else {
      // Handle no user case
      debugPrint('Warning: No current user found in Light Config');
    }
  });
}
```

**Build Method:**
- `final viewModel = context.watch<LightModuleViewModel>()`
- `final settingsViewModel = context.watch<SettingsViewModel>()`
- `final userId = settingsViewModel.currentUser?.id`
- `final config = viewModel.lightConfig ?? LightConfig.defaultConfig`

**Handle Loading/Error States:**
```dart
if (viewModel.isLoading) {
  return Center(child: CircularProgressIndicator());
}

if (viewModel.errorMessage != null) {
  return Center(child: Text('Error: ${viewModel.errorMessage}'));
}

if (userId == null) {
  return Center(child: Text('No user logged in'));
}
```

**Form Fields:**
- **Module Enabled** (Switch)
  - Calls `viewModel.toggleModule(userId)` on change

- **Target Time** (TimePicker)
  - Show current targetTime
  - Update on change

- **Duration** (Slider)
  - 15-60 minutes range
  - Show current targetDurationMinutes

- **Light Type** (Dropdown)
  - Options: Natural Sunlight, Light Box, Blue Light, Red Light
  - Show current LightType

- **Notifications Section:**
  - **Morning Reminder** (Switch + TimePicker)
  - **Evening Dim Reminder** (Switch + TimePicker)
  - **Blue Blocker Reminder** (Switch + TimePicker)

**Save Button:**
- Get userId from SettingsViewModel
- Create updated LightConfig
- Call `viewModel.saveConfig(userId, newConfig)`
- Show success SnackBar
- Navigate back

**Why:** Allows user to customize Light therapy intervention

**Reference:** See `ActionScreen` for complete example of this pattern!

---

## Step 6.11: Add Module Management to Settings

**File:** `lib/features/settings/presentation/screens/settings_screen.dart` (modify)
**Purpose:** Add "Manage Modules" option that navigates to Light config
**Action:** Update existing ListTile

**Changes:**
```dart
ListTile(
  title: Text('Manage Modules'),
  subtitle: Text('Enable/disable intervention modules'),
  trailing: Icon(Icons.extension),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<LightModuleViewModel>(),
          child: LightConfigScreen(),
        ),
      ),
    );
  },
),
```

**Why:** Provides navigation to module configuration

---

## Step 6.12: Register Light Module Providers

**File:** `lib/main.dart` (modify providers list)
**Purpose:** Add Light module to Provider tree
**Action:** Add to provider list

**✅ IMPORTANT - Provider Registration Order (from Phase 5):**
The order MUST be: Services → DataSources → Repositories → ViewModels

**Add AFTER SettingsViewModel:**
```dart
// ============================================================================
// Light Module - Intervention System
// ============================================================================

// DataSource layer - database access
Provider<LightModuleLocalDataSource>(
  create: (_) => LightModuleLocalDataSource(database: database),
),

// Repository layer - abstracts data access
Provider<LightModuleRepository>(
  create: (context) => LightModuleRepositoryImpl(
    dataSource: context.read<LightModuleLocalDataSource>(),
  ),
),

// ViewModel layer - state management
// NOTE: Unlike SettingsViewModel, this could be created locally in screens
// But registering globally makes it available everywhere
ChangeNotifierProvider<LightModuleViewModel>(
  create: (context) => LightModuleViewModel(
    repository: context.read<LightModuleRepository>(),
  ),
),
```

**Alternative: Local ViewModel Creation (Phase 5 Pattern)**
If you prefer, LightModuleViewModel can be created locally in the screen:
```dart
// In LightConfigScreen.build():
return ChangeNotifierProvider(
  create: (_) => LightModuleViewModel(
    repository: context.read<LightModuleRepository>(),
  ),
  child: const _LightConfigContent(),
);
```

**Choose based on:**
- Global registration: Easier access, shared state across screens
- Local creation: More isolated, follows ActionScreen pattern

**For Phase 6, register globally for simplicity.**

---

## Testing Checklist

### Manual Tests:
- [ ] Navigate to Settings → Manage Modules
- [ ] Should see Light Config screen
- [ ] Toggle module enabled, should save to database
- [ ] Set target time and duration, save
- [ ] Check database, user_module_configurations should have JSON config
- [ ] Enable notifications, check notification permission requested
- [ ] Wait for scheduled time, notification should fire
- [ ] Log activity for today, check intervention_activities table
- [ ] Check correlation: Night Review should show light activity for that day

### Unit Tests:
- [ ] Test LightConfig fromJson/toJson
- [ ] Test LightActivity moduleSpecificData parsing
- [ ] Test LightModuleViewModel saveConfig flow
- [ ] Test notification scheduling logic

### Integration Tests:
- [ ] Full workflow: Enable module → Configure → Schedule notifications → Log activity → View correlation

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
  sr.deep_sleep_duration
FROM intervention_activities ia
LEFT JOIN sleep_records sr ON sr.user_id = ia.user_id AND sr.sleep_date = ia.activity_date
WHERE ia.module_id = 'light'
ORDER BY ia.activity_date DESC;
```

---

## Rollback Strategy

- Light module is isolated, can disable without affecting other features
- Remove from Settings navigation if needed
- Database tables remain, just unused

---

## Next Steps

After Phase 6:
- **Pattern established:** Other modules (Sport, Meditation, etc.) follow same structure
- Proceed to **PHASE_7.md:** Clean up remaining screens (Habits Lab, Onboarding)
- Future: Add more modules using Light as template

---

## Notes

**Why Light module first?**
- Simplest intervention (just time and duration)
- Clear notifications (morning, evening)
- Easy to track (binary completion)

**Module Pattern Established:**
1. Models: BaseActivity + ModuleActivity + ModuleConfig
2. Repository: Interface + Datasource + Implementation
3. ViewModel: ChangeNotifier with CRUD operations (follow Phase 5 error handling!)
4. Screen: Configuration UI (access current user via SettingsViewModel)
5. Integration: Register in Provider, add to Settings

**Notification System:**
- Uses core/notifications/ infrastructure from Phase 1
- Module-specific scheduling in ViewModel
- Cancels on disable

**Correlation with Sleep:**
- intervention_activities.activity_date joins with sleep_records.sleep_date
- Analyze: Did light therapy on Day N improve sleep on Night N?

**Key Learnings from Phase 5 Applied Here:**

1. **ViewModel Error Handling Pattern:**
   - ALWAYS use try-catch-finally
   - Set _isLoading in try block before operation
   - Set _errorMessage in catch block
   - Set _isLoading = false in finally block
   - ALWAYS call notifyListeners() in finally block
   - Reference: SettingsViewModel for complete example

2. **Current User Access Pattern:**
   - Get user ID from SettingsViewModel, not hardcoded
   - Pattern: `context.read<SettingsViewModel>().currentUser?.id`
   - Handle null case gracefully
   - Reference: ActionScreen for complete example

3. **Async in initState Pattern:**
   - NEVER call async directly in initState
   - ALWAYS use: `WidgetsBinding.instance.addPostFrameCallback((_) { ... })`
   - Prevents "setState during build" errors
   - Reference: SplashScreen for complete example

4. **Provider Registration Order:**
   - Must be: Services → DataSources → Repositories → ViewModels
   - ViewModels depend on Repositories
   - Register in correct order or app will crash
   - Reference: main.dart for complete example

5. **Global vs Local ViewModels:**
   - Global (in main.dart): For app-wide state (e.g., SettingsViewModel)
   - Local (in screen): For feature-specific state (e.g., ActionViewModel)
   - LightModuleViewModel: Can be either, global is simpler
   - Choose based on whether state needs to be shared across screens

6. **Database Migrations:**
   - ALWAYS use `IF NOT EXISTS` in CREATE TABLE statements
   - Makes migrations idempotent (safe to run multiple times)
   - Pattern: `CREATE TABLE IF NOT EXISTS ...`
   - Reference: migration_v4.dart for example

**Estimated Time:** 8-10 hours
- Shared infrastructure: 90 minutes
- Light models: 90 minutes
- Repository: 90 minutes
- ViewModel: 120 minutes (with proper error handling!)
- Configuration screen: 120 minutes (with current user access!)
- Notification integration: 90 minutes
- Testing: 90 minutes
