# Shared Module Infrastructure - Implementation Plan

## Overview
Implement the shared module infrastructure that provides common patterns, base classes, utilities, and services used across all intervention modules. This foundation ensures consistency, reduces code duplication, and establishes a unified user experience.

**Core Principle:** Consistency through shared infrastructure. Extract common patterns as they emerge, validate with real usage, avoid premature abstraction.

## Prerequisites
- ✅ **Phase 1-5 completed:** MVVM + Provider setup, database infrastructure
- 📚 **Read:** SHARED_README.md for complete vision
- 🎯 **Strategy:** Iterative extraction - implement essentials first, extract more as patterns emerge

## Goals
- Create foundational base models used by all modules
- Implement critical utilities (DateTime handling, validation)
- Build core shared services (notifications, correlation)
- Develop reusable UI widgets (time slider, activity tracking)
- **Expected outcome:** Solid foundation enabling rapid module development

---

## 🎯 Implementation Strategy: Phased Approach

### Phase S.1: Essential Foundation (BEFORE Light Module)
**Implement these first - required for all modules**
- Base domain models (InterventionActivity, UserModuleConfig, Module)
- DateTimeHelpers utility
- Database constants for shared tables
- **Time: 4-6 hours**
- **Why: Every module needs these immediately**

### Phase S.2: Light Module Implementation
**Implement Light module using Phase S.1 foundation**
- Light module will have inline code for time slider, notifications, etc.
- Identify patterns that emerge during implementation
- **Time: 10-12 hours (see LIGHT_PLAN.md)**
- **Why: Real-world validation of patterns**

### Phase S.3: Extraction After Light (AFTER Light Module Works)
**Extract proven patterns from Light**
- TimeSliderWidget (validated with real usage)
- ColorSchemeHelper (validated with Light's color logic)
- Notification scheduling patterns
- **Time: 3-4 hours**
- **Why: Only extract what's proven useful**

### Phase S.4: Sport Module with Shared Components
**Implement Sport using extracted shared components**
- Test that shared components work for different use cases
- Refine shared components based on Sport's needs
- Extract additional patterns if they emerge
- **Time: 12-14 hours (see SPORT_PLAN.md)**
- **Why: Validates shared components are reusable**

### Phase S.5: Continue Pattern
**Each subsequent module:**
- Uses existing shared components
- Identifies new patterns to extract
- Contributes to shared infrastructure
- **Why: Organic growth, real-world driven**

---

## Phase S.1: Essential Foundation (Implement First)

### Step S1.1: Base Domain Models

**File:** `lib/modules/shared/domain/models/intervention_activity.dart`

**Purpose:** Base model for ALL intervention tracking

**Class: InterventionActivity**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'intervention_activity.g.dart';

@JsonSerializable()
class InterventionActivity {
  final String id;
  final String userId;
  final String moduleId;              // 'light', 'sport', 'meditation', etc.
  final DateTime activityDate;        // The day of intervention
  final bool wasCompleted;
  final DateTime? completedAt;
  final int? durationMinutes;
  final String? timeOfDay;            // 'morning', 'afternoon', 'evening', 'night'
  final String? intensity;            // 'low', 'medium', 'high'
  final Map<String, dynamic>? moduleSpecificData;  // Module-specific JSON
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  InterventionActivity({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.activityDate,
    required this.wasCompleted,
    this.completedAt,
    this.durationMinutes,
    this.timeOfDay,
    this.intensity,
    this.moduleSpecificData,
    this.notes,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  // JSON serialization (for API)
  factory InterventionActivity.fromJson(Map<String, dynamic> json) =>
      _$InterventionActivityFromJson(json);

  Map<String, dynamic> toJson() => _$InterventionActivityToJson(this);

  // Database serialization (for SQLite)
  factory InterventionActivity.fromDatabase(Map<String, dynamic> map) {
    return InterventionActivity(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      moduleId: map['module_id'] as String,
      activityDate: DatabaseDateUtils.parseDateTime(map['activity_date'] as String),
      wasCompleted: (map['was_completed'] as int) == 1,
      completedAt: DatabaseDateUtils.parseDateTimeNullable(map['completed_at'] as String?),
      durationMinutes: map['duration_minutes'] as int?,
      timeOfDay: map['time_of_day'] as String?,
      intensity: map['intensity'] as String?,
      moduleSpecificData: map['module_specific_data'] != null
          ? json.decode(map['module_specific_data'] as String) as Map<String, dynamic>
          : null,
      notes: map['notes'] as String?,
      createdAt: DatabaseDateUtils.parseDateTime(map['created_at'] as String),
      updatedAt: DatabaseDateUtils.parseDateTime(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'user_id': userId,
      'module_id': moduleId,
      'activity_date': DatabaseDateUtils.toIso8601String(activityDate),
      'was_completed': wasCompleted ? 1 : 0,
      'completed_at': DatabaseDateUtils.toIso8601StringNullable(completedAt),
      'duration_minutes': durationMinutes,
      'time_of_day': timeOfDay,
      'intensity': intensity,
      'module_specific_data': moduleSpecificData != null
          ? json.encode(moduleSpecificData)
          : null,
      'notes': notes,
      'created_at': DatabaseDateUtils.toIso8601String(createdAt),
      'updated_at': DatabaseDateUtils.toIso8601String(updatedAt),
    };
  }

  InterventionActivity copyWith({
    String? id,
    String? userId,
    String? moduleId,
    DateTime? activityDate,
    bool? wasCompleted,
    DateTime? completedAt,
    int? durationMinutes,
    String? timeOfDay,
    String? intensity,
    Map<String, dynamic>? moduleSpecificData,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InterventionActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moduleId: moduleId ?? this.moduleId,
      activityDate: activityDate ?? this.activityDate,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      intensity: intensity ?? this.intensity,
      moduleSpecificData: moduleSpecificData ?? this.moduleSpecificData,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

**After creating:** Run `dart run build_runner build`

---

**File:** `lib/modules/shared/domain/models/user_module_config.dart`

**Purpose:** User's configuration for any module

**Class: UserModuleConfig**

```dart
@JsonSerializable()
class UserModuleConfig {
  final String id;
  final String userId;
  final String moduleId;
  final bool isEnabled;
  final Map<String, dynamic> configuration;  // Module-specific JSON config
  final DateTime enrolledAt;
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

  // Helper to get typed config value
  T? getConfigValue<T>(String key) {
    return configuration[key] as T?;
  }

  // Helper to update single config value
  UserModuleConfig updateConfig(String key, dynamic value) {
    final newConfig = Map<String, dynamic>.from(configuration);
    newConfig[key] = value;
    return copyWith(
      configuration: newConfig,
      updatedAt: DateTime.now(),
    );
  }

  factory UserModuleConfig.fromJson(Map<String, dynamic> json) =>
      _$UserModuleConfigFromJson(json);

  Map<String, dynamic> toJson() => _$UserModuleConfigToJson(this);

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
}
```

---

**File:** `lib/modules/shared/domain/models/module.dart`

**Purpose:** Module metadata (from modules table)

**Class: Module**

```dart
@JsonSerializable()
class Module {
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;

  Module({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.icon,
    required this.isActive,
    required this.createdAt,
  });

  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);
  Map<String, dynamic> toJson() => _$ModuleToJson(this);

  factory Module.fromDatabase(Map<String, dynamic> map) {
    return Module(
      id: map['id'] as String,
      name: map['name'] as String,
      displayName: map['display_name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DatabaseDateUtils.parseDateTime(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'icon': icon,
      'is_active': isActive ? 1 : 0,
      'created_at': DatabaseDateUtils.toIso8601String(createdAt),
    };
  }
}
```

---

### Step S1.2: DateTimeHelpers Utility

**File:** `lib/modules/shared/utils/datetime_helpers.dart`

**Purpose:** DateTime operations used by all modules

```dart
import 'package:flutter/material.dart';

class DateTimeHelpers {
  /// Calculate time relative to wake time
  /// Example: 30 minutes after waking
  static DateTime calculateTimeRelativeToWake(Duration offset, DateTime wakeTime) {
    return wakeTime.add(offset);
  }

  /// Calculate time relative to bed time
  /// Example: 2 hours before bed
  static DateTime calculateTimeRelativeToBed(Duration offset, DateTime bedTime) {
    return bedTime.subtract(offset);
  }

  /// Format relative time description
  /// Example: "30 min after waking", "2 hours before bed"
  static String formatRelativeTime(DateTime time, DateTime referenceTime, {bool isBeforeReference = false}) {
    final difference = isBeforeReference
        ? referenceTime.difference(time)
        : time.difference(referenceTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ${isBeforeReference ? "before" : "after"}';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (minutes == 0) {
        return '$hours hour${hours != 1 ? "s" : ""} ${isBeforeReference ? "before" : "after"}';
      }
      return '$hours hour${hours != 1 ? "s" : ""} $minutes min ${isBeforeReference ? "before" : "after"}';
    }
  }

  /// Parse TimeOfDay from HH:mm string
  static TimeOfDay parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Convert TimeOfDay to DateTime (today)
  static DateTime timeOfDayToDateTime(TimeOfDay time, DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  /// Format TimeOfDay to HH:mm string
  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Calculate hours between two TimeOfDay
  static double calculateHoursBetween(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    var diff = endMinutes - startMinutes;
    if (diff < 0) diff += 24 * 60; // Handle overnight

    return diff / 60.0;
  }

  /// Add hours to TimeOfDay
  static TimeOfDay addHours(TimeOfDay time, double hours) {
    final totalMinutes = time.hour * 60 + time.minute + (hours * 60).toInt();
    final normalizedMinutes = totalMinutes % (24 * 60);

    return TimeOfDay(
      hour: normalizedMinutes ~/ 60,
      minute: normalizedMinutes % 60,
    );
  }

  /// Subtract hours from TimeOfDay
  static TimeOfDay subtractHours(TimeOfDay time, double hours) {
    return addHours(time, -hours);
  }

  /// Get midpoint between two TimeOfDay
  static TimeOfDay midpoint(TimeOfDay start, TimeOfDay end) {
    final hoursBetween = calculateHoursBetween(start, end);
    return addHours(start, hoursBetween / 2);
  }

  /// Determine time of day category
  static String getTimeOfDayCategory(TimeOfDay time) {
    if (time.hour >= 5 && time.hour < 12) return 'morning';
    if (time.hour >= 12 && time.hour < 17) return 'afternoon';
    if (time.hour >= 17 && time.hour < 21) return 'evening';
    return 'night';
  }
}
```

---

### Step S1.3: Update Database Constants

**File:** `lib/shared/constants/database_constants.dart`

**Add constants for shared tables:**

```dart
// Shared module tables
const String TABLE_MODULES = 'modules';
const String TABLE_USER_MODULE_CONFIGURATIONS = 'user_module_configurations';
const String TABLE_INTERVENTION_ACTIVITIES = 'intervention_activities';

// Module columns
const String MODULES_ID = 'id';
const String MODULES_NAME = 'name';
const String MODULES_DISPLAY_NAME = 'display_name';
const String MODULES_DESCRIPTION = 'description';
const String MODULES_ICON = 'icon';
const String MODULES_IS_ACTIVE = 'is_active';
const String MODULES_CREATED_AT = 'created_at';

// User module config columns
const String USER_MODULE_CONFIGS_ID = 'id';
const String USER_MODULE_CONFIGS_USER_ID = 'user_id';
const String USER_MODULE_CONFIGS_MODULE_ID = 'module_id';
const String USER_MODULE_CONFIGS_IS_ENABLED = 'is_enabled';
const String USER_MODULE_CONFIGS_CONFIGURATION = 'configuration';
const String USER_MODULE_CONFIGS_ENROLLED_AT = 'enrolled_at';
const String USER_MODULE_CONFIGS_UPDATED_AT = 'updated_at';

// Intervention activity columns
const String INTERVENTION_ACTIVITIES_ID = 'id';
const String INTERVENTION_ACTIVITIES_USER_ID = 'user_id';
const String INTERVENTION_ACTIVITIES_MODULE_ID = 'module_id';
const String INTERVENTION_ACTIVITIES_ACTIVITY_DATE = 'activity_date';
const String INTERVENTION_ACTIVITIES_WAS_COMPLETED = 'was_completed';
const String INTERVENTION_ACTIVITIES_COMPLETED_AT = 'completed_at';
const String INTERVENTION_ACTIVITIES_DURATION_MINUTES = 'duration_minutes';
const String INTERVENTION_ACTIVITIES_TIME_OF_DAY = 'time_of_day';
const String INTERVENTION_ACTIVITIES_INTENSITY = 'intensity';
const String INTERVENTION_ACTIVITIES_MODULE_SPECIFIC_DATA = 'module_specific_data';
const String INTERVENTION_ACTIVITIES_NOTES = 'notes';
const String INTERVENTION_ACTIVITIES_CREATED_AT = 'created_at';
const String INTERVENTION_ACTIVITIES_UPDATED_AT = 'updated_at';
```

---

## Phase S.3: Extraction After Light (Extract Proven Patterns)

### Step S3.1: Extract TimeSliderWidget

**Only extract AFTER Light module proves the pattern works**

**File:** `lib/modules/shared/presentation/widgets/time_slider_widget.dart`

**Purpose:** Reusable time slider with color-coded feedback

*(Full implementation deferred until after Light module validates the pattern)*

---

### Step S3.2: Extract ColorSchemeHelper

**File:** `lib/modules/shared/utils/color_scheme_helper.dart`

**Purpose:** Generate color gradients for time feedback

*(Extract from Light's color logic after validation)*

---

## Testing Checklist (Phase S.1)

### Unit Tests:
- [ ] Test InterventionActivity fromDatabase/toDatabase with all fields
- [ ] Test UserModuleConfig getConfigValue helper
- [ ] Test Module fromDatabase conversion
- [ ] Test DateTimeHelpers.calculateHoursBetween
- [ ] Test DateTimeHelpers.addHours with overnight rollover
- [ ] Test DateTimeHelpers.midpoint calculation

### Integration Tests:
- [ ] Insert InterventionActivity to database, read back, verify identical
- [ ] Update UserModuleConfig.configuration, verify persists
- [ ] Test all DateTimeHelpers with edge cases (midnight, etc.)

---

## Notes

**Why Phased Approach?**
- Avoids premature abstraction
- Validates patterns with real usage
- Reduces refactoring (extract proven code, not guessed code)
- Faster initial progress

**What NOT to Implement Yet:**
- TimeSliderWidget (wait for Light to validate)
- ColorSchemeHelper (wait for Light's color logic)
- Complex services (notification, correlation) - build inline in Light first
- UI widgets - extract only after seeing actual usage

**Essential Foundation (Phase S.1):**
- Base models: Every module needs immediately
- DateTimeHelpers: Every module uses immediately
- Database constants: Required for all queries

**Extraction Triggers:**
- After Light works: Extract time slider, color scheme
- After Sport works: Extract intensity validation
- After Temperature works: Extract dual-type patterns
- After 3+ modules: Extract notification patterns, correlation service

**Estimated Time:**
- Phase S.1 (Essential Foundation): 4-6 hours
- Phase S.3 (Extraction after Light): 3-4 hours
- Future extractions: 2-3 hours per pattern

**This plan follows: "Make it work, make it right, make it fast"**
