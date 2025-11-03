# PHASE 7: Habits Lab Framework - Module Management Infrastructure

## Overview
Build the foundational framework for Habits Lab module management system. This phase implements the data layer, module interface contracts, and repository patterns that enable users to add, remove, and configure intervention modules. **NO UI IMPLEMENTATION** - the UI will be built by juniors in a separate phase.

**Key Value Proposition:** Flexible, pluggable module system where users can customize their sleep intervention strategy by activating only the modules relevant to their needs.

## Prerequisites
- ✅ **Phase 1-5 completed:** MVVM architecture, database infrastructure, User model
- ✅ **Phase 6 completed:** Light module implemented (will serve as reference implementation)
- 📚 **Understanding:** Repository pattern, interface-based design, JSON configuration storage
- 📚 **Read:** `SHARED_README.md`, `SHARED_PLAN.md` for module architecture context

## Goals
- Create `user_module_configurations` database table for storing module settings
- Define `ModuleInterface` contract that all modules must implement
- Implement `ModuleRegistry` for centralized module management
- Create `ModuleMetadata` system for module descriptions, icons, and colors
- Build repository pattern for module configuration CRUD operations
- Create data models with proper serialization
- Update Light Module to implement the interface (reference for juniors)
- **Expected outcome:** Complete framework ready for UI implementation, 0 analyzer warnings

---

## Architecture Overview

### What We're Building

```
┌─────────────────────────────────────────────────────────────────┐
│                     Habits Lab UI (Future)                       │
│                     Implemented by Juniors                       │
└────────────────────┬────────────────────────────────────────────┘
                     │ uses
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ModuleRegistry (Phase 7)                      │
│  getAllModules() → List all available modules                    │
│  getModule(id) → Get specific module                             │
├─────────────────────────────────────────────────────────────────┤
│         ┌──────────────┬──────────────┬──────────────┐          │
│         │ LightModule  │ SportModule  │ MeditModule  │          │
│         │ implements   │ implements   │ implements   │          │
│         │ Interface    │ Interface    │ Interface    │          │
│         └──────────────┴──────────────┴──────────────┘          │
└────────────────────┬────────────────────────────────────────────┘
                     │ implements
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│              ModuleInterface (Phase 7 Contract)                  │
│  - getMetadata() → ModuleMetadata                                │
│  - getConfigurationScreen() → Widget                             │
│  - getDefaultConfiguration() → Map<String, dynamic>              │
│  - onModuleActivated() → Schedule notifications, etc.            │
│  - onModuleDeactivated() → Cancel notifications, etc.            │
└────────────────────┬────────────────────────────────────────────┘
                     │ uses
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│           ModuleConfigRepository (Phase 7 Data Layer)            │
│  - getUserModuleConfigs() → List<UserModuleConfig>               │
│  - addModuleConfig() → Enable module with default settings       │
│  - updateModuleConfig() → Update module settings                 │
│  - deactivateModule() → Mark module as inactive                  │
└────────────────────┬────────────────────────────────────────────┘
                     │ queries
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│           user_module_configurations Table (Phase 7)             │
│  Columns: id, user_id, module_id, is_enabled, configuration,    │
│           enrolled_at, updated_at                                │
└─────────────────────────────────────────────────────────────────┘
```

### User Flow (After UI is Built)

1. User opens Habits Lab → sees list of modules (from ModuleRegistry)
2. User taps "Add Module" → sees available modules not yet active
3. User selects "Sport" → Module activated with default settings
4. User taps Sport module card → navigates to `SportModule.getConfigurationScreen()`
5. User modifies settings → saved to `configuration` JSON column
6. User deactivates Sport → notifications cancelled, data kept, `is_enabled = false`

---

## Habits Lab Delegation Model

**Key Principle:** Habits Lab does NOT handle module data directly. It delegates all operations to modules.

### What Habits Lab Does:
✅ **Module Discovery** - Uses `ModuleRegistry` to list available modules
✅ **Activation/Deactivation** - Uses `ModuleConfigRepository` to enable/disable modules
✅ **Navigation** - Routes to module config screens via `ModuleInterface.getConfigurationScreen()`
✅ **Lifecycle Management** - Calls `onModuleActivated()` / `onModuleDeactivated()` hooks

### What Habits Lab Does NOT Do:
❌ **Module CRUD** - Each module has its own repository (LightRepository, SportRepository, etc.)
❌ **Activity Tracking** - Handled by module-specific repositories
❌ **Module Analytics** - Delegated to module repositories
❌ **Module-Specific Logic** - Lives in module implementations

### Data Flow Example:

**User activates Light module:**
```
1. Habits Lab → ModuleRegistry.getModule('light')
2. Habits Lab → lightModule.getDefaultConfiguration()
3. Habits Lab → ModuleConfigRepository.addModuleConfig(config)
4. ModuleConfigRepository → lightModule.onModuleActivated()
5. Light Module → LightRepository (schedules notifications, stores config)
```

**User logs light activity:**
```
1. Light Module UI → LightViewModel.logActivity()
2. LightViewModel → LightRepository.logActivity()
3. LightRepository → intervention_activities table
```

**Habits Lab never touches LightRepository!** Each module manages its own data.

---

## Part A: Database Schema

### Step 7.1: Create Database Migration v5

**File:** `lib/core/database/migrations/migration_v5.dart`
**Purpose:** Create `user_module_configurations` table
**Dependencies:** None

**Why this table?**
- Central storage for all module settings across the app
- JSON configuration column for module-specific settings (flexible schema)
- Track when modules were activated/deactivated
- Support for multiple users (future-proofing)

**Implementation:**

```dart
// ignore_for_file: constant_identifier_names
/// Migration V5: User Module Configurations
///
/// Creates table for storing user's module settings and activation status.
/// Each module stores its configuration as JSON for maximum flexibility.
library;

class MigrationV5 {
  static const String MIGRATION_V5 = '''
    -- User module configuration table
    -- Stores which modules each user has enabled and their settings
    CREATE TABLE IF NOT EXISTS user_module_configurations (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      module_id TEXT NOT NULL,
      is_enabled INTEGER NOT NULL DEFAULT 1,
      configuration TEXT NOT NULL,
      enrolled_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Ensure one config per user per module
    CREATE UNIQUE INDEX IF NOT EXISTS idx_user_module_unique
      ON user_module_configurations(user_id, module_id);

    -- Query by user
    CREATE INDEX IF NOT EXISTS idx_user_module_user_id
      ON user_module_configurations(user_id);

    -- Query active modules
    CREATE INDEX IF NOT EXISTS idx_user_module_enabled
      ON user_module_configurations(user_id, is_enabled);
  ''';
}
```

**Table Design Decisions:**

**`id` (TEXT PRIMARY KEY)**
- UUID generated by app
- Local-first approach, no auto-increment

**`user_id` (TEXT NOT NULL)**
- Foreign key to users table
- Enables multi-user support (future)
- Cascade delete: Remove configs when user deleted

**`module_id` (TEXT NOT NULL)**
- Module identifier: 'light', 'sport', 'meditation', etc.
- Matches module IDs from ModuleMetadata

**`is_enabled` (INTEGER NOT NULL DEFAULT 1)**
- 1 = module active, 0 = module deactivated
- Deactivating keeps configuration and history
- Default to 1 when first added

**`configuration` (TEXT NOT NULL)**
- JSON-encoded Map<String, dynamic>
- Module-specific settings stored here
- Example for Light module:
  ```json
  {
    "mode": "standard",
    "sessions": [
      {
        "type": "sunlight",
        "time": "07:30",
        "duration": 20,
        "enabled": true,
        "notificationEnabled": true
      }
    ]
  }
  ```

**`enrolled_at` (TEXT NOT NULL)**
- ISO 8601 datetime when module first activated
- Useful for analytics, retention tracking

**`updated_at` (TEXT NOT NULL)**
- ISO 8601 datetime of last configuration change
- Updated whenever settings modified

**Indexes:**
- UNIQUE(user_id, module_id): Prevent duplicate module configs
- INDEX(user_id): Fast queries for user's modules
- INDEX(user_id, is_enabled): Fast queries for active modules only

---

### Step 7.2: Update DatabaseHelper

**File:** `lib/core/database/database_helper.dart`
**Purpose:** Register migration v5
**Pattern Reference:** Phase 4 pattern for adding migrations

**What to change:**

1. Update database version:
```dart
static const int _DATABASE_VERSION = 5; // Was 4
```

2. Add migration to onCreate:
```dart
await database.execute(MigrationV4.MIGRATION_V4);
await database.execute(MigrationV5.MIGRATION_V5); // ADD THIS
```

3. Add to onUpgrade:
```dart
if (oldVersion < 5) {
  await db.execute(MigrationV5.MIGRATION_V5);
}
```

**Import:**
```dart
import 'migrations/migration_v5.dart';
```

---

### Step 7.3: Update Database Constants

**File:** `lib/shared/constants/database_constants.dart`
**Purpose:** Add constants for new table
**Pattern Reference:** Existing table constants in same file

**Add these constants:**

```dart
// ============================================================================
// User Module Configurations Table
// ============================================================================

const String TABLE_USER_MODULE_CONFIGURATIONS = 'user_module_configurations';

// Columns
const String USER_MODULE_CONFIGS_ID = 'id';
const String USER_MODULE_CONFIGS_USER_ID = 'user_id';
const String USER_MODULE_CONFIGS_MODULE_ID = 'module_id';
const String USER_MODULE_CONFIGS_IS_ENABLED = 'is_enabled';
const String USER_MODULE_CONFIGS_CONFIGURATION = 'configuration';
const String USER_MODULE_CONFIGS_ENROLLED_AT = 'enrolled_at';
const String USER_MODULE_CONFIGS_UPDATED_AT = 'updated_at';
```

**Why constants?**
- Type safety (catch typos at compile time)
- Refactoring support (change column name in one place)
- Consistency across datasources

---

## Part B: Module Metadata System

### Step 7.4: Create ModuleMetadata Model

**File:** `lib/modules/shared/constants/module_metadata.dart`
**Purpose:** Define module metadata (names, descriptions, icons, colors)
**Dependencies:** `flutter/material.dart`

**Create new folder first:**
```bash
mkdir -p lib/modules/shared/constants
```

**Implementation:**

```dart
import 'package:flutter/material.dart';

/// Metadata describing an intervention module
///
/// Contains display information used by UI to show modules to users.
/// This is hardcoded configuration data, not database models.
class ModuleMetadata {
  /// Unique module identifier (matches module_id in database)
  final String id;

  /// Display name shown to users
  final String displayName;

  /// Short description (1-2 sentences) for module selection
  final String shortDescription;

  /// Longer description explaining module benefits and usage
  final String longDescription;

  /// Icon representing the module
  final IconData icon;

  /// Primary color for module UI elements
  final Color primaryColor;

  /// Whether module is currently implemented
  /// Set to false for planned modules not yet available
  final bool isAvailable;

  const ModuleMetadata({
    required this.id,
    required this.displayName,
    required this.shortDescription,
    required this.longDescription,
    required this.icon,
    required this.primaryColor,
    this.isAvailable = true,
  });
}

/// Central registry of all module metadata
///
/// Add new modules here when implementing them.
/// UI will automatically display new modules when added to this map.
const Map<String, ModuleMetadata> moduleMetadata = {
  'light': ModuleMetadata(
    id: 'light',
    displayName: 'Light Therapy',
    shortDescription: 'Morning bright light to regulate circadian rhythm',
    longDescription: 'Optimize light exposure throughout the day to support '
        'healthy circadian rhythms and improve sleep quality. Bright light '
        'in the morning advances the sleep-wake cycle, while avoiding bright '
        'light in the evening supports natural melatonin production.',
    icon: Icons.wb_sunny,
    primaryColor: Color(0xFFFFA726), // Amber
    isAvailable: true,
  ),

  'sport': ModuleMetadata(
    id: 'sport',
    displayName: 'Physical Activity',
    shortDescription: 'Exercise timing and intensity optimization',
    longDescription: 'Track exercise timing and intensity with wearable '
        'integration. Morning HIIT provides optimal sleep benefit, while '
        'high-intensity evening exercise may disrupt sleep. Find your '
        'optimal exercise schedule.',
    icon: Icons.directions_run,
    primaryColor: Color(0xFF66BB6A), // Green
    isAvailable: false, // Not yet implemented
  ),

  'meditation': ModuleMetadata(
    id: 'meditation',
    displayName: 'Meditation & Relaxation',
    shortDescription: 'Guided relaxation and breathwork practices',
    longDescription: 'Access a library of guided meditation and breathwork '
        'sessions. Evening pre-sleep sessions reduce anxiety and racing '
        'thoughts. Diverse techniques from multiple teachers and traditions.',
    icon: Icons.spa,
    primaryColor: Color(0xFF9C27B0), // Purple
    isAvailable: false,
  ),

  'temperature': ModuleMetadata(
    id: 'temperature',
    displayName: 'Temperature Therapy',
    shortDescription: 'Cold and heat exposure for sleep enhancement',
    longDescription: 'Optimize temperature exposure timing. Morning cold '
        'showers boost alertness, while evening saunas facilitate sleep '
        'onset through subsequent body cooling. Science-backed protocols.',
    icon: Icons.thermostat,
    primaryColor: Color(0xFF42A5F5), // Blue
    isAvailable: false,
  ),

  'mealtime': ModuleMetadata(
    id: 'mealtime',
    displayName: 'Meal Timing',
    shortDescription: 'Eating schedule optimization for better sleep',
    longDescription: 'Optimize eating windows and meal timing. Default '
        '3-meal pattern or customizable intermittent fasting windows, '
        'automatically adjusted to your sleep schedule.',
    icon: Icons.restaurant_menu,
    primaryColor: Color(0xFFFF7043), // Deep Orange
    isAvailable: false,
  ),

  'nutrition': ModuleMetadata(
    id: 'nutrition',
    displayName: 'Sleep Nutrition',
    shortDescription: 'Evidence-based food and supplement guidance',
    longDescription: 'Learn about sleep-promoting foods, nutrients, and '
        'supplements. Daily tips, comprehensive food database, and '
        'personalized recommendations based on dietary preferences.',
    icon: Icons.eco,
    primaryColor: Color(0xFF26A69A), // Teal
    isAvailable: false,
  ),

  'journaling': ModuleMetadata(
    id: 'journaling',
    displayName: 'Sleep Journaling',
    shortDescription: 'Reflective writing with pattern recognition',
    longDescription: 'Track thoughts, emotions, and daily events with '
        'multiple input methods (typing, voice, handwriting). ML-based '
        'pattern recognition identifies factors affecting your sleep.',
    icon: Icons.edit_note,
    primaryColor: Color(0xFF8D6E63), // Brown
    isAvailable: false,
  ),
};

/// Get metadata for a specific module
///
/// Returns unknown module metadata if module_id not found.
/// This prevents crashes when referencing modules not yet defined.
ModuleMetadata getModuleMetadata(String moduleId) {
  return moduleMetadata[moduleId] ??
      const ModuleMetadata(
        id: 'unknown',
        displayName: 'Unknown Module',
        shortDescription: 'Module not found',
        longDescription: '',
        icon: Icons.help_outline,
        primaryColor: Color(0xFF9E9E9E), // Grey
        isAvailable: false,
      );
}

/// Get all available (implemented) modules
List<ModuleMetadata> getAvailableModules() {
  return moduleMetadata.values.where((m) => m.isAvailable).toList();
}

/// Get all planned (not yet implemented) modules
List<ModuleMetadata> getPlannedModules() {
  return moduleMetadata.values.where((m) => !m.isAvailable).toList();
}
```

**Usage Example:**
```dart
// Get metadata
final lightMeta = getModuleMetadata('light');

// Display in UI
Icon(lightMeta.icon, color: lightMeta.primaryColor);
Text(lightMeta.displayName);
Text(lightMeta.shortDescription);
```

**Why hardcoded?**
- Modules are relatively static (7 core modules)
- Type-safe at compile time
- Zero database queries needed
- Easy to maintain and version control
- Can still use database `modules` table for feature flags later

---

## Part C: Module Interface Contract

### Step 7.5: Create ModuleInterface

**File:** `lib/modules/shared/domain/interfaces/module_interface.dart`
**Purpose:** Contract that all intervention modules must implement
**Dependencies:** Material, models

**Create new folder first:**
```bash
mkdir -p lib/modules/shared/domain/interfaces
```

**Implementation:**

```dart
import 'package:flutter/material.dart';
import '../models/user_module_config.dart';
import '../../constants/module_metadata.dart';

/// Interface that all intervention modules must implement
///
/// This contract enables:
/// - Habits Lab to discover and display all modules
/// - Standard lifecycle hooks (activation, deactivation)
/// - Automatic navigation to module-specific screens
/// - Type-safe module interactions
///
/// Each module (Light, Sport, Meditation, etc.) creates a class
/// implementing this interface and registers it with ModuleRegistry.
abstract class ModuleInterface {
  /// Unique module identifier
  ///
  /// Must match:
  /// - moduleMetadata map key
  /// - module_id in database
  /// - module folder name
  ///
  /// Examples: 'light', 'sport', 'meditation'
  String get moduleId;

  /// Get module metadata (name, description, icon, colors)
  ///
  /// Returns metadata from moduleMetadata map.
  /// Used by Habits Lab to display module information.
  ModuleMetadata getMetadata();

  /// Get the configuration screen for this module
  ///
  /// This screen allows users to customize module settings.
  /// Called when user taps module in Habits Lab.
  ///
  /// Parameters:
  /// - userId: Current user's ID
  /// - config: Existing configuration (null if first time setup)
  ///
  /// Returns: Module-specific configuration screen widget
  ///
  /// Example: LightModule returns LightConfigScreen
  Widget getConfigurationScreen({
    required String userId,
    UserModuleConfig? config,
  });

  /// Get default configuration when module is first activated
  ///
  /// Returns Map containing science-based default settings.
  /// Stored in user_module_configurations.configuration as JSON.
  ///
  /// Parameters:
  /// - userId: User's ID (for personalization if needed)
  /// - userWakeTime: User's typical wake time (from settings)
  /// - userBedTime: User's typical bed time (from settings)
  ///
  /// Returns: JSON-serializable Map<String, dynamic>
  ///
  /// Example for Light module:
  /// ```dart
  /// {
  ///   'mode': 'standard',
  ///   'sessions': [
  ///     {
  ///       'type': 'sunlight',
  ///       'time': '07:30',  // 30 min after wake
  ///       'duration': 20,
  ///       'enabled': true,
  ///       'notificationEnabled': true,
  ///     }
  ///   ]
  /// }
  /// ```
  Map<String, dynamic> getDefaultConfiguration({
    required String userId,
    TimeOfDay? userWakeTime,
    TimeOfDay? userBedTime,
  });

  /// Validate module configuration before saving
  ///
  /// Called before updating user_module_configurations.
  /// Allows module to enforce business rules.
  ///
  /// Parameters:
  /// - config: Configuration Map to validate
  ///
  /// Returns:
  /// - null if valid
  /// - Error message string if invalid
  ///
  /// Example validations:
  /// - At least one session configured
  /// - Duration values in valid range (5-60 minutes)
  /// - Time values properly formatted
  String? validateConfiguration(Map<String, dynamic> config);

  /// Called when module is activated by user
  ///
  /// Use this hook to:
  /// - Schedule initial notifications
  /// - Initialize module-specific services
  /// - Log analytics events
  ///
  /// Parameters:
  /// - userId: User who activated the module
  /// - config: Module configuration (from getDefaultConfiguration or user customization)
  ///
  /// This method is async to support database/network operations.
  Future<void> onModuleActivated({
    required String userId,
    required Map<String, dynamic> config,
  });

  /// Called when module is deactivated by user
  ///
  /// Use this hook to:
  /// - Cancel all scheduled notifications
  /// - Clean up resources
  /// - Log analytics events
  ///
  /// IMPORTANT: Do NOT delete user data or activity history.
  /// Only cleanup active resources (notifications, listeners, etc.)
  ///
  /// Parameters:
  /// - userId: User who deactivated the module
  Future<void> onModuleDeactivated({
    required String userId,
  });

  /// Called when user's sleep schedule changes
  ///
  /// Modules can update their recommendations and reschedule
  /// notifications based on new wake/bed times.
  ///
  /// Optional to implement - modules with timing-dependent
  /// features should implement this.
  ///
  /// Parameters:
  /// - userId: User whose schedule changed
  /// - newWakeTime: New wake time
  /// - newBedTime: New bed time
  ///
  /// Example: Light module recalculates morning session time
  /// to be 30 minutes after new wake time.
  Future<void> onSleepScheduleChanged({
    required String userId,
    required TimeOfDay newWakeTime,
    required TimeOfDay newBedTime,
  }) async {
    // Default implementation: do nothing
    // Modules can override if they need to react to schedule changes
  }
}
```

**Why this interface?**
- **Decoupling:** Habits Lab doesn't need module-specific code
- **Consistency:** All modules follow same patterns
- **Discoverability:** ModuleRegistry can list all modules
- **Type safety:** Compiler enforces method implementations
- **Extensibility:** Easy to add new modules

---

### Step 7.6: Create ModuleRegistry

**File:** `lib/modules/shared/domain/services/module_registry.dart`
**Purpose:** Central registry of all available modules
**Dependencies:** `module_interface.dart`

**Create new folder first:**
```bash
mkdir -p lib/modules/shared/domain/services
```

**Implementation:**

```dart
import '../interfaces/module_interface.dart';
import '../../constants/module_metadata.dart';

/// Central registry of all available modules
///
/// Modules register themselves at app startup in main.dart.
/// Habits Lab queries this registry to display available modules.
///
/// Usage in main.dart:
/// ```dart
/// void main() {
///   ModuleRegistry.register(LightModule());
///   ModuleRegistry.register(SportModule());
///   // ... register other modules
///
///   runApp(MyApp());
/// }
/// ```
///
/// Usage in Habits Lab:
/// ```dart
/// final availableModules = ModuleRegistry.getAllModules();
/// for (final module in availableModules) {
///   // Display module card
/// }
/// ```
class ModuleRegistry {
  /// Internal storage of registered modules
  /// Key: module_id, Value: ModuleInterface implementation
  static final Map<String, ModuleInterface> _modules = {};

  /// Register a module
  ///
  /// Called at app startup for each implemented module.
  /// If module already registered, it will be replaced.
  ///
  /// Parameters:
  /// - module: Module implementation (e.g., LightModule())
  ///
  /// Throws: ArgumentError if module.moduleId is empty
  static void register(ModuleInterface module) {
    if (module.moduleId.isEmpty) {
      throw ArgumentError('Module ID cannot be empty');
    }
    _modules[module.moduleId] = module;
  }

  /// Get all registered modules
  ///
  /// Returns list of all modules that have been registered.
  /// Used by Habits Lab to display available modules.
  ///
  /// Returns: List of ModuleInterface implementations
  static List<ModuleInterface> getAllModules() {
    return _modules.values.toList();
  }

  /// Get specific module by ID
  ///
  /// Used when:
  /// - User taps module → navigate to config screen
  /// - User activates module → call onModuleActivated
  /// - User deactivates module → call onModuleDeactivated
  ///
  /// Parameters:
  /// - moduleId: Module identifier (e.g., 'light', 'sport')
  ///
  /// Returns: ModuleInterface or null if not found
  static ModuleInterface? getModule(String moduleId) {
    return _modules[moduleId];
  }

  /// Get metadata for all registered modules
  ///
  /// Convenience method for getting metadata of all modules.
  ///
  /// Returns: Map of module_id → ModuleMetadata
  static Map<String, ModuleMetadata> getAllMetadata() {
    return Map.fromEntries(
      _modules.entries.map((e) => MapEntry(e.key, e.value.getMetadata())),
    );
  }

  /// Check if module is registered
  ///
  /// Useful for checking if module is available before trying to use it.
  ///
  /// Parameters:
  /// - moduleId: Module identifier
  ///
  /// Returns: true if module is registered, false otherwise
  static bool isRegistered(String moduleId) {
    return _modules.containsKey(moduleId);
  }

  /// Unregister all modules
  ///
  /// Only used in tests to reset registry state.
  /// Should NOT be called in production code.
  static void clearAll() {
    _modules.clear();
  }
}
```

**Usage Pattern:**

1. **Register modules at app startup (main.dart):**
```dart
void main() {
  // Register all implemented modules
  ModuleRegistry.register(LightModule());
  // ModuleRegistry.register(SportModule());  // When implemented
  // ModuleRegistry.register(MeditationModule());  // When implemented

  runApp(MyApp());
}
```

2. **Query modules in Habits Lab:**
```dart
// Get all modules
final modules = ModuleRegistry.getAllModules();

// Get specific module
final lightModule = ModuleRegistry.getModule('light');
if (lightModule != null) {
  final screen = lightModule.getConfigurationScreen(
    userId: currentUserId,
    config: existingConfig,
  );
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
```

---

## Part D: Data Models

### Step 7.7: Create UserModuleConfig Model

**File:** `lib/modules/shared/domain/models/user_module_config.dart`
**Purpose:** Model for user's module configuration
**Dependencies:** `json_annotation`, `database_date_utils`

**Create folder if needed:**
```bash
mkdir -p lib/modules/shared/domain/models
```

**Implementation:**

```dart
import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/date_formatter.dart';

part 'user_module_config.g.dart';

/// User's configuration for a specific module
///
/// Stored in user_module_configurations table.
/// Contains both activation status and module-specific settings.
@JsonSerializable()
class UserModuleConfig {
  /// Unique config ID (UUID)
  final String id;

  /// User who owns this configuration
  final String userId;

  /// Module this configuration belongs to
  /// Examples: 'light', 'sport', 'meditation'
  final String moduleId;

  /// Whether module is currently active
  /// true = user is using this module
  /// false = user deactivated, but we keep settings
  final bool isEnabled;

  /// Module-specific configuration as JSON
  ///
  /// Each module defines its own configuration structure.
  /// Stored as Map<String, dynamic> in Dart, JSON string in database.
  ///
  /// Example for Light module:
  /// {
  ///   'mode': 'standard',
  ///   'sessions': [...]
  /// }
  final Map<String, dynamic> configuration;

  /// When user first activated this module
  final DateTime enrolledAt;

  /// When configuration was last updated
  final DateTime updatedAt;

  UserModuleConfig({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.isEnabled,
    required this.configuration,
    required this.enrolledAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  // ========================================================================
  // Helper Methods
  // ========================================================================

  /// Get typed value from configuration
  ///
  /// Type-safe way to extract values from configuration map.
  ///
  /// Example:
  /// ```dart
  /// final mode = config.getConfigValue<String>('mode'); // 'standard'
  /// final sessions = config.getConfigValue<List>('sessions');
  /// ```
  T? getConfigValue<T>(String key) {
    return configuration[key] as T?;
  }

  /// Update a single configuration value
  ///
  /// Returns new UserModuleConfig with updated configuration.
  /// Does NOT mutate original object (immutable pattern).
  ///
  /// Example:
  /// ```dart
  /// final updated = config.updateConfigValue('mode', 'advanced');
  /// ```
  UserModuleConfig updateConfigValue(String key, dynamic value) {
    final newConfig = Map<String, dynamic>.from(configuration);
    newConfig[key] = value;
    return copyWith(
      configuration: newConfig,
      updatedAt: DateTime.now(),
    );
  }

  // ========================================================================
  // JSON Serialization (for API - future use)
  // ========================================================================

  factory UserModuleConfig.fromJson(Map<String, dynamic> json) =>
      _$UserModuleConfigFromJson(json);

  Map<String, dynamic> toJson() => _$UserModuleConfigToJson(this);

  // ========================================================================
  // Database Serialization (for SQLite)
  // ========================================================================

  /// Create from database row
  ///
  /// Converts SQLite row to UserModuleConfig instance.
  /// Handles type conversions:
  /// - INTEGER → bool (is_enabled)
  /// - TEXT → DateTime (enrolled_at, updated_at)
  /// - TEXT → Map<String, dynamic> (configuration JSON)
  factory UserModuleConfig.fromDatabase(Map<String, dynamic> map) {
    return UserModuleConfig(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      moduleId: map['module_id'] as String,
      isEnabled: (map['is_enabled'] as int) == 1,
      configuration: json.decode(map['configuration'] as String) as Map<String, dynamic>,
      enrolledAt: DatabaseDateUtils.parseDateTime(map['enrolled_at'] as String),
      updatedAt: DatabaseDateUtils.parseDateTime(map['updated_at'] as String),
    );
  }

  /// Convert to database row
  ///
  /// Converts UserModuleConfig to Map for SQLite insertion.
  /// Handles type conversions:
  /// - bool → INTEGER (1 or 0)
  /// - DateTime → TEXT (ISO 8601)
  /// - Map → TEXT (JSON string)
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'user_id': userId,
      'module_id': moduleId,
      'is_enabled': isEnabled ? 1 : 0,
      'configuration': json.encode(configuration),
      'enrolled_at': DatabaseDateUtils.toIso8601String(enrolledAt),
      'updated_at': DatabaseDateUtils.toIso8601String(updatedAt),
    };
  }

  // ========================================================================
  // CopyWith
  // ========================================================================

  UserModuleConfig copyWith({
    String? id,
    String? userId,
    String? moduleId,
    bool? isEnabled,
    Map<String, dynamic>? configuration,
    DateTime? enrolledAt,
    DateTime? updatedAt,
  }) {
    return UserModuleConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moduleId: moduleId ?? this.moduleId,
      isEnabled: isEnabled ?? this.isEnabled,
      configuration: configuration ?? this.configuration,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModuleConfig(id: $id, userId: $userId, moduleId: $moduleId, '
        'isEnabled: $isEnabled, enrolledAt: $enrolledAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModuleConfig &&
        other.id == id &&
        other.userId == userId &&
        other.moduleId == moduleId &&
        other.isEnabled == isEnabled &&
        other.enrolledAt == enrolledAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      moduleId,
      isEnabled,
      enrolledAt,
      updatedAt,
    );
  }
}
```

**After creating, run code generation:**
```bash
dart run build_runner build
```

---

## Part E: Repository Pattern

### Step 7.8: Create ModuleConfigRepository Interface

**File:** `lib/modules/shared/domain/repositories/module_config_repository.dart`
**Purpose:** Repository interface for module configuration operations
**Dependencies:** `user_module_config.dart`

**Implementation:**

```dart
import '../models/user_module_config.dart';

/// Repository for managing user module configurations
///
/// Provides CRUD operations for user_module_configurations table.
/// Concrete implementation in data layer.
abstract class ModuleConfigRepository {
  /// Get specific module configuration for user
  ///
  /// Returns null if user hasn't configured this module yet.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - moduleId: Module identifier (e.g., 'light')
  ///
  /// Returns: UserModuleConfig or null
  Future<UserModuleConfig?> getModuleConfig(String userId, String moduleId);

  /// Get all module configurations for user
  ///
  /// Returns all modules user has ever activated (active and inactive).
  /// Empty list if user hasn't configured any modules.
  ///
  /// Parameters:
  /// - userId: User's ID
  ///
  /// Returns: List of UserModuleConfig
  Future<List<UserModuleConfig>> getAllModuleConfigs(String userId);

  /// Get only active module configurations
  ///
  /// Returns modules where is_enabled = true.
  /// Used by Action Center to show only active modules.
  ///
  /// Parameters:
  /// - userId: User's ID
  ///
  /// Returns: List of UserModuleConfig
  Future<List<UserModuleConfig>> getActiveModuleConfigs(String userId);

  /// Get list of active module IDs
  ///
  /// Convenience method to get just the module IDs.
  /// Useful when you only need to know which modules are active.
  ///
  /// Parameters:
  /// - userId: User's ID
  ///
  /// Returns: List of module IDs (e.g., ['light', 'sport'])
  Future<List<String>> getActiveModuleIds(String userId);

  /// Add new module configuration
  ///
  /// Called when user activates a module for the first time.
  /// Also calls module's onModuleActivated lifecycle hook.
  ///
  /// Parameters:
  /// - config: UserModuleConfig to save
  ///
  /// Throws: Exception if config already exists for this user+module
  Future<void> addModuleConfig(UserModuleConfig config);

  /// Update existing module configuration
  ///
  /// Called when user changes module settings.
  /// Updates configuration JSON and updated_at timestamp.
  ///
  /// Parameters:
  /// - config: UserModuleConfig with updated values
  Future<void> updateModuleConfig(UserModuleConfig config);

  /// Enable/disable module
  ///
  /// Sets is_enabled flag without changing configuration.
  /// When disabling: calls module's onModuleDeactivated hook.
  /// When enabling: calls module's onModuleActivated hook.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - moduleId: Module to enable/disable
  /// - isEnabled: true to enable, false to disable
  Future<void> setModuleEnabled(String userId, String moduleId, bool isEnabled);

  /// Delete module configuration
  ///
  /// Permanently removes configuration and all related data.
  /// WARNING: This is destructive. Consider setModuleEnabled(false) instead.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - moduleId: Module to delete
  Future<void> deleteModuleConfig(String userId, String moduleId);
}
```

---

### Step 7.9: Create ModuleConfigLocalDataSource

**File:** `lib/modules/shared/data/datasources/module_config_local_datasource.dart`
**Purpose:** SQLite operations for module configurations
**Dependencies:** `sqflite`, `database_helper`, models

**Create folder if needed:**
```bash
mkdir -p lib/modules/shared/data/datasources
```

**Implementation:**

```dart
import 'package:sqflite/sqflite.dart';
import '../../domain/models/user_module_config.dart';
import '../../../../shared/constants/database_constants.dart';

/// Local datasource for module configuration CRUD operations
///
/// Performs SQLite queries on user_module_configurations table.
class ModuleConfigLocalDataSource {
  final Database database;

  ModuleConfigLocalDataSource({required this.database});

  /// Get module config by user and module ID
  Future<UserModuleConfig?> getModuleConfig(String userId, String moduleId) async {
    final results = await database.query(
      TABLE_USER_MODULE_CONFIGURATIONS,
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_MODULE_ID = ?',
      whereArgs: [userId, moduleId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    return UserModuleConfig.fromDatabase(results.first);
  }

  /// Get all configs for user
  Future<List<UserModuleConfig>> getAllModuleConfigs(String userId) async {
    final results = await database.query(
      TABLE_USER_MODULE_CONFIGURATIONS,
      where: '$USER_MODULE_CONFIGS_USER_ID = ?',
      whereArgs: [userId],
      orderBy: '$USER_MODULE_CONFIGS_ENROLLED_AT DESC',
    );

    return results.map((row) => UserModuleConfig.fromDatabase(row)).toList();
  }

  /// Get active configs for user
  Future<List<UserModuleConfig>> getActiveModuleConfigs(String userId) async {
    final results = await database.query(
      TABLE_USER_MODULE_CONFIGURATIONS,
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_IS_ENABLED = 1',
      whereArgs: [userId],
      orderBy: '$USER_MODULE_CONFIGS_ENROLLED_AT DESC',
    );

    return results.map((row) => UserModuleConfig.fromDatabase(row)).toList();
  }

  /// Get active module IDs only
  Future<List<String>> getActiveModuleIds(String userId) async {
    final results = await database.query(
      TABLE_USER_MODULE_CONFIGURATIONS,
      columns: [USER_MODULE_CONFIGS_MODULE_ID],
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_IS_ENABLED = 1',
      whereArgs: [userId],
    );

    return results.map((row) => row[USER_MODULE_CONFIGS_MODULE_ID] as String).toList();
  }

  /// Insert new config
  Future<void> insertModuleConfig(UserModuleConfig config) async {
    await database.insert(
      TABLE_USER_MODULE_CONFIGURATIONS,
      config.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.fail, // Throw error if exists
    );
  }

  /// Update existing config
  Future<void> updateModuleConfig(UserModuleConfig config) async {
    final rowsUpdated = await database.update(
      TABLE_USER_MODULE_CONFIGURATIONS,
      config.toDatabase(),
      where: '$USER_MODULE_CONFIGS_ID = ?',
      whereArgs: [config.id],
    );

    if (rowsUpdated == 0) {
      throw Exception('Module config not found: ${config.id}');
    }
  }

  /// Update is_enabled flag
  Future<void> updateModuleEnabled(String userId, String moduleId, bool isEnabled) async {
    final rowsUpdated = await database.update(
      TABLE_USER_MODULE_CONFIGURATIONS,
      {
        USER_MODULE_CONFIGS_IS_ENABLED: isEnabled ? 1 : 0,
        USER_MODULE_CONFIGS_UPDATED_AT: DateTime.now().toIso8601String(),
      },
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_MODULE_ID = ?',
      whereArgs: [userId, moduleId],
    );

    if (rowsUpdated == 0) {
      throw Exception('Module config not found for user $userId, module $moduleId');
    }
  }

  /// Delete config
  Future<void> deleteModuleConfig(String userId, String moduleId) async {
    await database.delete(
      TABLE_USER_MODULE_CONFIGURATIONS,
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_MODULE_ID = ?',
      whereArgs: [userId, moduleId],
    );
  }
}
```

---

### Step 7.10: Create ModuleConfigRepositoryImpl

**File:** `lib/modules/shared/data/repositories/module_config_repository_impl.dart`
**Purpose:** Concrete repository implementation
**Dependencies:** Interface, datasource, ModuleRegistry

**Create folder if needed:**
```bash
mkdir -p lib/modules/shared/data/repositories
```

**Implementation:**

```dart
import '../../domain/repositories/module_config_repository.dart';
import '../../domain/models/user_module_config.dart';
import '../../domain/services/module_registry.dart';
import '../datasources/module_config_local_datasource.dart';

/// Repository implementation for module configurations
///
/// Delegates database operations to datasource.
/// Adds business logic for module lifecycle hooks.
class ModuleConfigRepositoryImpl implements ModuleConfigRepository {
  final ModuleConfigLocalDataSource dataSource;

  ModuleConfigRepositoryImpl({required this.dataSource});

  @override
  Future<UserModuleConfig?> getModuleConfig(String userId, String moduleId) {
    return dataSource.getModuleConfig(userId, moduleId);
  }

  @override
  Future<List<UserModuleConfig>> getAllModuleConfigs(String userId) {
    return dataSource.getAllModuleConfigs(userId);
  }

  @override
  Future<List<UserModuleConfig>> getActiveModuleConfigs(String userId) {
    return dataSource.getActiveModuleConfigs(userId);
  }

  @override
  Future<List<String>> getActiveModuleIds(String userId) {
    return dataSource.getActiveModuleIds(userId);
  }

  @override
  Future<void> addModuleConfig(UserModuleConfig config) async {
    // Insert into database
    await dataSource.insertModuleConfig(config);

    // Call module lifecycle hook
    if (config.isEnabled) {
      final module = ModuleRegistry.getModule(config.moduleId);
      if (module != null) {
        await module.onModuleActivated(
          userId: config.userId,
          config: config.configuration,
        );
      }
    }
  }

  @override
  Future<void> updateModuleConfig(UserModuleConfig config) async {
    await dataSource.updateModuleConfig(config);
  }

  @override
  Future<void> setModuleEnabled(String userId, String moduleId, bool isEnabled) async {
    // Get current config to pass to lifecycle hooks
    final currentConfig = await dataSource.getModuleConfig(userId, moduleId);
    if (currentConfig == null) {
      throw Exception('Cannot enable/disable non-existent module config');
    }

    // Update database
    await dataSource.updateModuleEnabled(userId, moduleId, isEnabled);

    // Call appropriate lifecycle hook
    final module = ModuleRegistry.getModule(moduleId);
    if (module != null) {
      if (isEnabled) {
        await module.onModuleActivated(
          userId: userId,
          config: currentConfig.configuration,
        );
      } else {
        await module.onModuleDeactivated(userId: userId);
      }
    }
  }

  @override
  Future<void> deleteModuleConfig(String userId, String moduleId) async {
    // Ensure module is deactivated first
    final config = await dataSource.getModuleConfig(userId, moduleId);
    if (config != null && config.isEnabled) {
      await setModuleEnabled(userId, moduleId, false);
    }

    // Delete from database
    await dataSource.deleteModuleConfig(userId, moduleId);
  }
}
```

**Why lifecycle hooks in repository?**
- Repository is where business logic lives
- Ensures hooks are always called when module state changes
- Module-specific notification scheduling happens automatically

---

## Part F: Update Light Module (Reference Implementation)

### Step 7.11: Create LightModule Class

**File:** `lib/modules/light/domain/light_module.dart`
**Purpose:** Light module implementation of ModuleInterface
**Dependencies:** ModuleInterface, module_metadata, Light screens

**Create folder if needed:**
```bash
mkdir -p lib/modules/light/domain
```

**Implementation:**

```dart
import 'package:flutter/material.dart';
import '../../shared/domain/interfaces/module_interface.dart';
import '../../shared/domain/models/user_module_config.dart';
import '../../shared/constants/module_metadata.dart';
import '../../shared/utils/datetime_helpers.dart';
import '../presentation/screens/light_config_screen.dart';
// TODO: Import notification service when implemented

/// Light Therapy Module
///
/// Reference implementation of ModuleInterface.
/// Other modules should follow this pattern.
class LightModule implements ModuleInterface {
  @override
  String get moduleId => 'light';

  @override
  ModuleMetadata getMetadata() {
    return moduleMetadata['light']!;
  }

  @override
  Widget getConfigurationScreen({
    required String userId,
    UserModuleConfig? config,
  }) {
    // Return Light module's configuration screen
    // TODO: Create LightConfigScreen in future phase
    return LightConfigScreen(
      userId: userId,
      existingConfig: config,
    );
  }

  @override
  Map<String, dynamic> getDefaultConfiguration({
    required String userId,
    TimeOfDay? userWakeTime,
    TimeOfDay? userBedTime,
  }) {
    // Calculate default morning light time (30 min after wake)
    final wakeTime = userWakeTime ?? const TimeOfDay(hour: 7, minute: 0);
    final morningLightTime = DateTimeHelpers.addHours(wakeTime, 0.5);

    return {
      'mode': 'standard', // 'standard' or 'advanced'
      'sessions': [
        {
          'type': 'sunlight', // sunlight, lightbox, bluelight, redlight
          'time': DateTimeHelpers.formatTimeOfDay(morningLightTime),
          'duration': 20, // minutes
          'enabled': true,
          'notificationEnabled': true,
          'notificationOffset': 0, // minutes before session time
        }
      ],
    };
  }

  @override
  String? validateConfiguration(Map<String, dynamic> config) {
    // Validate mode
    final mode = config['mode'];
    if (mode == null || (mode != 'standard' && mode != 'advanced')) {
      return 'Invalid mode. Must be "standard" or "advanced".';
    }

    // Validate sessions
    final sessions = config['sessions'] as List?;
    if (sessions == null || sessions.isEmpty) {
      return 'At least one light session is required.';
    }

    // Validate each session
    for (final session in sessions) {
      if (session is! Map) {
        return 'Invalid session format.';
      }

      // Check required fields
      if (!session.containsKey('type') ||
          !session.containsKey('time') ||
          !session.containsKey('duration')) {
        return 'Session missing required fields (type, time, duration).';
      }

      // Validate duration
      final duration = session['duration'];
      if (duration is! int || duration < 5 || duration > 60) {
        return 'Session duration must be between 5 and 60 minutes.';
      }
    }

    return null; // Valid
  }

  @override
  Future<void> onModuleActivated({
    required String userId,
    required Map<String, dynamic> config,
  }) async {
    // TODO: Schedule notifications for light sessions
    // final notificationService = ...;
    // await notificationService.scheduleLightReminders(userId, config);

    print('Light module activated for user $userId');
  }

  @override
  Future<void> onModuleDeactivated({required String userId}) async {
    // TODO: Cancel all light module notifications
    // final notificationService = ...;
    // await notificationService.cancelModuleNotifications(userId, 'light');

    print('Light module deactivated for user $userId');
  }

  @override
  Future<void> onSleepScheduleChanged({
    required String userId,
    required TimeOfDay newWakeTime,
    required TimeOfDay newBedTime,
  }) async {
    // TODO: Recalculate morning light session time
    // Get user's config, update session time to 30 min after new wake time
    // Save updated config

    print('Light module: Sleep schedule changed for user $userId');
  }
}
```

**Note:** LightConfigScreen will be created in future phase when implementing Light module UI.

---

### Step 7.12: Register Light Module

**File:** `lib/main.dart`
**Purpose:** Register Light module at app startup
**Location:** At the very beginning of main() function

**Add import:**
```dart
import 'modules/light/domain/light_module.dart';
import 'modules/shared/domain/services/module_registry.dart';
```

**In main() function, BEFORE runApp():**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================================
  // Register Modules
  // ============================================================================

  ModuleRegistry.register(LightModule());
  // TODO: Register other modules as they're implemented
  // ModuleRegistry.register(SportModule());
  // ModuleRegistry.register(MeditationModule());

  // ... rest of main() function (database init, etc.)

  runApp(const MyApp());
}
```

---

## Part G: Provider Registration

### Step 7.13: Wire Up Providers

**File:** `lib/main.dart`
**Purpose:** Register module config repository with Provider
**Pattern:** Follow Phase 5 provider registration pattern

**Add imports:**
```dart
import 'modules/shared/data/datasources/module_config_local_datasource.dart';
import 'modules/shared/data/repositories/module_config_repository_impl.dart';
import 'modules/shared/domain/repositories/module_config_repository.dart';
```

**In MultiProvider providers list, add AFTER database initialization:**

```dart
// ============================================================================
// Module Configuration Repository
// ============================================================================

// DataSource (needs database)
Provider<ModuleConfigLocalDataSource>(
  create: (_) => ModuleConfigLocalDataSource(database: database),
),

// Repository (needs datasource)
Provider<ModuleConfigRepository>(
  create: (context) => ModuleConfigRepositoryImpl(
    dataSource: context.read<ModuleConfigLocalDataSource>(),
  ),
),
```

**IMPORTANT: Provider Order**
- Database initialization FIRST
- DataSource SECOND (depends on database)
- Repository THIRD (depends on datasource)

---

## Testing Checklist

### Database Tests:

- [ ] Test migration v5 creates table with correct schema
- [ ] Test UNIQUE index prevents duplicate user+module configs
- [ ] Test foreign key cascade deletes configs when user deleted
- [ ] Test is_enabled defaults to 1 for new records
- [ ] Test configuration column stores valid JSON

### Model Tests:

- [ ] Test UserModuleConfig.fromDatabase conversion (all fields)
- [ ] Test UserModuleConfig.toDatabase conversion (all fields)
- [ ] Test getConfigValue() with various types (String, int, List, Map)
- [ ] Test updateConfigValue() returns new instance (immutable)
- [ ] Test copyWith() preserves unchanged fields

### DataSource Tests:

- [ ] Test getModuleConfig() returns null for non-existent config
- [ ] Test getAllModuleConfigs() returns empty list for new user
- [ ] Test getActiveModuleConfigs() filters by is_enabled = 1
- [ ] Test getActiveModuleIds() returns only module IDs
- [ ] Test insertModuleConfig() throws on duplicate user+module
- [ ] Test updateModuleConfig() throws if config doesn't exist
- [ ] Test updateModuleEnabled() updates is_enabled and updated_at
- [ ] Test deleteModuleConfig() removes config from database

### Repository Tests:

- [ ] Test addModuleConfig() calls module.onModuleActivated()
- [ ] Test setModuleEnabled(true) calls module.onModuleActivated()
- [ ] Test setModuleEnabled(false) calls module.onModuleDeactivated()
- [ ] Test deleteModuleConfig() deactivates before deleting
- [ ] Test repository throws exception for non-existent configs

### ModuleRegistry Tests:

- [ ] Test register() adds module to registry
- [ ] Test register() replaces existing module with same ID
- [ ] Test register() throws on empty module ID
- [ ] Test getAllModules() returns all registered modules
- [ ] Test getModule() returns correct module by ID
- [ ] Test getModule() returns null for unregistered ID
- [ ] Test isRegistered() returns true/false correctly
- [ ] Test clearAll() removes all modules (test cleanup)

### ModuleMetadata Tests:

- [ ] Test getModuleMetadata() returns correct metadata for 'light'
- [ ] Test getModuleMetadata() returns unknown metadata for invalid ID
- [ ] Test getAvailableModules() returns only isAvailable = true
- [ ] Test getPlannedModules() returns only isAvailable = false
- [ ] Test all module IDs in metadata map are unique

### LightModule Tests:

- [ ] Test getMetadata() returns light module metadata
- [ ] Test getDefaultConfiguration() generates valid config
- [ ] Test getDefaultConfiguration() calculates time 30 min after wake
- [ ] Test validateConfiguration() accepts valid config
- [ ] Test validateConfiguration() rejects invalid mode
- [ ] Test validateConfiguration() rejects empty sessions
- [ ] Test validateConfiguration() rejects invalid duration (< 5 or > 60)
- [ ] Test onModuleActivated() executes without errors
- [ ] Test onModuleDeactivated() executes without errors

### Integration Tests:

**Full Module Activation Flow:**
- [ ] Register Light module → Add config → Verify in database
- [ ] Verify onModuleActivated() called
- [ ] Verify configuration JSON stored correctly
- [ ] Verify enrolled_at and updated_at timestamps set

**Full Module Deactivation Flow:**
- [ ] Deactivate module → Verify is_enabled = 0
- [ ] Verify onModuleDeactivated() called
- [ ] Verify configuration still exists in database

**Provider Integration:**
- [ ] Verify ModuleConfigRepository accessible via context.read()
- [ ] Verify repository operations work through Provider

---

## Completion Checklist

### Code Quality:
- [ ] Run `dart run build_runner build` - Generate JSON serialization
- [ ] Run `flutter analyze` - Fix ALL warnings
- [ ] Run `dart format .` - Format all modified files
- [ ] Add documentation comments to all public APIs
- [ ] Add inline comments for complex logic

### Database:
- [ ] Test migration on fresh database (uninstall app, reinstall)
- [ ] Test migration from v4 to v5 (upgrade scenario)
- [ ] Verify indexes created correctly (check with SQLite viewer)
- [ ] Test with sample data (insert, query, update, delete)

### Documentation:
- [ ] Update README.md with Phase 7 completion status
- [ ] Document module registration process for juniors
- [ ] Add examples of implementing ModuleInterface
- [ ] Explain configuration JSON structure for each module

---

## For Juniors: How to Implement a New Module

When you implement a new module (Sport, Meditation, etc.), follow this checklist:

### 1. Create Module Class
- [ ] Create `lib/modules/[module_name]/domain/[module_name]_module.dart`
- [ ] Implement `ModuleInterface`
- [ ] Define `getDefaultConfiguration()` with science-based defaults
- [ ] Implement `validateConfiguration()` with module-specific rules
- [ ] Implement `onModuleActivated()` - schedule notifications
- [ ] Implement `onModuleDeactivated()` - cancel notifications

### 2. Add Module Metadata
- [ ] Add entry to `moduleMetadata` map in `module_metadata.dart`
- [ ] Choose appropriate icon and color
- [ ] Write short description (1-2 sentences)
- [ ] Write long description (benefits, usage)
- [ ] Set `isAvailable: true` when module ready

### 3. Register Module
- [ ] Add to `main.dart`: `ModuleRegistry.register(YourModule())`

### 4. Test Your Module
- [ ] Unit test: Default configuration generation
- [ ] Unit test: Configuration validation
- [ ] Integration test: Activate module → verify in database
- [ ] Integration test: Deactivate module → verify notifications cancelled

**That's it!** Your module automatically appears in Habits Lab.

---

## After Phase 7 Complete

**Features Delivered:**
- ✅ Complete module management framework
- ✅ Database schema for module configurations
- ✅ ModuleInterface contract for all modules
- ✅ ModuleRegistry for module discovery
- ✅ Repository pattern for configuration CRUD
- ✅ Light module as reference implementation
- ✅ Foundation for Habits Lab UI (next phase)

**Next Steps:**
1. **Implement Habits Lab UI** (Juniors) - Uses ModuleRegistry and ModuleConfigRepository
2. **Implement Light Config Screen** - Allows users to customize Light module
3. **Implement Sport Module** - Follow Light module pattern
4. **Implement remaining modules** - Meditation, Temperature, Mealtime, etc.

**UI Implementation Guide (for juniors):**
- Read `HABITS_LAB_IMPLEMENTATION_PLAN.md` for detailed UI specs
- Use `ModuleRegistry.getAllModules()` to get available modules
- Use `ModuleConfigRepository` to add/remove/update modules
- Navigate to module config screens via `module.getConfigurationScreen()`

---

## Notes

**Why Interface + Registry Pattern?**
- **Decoupling:** Habits Lab doesn't need to know about specific modules
- **Scalability:** Add new modules without changing Habits Lab code
- **Consistency:** All modules follow same patterns
- **Testing:** Easy to mock modules for testing

**Why JSON Configuration?**
- **Flexibility:** Each module has different settings (no rigid schema)
- **Evolution:** Add new settings without database migrations
- **Future-proof:** Easy to add new modules with unique configurations

**Configuration Examples:**

**Light Module:**
```json
{
  "mode": "standard",
  "sessions": [
    {"type": "sunlight", "time": "07:30", "duration": 20, ...}
  ]
}
```

**Sport Module (future):**
```json
{
  "mode": "advanced",
  "sessions": [
    {"type": "hiit", "time": "06:00", "duration": 30, "intensity": "high", ...}
  ],
  "wearableSync": true
}
```

**Meditation Module (future):**
```json
{
  "favoriteSessionIds": ["session-123", "session-456"],
  "defaultDuration": 10,
  "reminderTime": "21:00"
}
```

**Security Considerations:**
- Configuration JSON validated before saving
- Module-specific validation rules in `validateConfiguration()`
- No user input directly stored without validation

**Performance:**
- ModuleRegistry is in-memory (fast lookups)
- Database queries use indexes (fast filtering by user_id, is_enabled)
- JSON encoding/decoding is fast for small configurations

**Estimated Time:** 6-8 hours
- Database migration & constants: 30 minutes
- ModuleMetadata system: 45 minutes
- ModuleInterface + Registry: 60 minutes
- Data models (UserModuleConfig): 45 minutes
- Repository pattern (interface, datasource, impl): 90 minutes
- Light module implementation: 60 minutes
- Provider registration: 15 minutes
- Testing & debugging: 90 minutes
- Documentation: 30 minutes
