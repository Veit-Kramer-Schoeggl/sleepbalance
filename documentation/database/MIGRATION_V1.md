# Migration V1: Initial Database Schema

**Version:** 1
**Status:** ✅ Active
**Purpose:** Creates the core database schema for SleepBalance application

## Overview

Migration V1 establishes the foundational database structure, creating all core tables required for user management, sleep tracking, module-based interventions, and correlation analysis.

## Tables Created

### 1. `users`

Stores user profiles, authentication credentials, sleep preferences, and health context.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID for user |
| `email` | TEXT | UNIQUE NOT NULL | User email address |
| `password_hash` | TEXT | | Bcrypt hashed password |
| `first_name` | TEXT | NOT NULL | User's first name |
| `last_name` | TEXT | NOT NULL | User's last name |
| `birth_date` | TEXT | NOT NULL | User's date of birth (DATE format) |
| `timezone` | TEXT | NOT NULL | IANA timezone (e.g., 'America/New_York') |
| `target_sleep_duration` | INTEGER | | Target sleep duration in minutes |
| `target_bed_time` | TEXT | | Target bedtime (HH:mm format) |
| `target_wake_time` | TEXT | | Target wake time (HH:mm format) |
| `has_sleep_disorder` | INTEGER | NOT NULL DEFAULT 0 | Boolean: has diagnosed sleep disorder |
| `sleep_disorder_type` | TEXT | | Type of disorder (e.g., 'insomnia', 'sleep_apnea') |
| `takes_sleep_medication` | INTEGER | NOT NULL DEFAULT 0 | Boolean: takes sleep medication |
| `preferred_unit_system` | TEXT | NOT NULL DEFAULT 'metric' | 'metric' or 'imperial' |
| `language` | TEXT | NOT NULL DEFAULT 'en' | Language code (e.g., 'en', 'de') |
| `created_at` | TEXT | NOT NULL | Creation timestamp |
| `updated_at` | TEXT | NOT NULL | Last update timestamp |
| `synced_at` | TEXT | | Last sync timestamp (NULL = not synced) |
| `is_deleted` | INTEGER | NOT NULL DEFAULT 0 | Soft delete flag for sync |

**Purpose:**
Central user profile table supporting future multi-user capability and backend sync. Sleep context fields (`has_sleep_disorder`, `sleep_disorder_type`) provide important context for analysis, as users with sleep disorders have different baseline expectations.

---

### 2. `sleep_records`

Stores aggregated nightly sleep data from wearable devices.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID for record |
| `user_id` | TEXT | NOT NULL, FK → users(id) | Owner of this sleep record |
| `sleep_date` | TEXT | NOT NULL | The night (DATE format, e.g., '2025-10-29') |
| `bed_time` | TEXT | | When user went to bed (TIMESTAMP) |
| `sleep_start_time` | TEXT | | When user fell asleep (TIMESTAMP) |
| `sleep_end_time` | TEXT | | When user woke up (TIMESTAMP) |
| `wake_time` | TEXT | | When user got out of bed (TIMESTAMP) |
| `total_sleep_time` | INTEGER | | Total minutes asleep |
| `deep_sleep_duration` | INTEGER | | Deep sleep minutes |
| `rem_sleep_duration` | INTEGER | | REM sleep minutes |
| `light_sleep_duration` | INTEGER | | Light sleep minutes |
| `awake_duration` | INTEGER | | Awake minutes during night |
| `avg_heart_rate` | REAL | | Average heart rate (bpm) |
| `min_heart_rate` | REAL | | Minimum heart rate (bpm) |
| `max_heart_rate` | REAL | | Maximum heart rate (bpm) |
| `avg_hrv` | REAL | | Average HRV (RMSSD in ms) |
| `avg_breathing_rate` | REAL | | Average breaths per minute |
| `quality_rating` | TEXT | CHECK: 'bad', 'average', 'good' | User's subjective quality rating |
| `quality_notes` | TEXT | | Optional user notes |
| `data_source` | TEXT | NOT NULL | Source (e.g., 'apple_health', 'fitbit') |
| `created_at` | TEXT | NOT NULL | Record creation timestamp |
| `updated_at` | TEXT | NOT NULL | Last update timestamp |
| `synced_at` | TEXT | | Last sync timestamp |
| `is_deleted` | INTEGER | NOT NULL DEFAULT 0 | Soft delete flag |

**Constraints:**
- `UNIQUE(user_id, sleep_date)` - One sleep record per night per user
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`

**Indexes:**
- `idx_sleep_records_user_date` on `(user_id, sleep_date)` - Fast date range queries
- `idx_sleep_records_quality` on `(user_id, quality_rating)` - Filter by quality

**Purpose:**
Stores aggregated nightly sleep metrics. Design decision: aggregates first (not minute-by-minute data) for simpler queries and faster UI performance. Granular time-series data can be added in future migrations without breaking existing code.

---

### 3. `modules`

Defines available intervention modules (e.g., Light Therapy, Sport, Meditation).

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `id` | TEXT | PRIMARY KEY | Module identifier (e.g., 'light', 'sport') |
| `name` | TEXT | UNIQUE NOT NULL | Internal name |
| `display_name` | TEXT | NOT NULL | UI display name (e.g., 'Light Therapy') |
| `description` | TEXT | | Module description |
| `icon` | TEXT | | Icon identifier (legacy - metadata now hardcoded) |
| `is_active` | INTEGER | NOT NULL DEFAULT 1 | Can disable modules app-wide |
| `created_at` | TEXT | NOT NULL | Creation timestamp |

**Purpose:**
Registry of available intervention modules. Used for foreign key relationships and module enumeration.

**Note (Phase 7 Update):** Module metadata (icons, colors, descriptions) is now hardcoded in `lib/modules/shared/constants/module_metadata.dart` for better type safety. This table remains for foreign key relationships.

---

### 4. `user_module_configurations`

Stores each user's module-specific settings and activation status.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID for configuration |
| `user_id` | TEXT | NOT NULL, FK → users(id) | User who owns this config |
| `module_id` | TEXT | NOT NULL, FK → modules(id) | Which module this configures |
| `is_enabled` | INTEGER | NOT NULL DEFAULT 1 | User has enabled this module |
| `configuration` | TEXT (JSON) | | Module-specific settings as JSON |
| `enrolled_at` | TEXT | NOT NULL | When user enrolled in module |
| `updated_at` | TEXT | NOT NULL | Last update timestamp |
| `synced_at` | TEXT | | Last sync timestamp |

**Constraints:**
- `UNIQUE(user_id, module_id)` - One config per user per module
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`
- `FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE`

**Indexes:**
- `idx_user_modules_user` on `(user_id)` - Fast user lookups

**JSON Configuration Example (Light Module):**
```json
{
  "target_time": "07:30",
  "target_duration_minutes": 30,
  "preferred_light_type": "natural_sunlight",
  "notifications": {
    "morning_reminder": {"enabled": true, "time": "07:00"},
    "evening_dim_reminder": {"enabled": true, "time": "20:00"},
    "blue_blocker_reminder": {"enabled": true, "time": "21:00"}
  }
}
```

**Purpose:**
Flexible storage for module-specific settings. JSON approach avoids creating separate configuration tables for each of the 9 modules, making it easy to add new configuration options without schema migrations.

---

### 5. `intervention_activities`

**Core correlation table.** Stores daily intervention tracking for all modules.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID for activity |
| `user_id` | TEXT | NOT NULL, FK → users(id) | User who performed activity |
| `module_id` | TEXT | NOT NULL, FK → modules(id) | Which module (e.g., 'light') |
| `activity_date` | TEXT | NOT NULL | The day intervention was performed (DATE) |
| `was_completed` | INTEGER | NOT NULL | Binary: did user complete it? (required) |
| `completed_at` | TEXT | | When specifically completed (TIMESTAMP, optional) |
| `duration_minutes` | INTEGER | | How long the activity took |
| `time_of_day` | TEXT | CHECK: 'morning', 'afternoon', 'evening', 'night' | When during day |
| `intensity` | TEXT | CHECK: 'low', 'medium', 'high' | Activity intensity |
| `module_specific_data` | TEXT (JSON) | | Module-unique attributes as JSON |
| `notes` | TEXT | | Optional user notes |
| `created_at` | TEXT | NOT NULL | Record creation timestamp |
| `updated_at` | TEXT | NOT NULL | Last update timestamp |
| `synced_at` | TEXT | | Last sync timestamp |
| `is_deleted` | INTEGER | NOT NULL DEFAULT 0 | Soft delete flag |

**Constraints:**
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`
- `FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE`

**Indexes:**
- `idx_intervention_activities_user_date` on `(user_id, activity_date)` - Date range queries
- `idx_intervention_activities_module` on `(module_id, activity_date)` - Module-specific queries

**JSON Example (Light Module):**
```json
{
  "light_type": "natural_sunlight",
  "location": "outdoor",
  "weather": "sunny"
}
```

**Purpose:**
Single table for all intervention tracking across all modules. Key design decision: hybrid approach with common typed fields (`duration_minutes`, `time_of_day`, `intensity`) for cross-module queries, plus JSON for module-specific attributes. Enables correlation analysis like "Does light therapy improve deep sleep?"

---

### 6. `user_sleep_baselines`

Stores pre-computed personal sleep averages for "you vs your average" comparisons.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID for baseline |
| `user_id` | TEXT | NOT NULL, FK → users(id) | User this baseline belongs to |
| `baseline_type` | TEXT | NOT NULL, CHECK: '7_day', '30_day', 'all_time' | Rolling window type |
| `metric_name` | TEXT | NOT NULL | Metric being averaged (e.g., 'avg_deep_sleep') |
| `metric_value` | REAL | NOT NULL | Computed average value |
| `data_range_start` | TEXT | NOT NULL | Start of data range (DATE) |
| `data_range_end` | TEXT | NOT NULL | End of data range (DATE) |
| `computed_at` | TEXT | NOT NULL | When this baseline was calculated |

**Constraints:**
- `UNIQUE(user_id, baseline_type, metric_name, data_range_end)` - One baseline per metric per period
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`

**Indexes:**
- `idx_baselines_user` on `(user_id, baseline_type, metric_name)` - Fast baseline lookups

**Example Data:**
```sql
-- User's average deep sleep for last 7 days
('uuid1', 'user123', '7_day', 'avg_deep_sleep', 85.5, '2025-10-23', '2025-10-29', '2025-10-29 23:00:00')

-- User's average total sleep for last 30 days
('uuid2', 'user123', '30_day', 'avg_total_sleep', 420.0, '2025-09-30', '2025-10-29', '2025-10-29 23:00:00')
```

**Purpose:**
Pre-computed baselines enable fast UI queries for "Tonight vs Your 7-Day Average" comparisons without calculating on-the-fly. Background job runs nightly to update these values.

---

## Migration Script Location

`lib/core/database/migrations/migration_v1.dart`

## Applied

This migration is applied during:
- Fresh database creation (version 1+)
- Automatic on first app launch

## Notes

- All timestamps stored as ISO 8601 strings (TEXT) for SQLite compatibility
- UUIDs stored as TEXT for local-first ID generation
- Soft deletes (`is_deleted` flag) enable sync reliability
- CHECK constraints enforce data validity at database level
- Foreign keys with `ON DELETE CASCADE` ensure referential integrity
