# Database Design

This document describes the database architecture for SleepBalance, including schema design, implementation approach, and migration strategy.

## Overview

**Database Type:** SQLite (local-first) → PostgreSQL (future backend sync)
**Design Pattern:** Hybrid approach (typed columns + JSON flexibility)
**Architecture:** Local-first with offline-first capabilities

## Design Philosophy

### Hybrid Schema Approach

We use a **hybrid design** that combines:
- **Typed columns** for common, frequently-queried attributes
- **JSON fields** for module-specific, flexible data

**Why hybrid?**
- ✅ Type safety and performance for common queries
- ✅ Flexibility to add new modules without schema changes
- ✅ Easy migration from SQLite to PostgreSQL
- ✅ Simpler sync logic (JSON eliminates schema versioning issues)

### Local-First Architecture

**Key Principles:**
- User data lives on device first
- Offline-capable by default
- UUIDs for distributed ID generation
- Sync queue for eventual backend consistency
- Soft deletes for sync reliability

## Core Tables

### 1. Users Table

Stores user profiles and sleep preferences.

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,                    -- UUID
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  birth_date DATE NOT NULL,

  -- Sleep context
  timezone TEXT NOT NULL,                 -- IANA timezone (e.g., 'America/New_York')
  target_sleep_duration INTEGER,          -- minutes (e.g., 480 = 8 hours)
  target_bed_time TEXT,                   -- HH:mm format (e.g., '22:30')
  target_wake_time TEXT,                  -- HH:mm format (e.g., '06:30')

  -- Health context (for analysis)
  has_sleep_disorder BOOLEAN DEFAULT FALSE,
  sleep_disorder_type TEXT,               -- 'insomnia', 'sleep_apnea', etc.
  takes_sleep_medication BOOLEAN DEFAULT FALSE,

  -- Preferences
  preferred_unit_system TEXT DEFAULT 'metric',  -- 'metric' or 'imperial'
  language TEXT DEFAULT 'en',             -- 'en', 'de', etc.

  -- Sync metadata
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP,                    -- NULL = not yet synced
  is_deleted BOOLEAN DEFAULT FALSE        -- Soft delete for sync
);
```

**Key Fields:**
- `timezone`: Critical for sleep timing calculations (users may travel)
- `target_*`: User's sleep goals, used for comparisons
- `has_sleep_disorder`: Context for analysis (users with disorders have different baselines)

---

### 2. Sleep Records Table

Stores nightly sleep data from wearables (aggregated metrics).

```sql
CREATE TABLE sleep_records (
  id TEXT PRIMARY KEY,                    -- UUID
  user_id TEXT NOT NULL,
  sleep_date DATE NOT NULL,               -- The night (e.g., 2025-10-29)

  -- Sleep timing
  bed_time TIMESTAMP,                     -- When user went to bed
  sleep_start_time TIMESTAMP,             -- When user fell asleep (sleep onset)
  sleep_end_time TIMESTAMP,               -- When user woke up
  wake_time TIMESTAMP,                    -- When user got out of bed

  -- Sleep phase durations (in minutes) - AGGREGATED
  total_sleep_time INTEGER,               -- Total time asleep
  deep_sleep_duration INTEGER,
  rem_sleep_duration INTEGER,
  light_sleep_duration INTEGER,
  awake_duration INTEGER,                 -- Awake time during the night

  -- Biometric data (nightly averages)
  avg_heart_rate REAL,                    -- bpm
  min_heart_rate REAL,
  max_heart_rate REAL,
  avg_hrv REAL,                           -- Heart Rate Variability (RMSSD in ms)
  avg_breathing_rate REAL,                -- breaths per minute

  -- Subjective quality (user input)
  quality_rating TEXT CHECK(quality_rating IN ('bad', 'average', 'good')),
  quality_notes TEXT,                     -- Optional user notes

  -- Metadata
  data_source TEXT,                       -- 'apple_health', 'google_fit', 'manual', etc.
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(user_id, sleep_date)             -- One sleep record per night per user
);

CREATE INDEX idx_sleep_records_user_date ON sleep_records(user_id, sleep_date);
CREATE INDEX idx_sleep_records_quality ON sleep_records(user_id, quality_rating);
```

**Important Notes:**
- **Aggregated data only** for now (total deep sleep, not minute-by-minute)
- **Future**: Add `sleep_stages_timeseries` table for fine-grained data
- `quality_rating`: User's subjective feeling (nullable - optional input)
- `data_source`: Track where data came from (useful for debugging/quality checks)

**Design Decision:** Why aggregates first?
- Simpler queries for UI (no need to sum time-series data)
- Faster performance (aggregates are pre-calculated)
- Can add granular data later without breaking existing code

---

### 3. Modules Table

Defines available intervention modules.

```sql
CREATE TABLE modules (
  id TEXT PRIMARY KEY,                    -- e.g., 'light', 'sport', 'meditation'
  name TEXT UNIQUE NOT NULL,              -- Internal name
  display_name TEXT NOT NULL,             -- e.g., 'Light Therapy'
  description TEXT,
  icon TEXT,                              -- Icon identifier
  is_active BOOLEAN DEFAULT TRUE,         -- Can disable modules app-wide
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pre-populate with 9 modules
INSERT INTO modules (id, name, display_name) VALUES
  ('light', 'light', 'Light Therapy'),
  ('sport', 'sport', 'Exercise & Movement'),
  ('temperature', 'temperature', 'Temperature Exposure'),
  ('nutrition', 'nutrition', 'Sleep-Promoting Nutrition'),
  ('mealtime', 'mealtime', 'Meal Timing'),
  ('sleep_hygiene', 'sleep_hygiene', 'Sleep Hygiene'),
  ('meditation', 'meditation', 'Meditation & Relaxation'),
  ('journaling', 'journaling', 'Sleep Journaling'),
  ('medication', 'medication', 'Medication Tracking');
```

**Design Decision:** Why a modules table?
- Centralized module registry
- Easy to add new modules without code changes
- Can disable modules globally (e.g., beta features)
- Metadata (icons, descriptions) stored in one place

---

### 4. User Module Configurations Table

Stores each user's module settings.

```sql
CREATE TABLE user_module_configurations (
  id TEXT PRIMARY KEY,                    -- UUID
  user_id TEXT NOT NULL,
  module_id TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT TRUE,        -- User has enabled this module

  -- Module-specific configuration (JSON)
  -- Example for Light module:
  -- {
  --   "target_time": "07:30",
  --   "target_duration_minutes": 30,
  --   "preferred_light_type": "natural_sunlight",
  --   "notifications": {
  --     "morning_reminder": {"enabled": true, "time": "07:00"},
  --     "evening_dim_reminder": {"enabled": true, "time": "20:00"},
  --     "blue_blocker_reminder": {"enabled": true, "time": "21:00"}
  --   }
  -- }
  configuration JSON,

  enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE,
  UNIQUE(user_id, module_id)              -- One config per user per module
);

CREATE INDEX idx_user_modules_user ON user_module_configurations(user_id);
```

**Why JSON for configuration?**
- Each module has different settings (light has "light_type", sport has "exercise_type")
- Avoids creating 9 separate configuration tables
- Easy to add new configuration options without migrations
- Notification settings are complex nested objects (perfect for JSON)

---

### 5. Intervention Activities Table

**This is the core correlation table.** Stores daily intervention tracking.

```sql
CREATE TABLE intervention_activities (
  id TEXT PRIMARY KEY,                    -- UUID
  user_id TEXT NOT NULL,
  module_id TEXT NOT NULL,
  activity_date DATE NOT NULL,            -- The day the intervention was performed

  -- Completion tracking
  was_completed BOOLEAN NOT NULL,         -- Did the user do it? (required)
  completed_at TIMESTAMP,                 -- When specifically (optional)

  -- Common typed fields (present for most modules)
  duration_minutes INTEGER,               -- How long (almost all modules have duration)
  time_of_day TEXT CHECK(time_of_day IN ('morning', 'afternoon', 'evening', 'night')),
  intensity TEXT CHECK(intensity IN ('low', 'medium', 'high')),

  -- Module-specific flexible data (JSON)
  -- Example for Light module:
  -- {
  --   "light_type": "natural_sunlight",
  --   "location": "outdoor",
  --   "weather": "sunny"
  -- }
  module_specific_data JSON,

  -- Notes
  notes TEXT,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE
);

CREATE INDEX idx_intervention_activities_user_date ON intervention_activities(user_id, activity_date);
CREATE INDEX idx_intervention_activities_module ON intervention_activities(module_id, activity_date);
CREATE INDEX idx_intervention_activities_completion ON intervention_activities(user_id, was_completed);
```

**Key Design Decisions:**

1. **`was_completed` is required**: Binary yes/no tracking (essential for correlation)
2. **Common typed fields**: duration, time_of_day, intensity are extracted because they're common across modules
3. **`module_specific_data` JSON**: Flexible storage for module-unique attributes
4. **`activity_date` is DATE**: Interventions are day-level (not timestamp) for easier correlation

**Why this works for correlation:**
```sql
-- Example: Get sleep quality vs light therapy adherence
SELECT
  sr.sleep_date,
  sr.quality_rating,
  sr.deep_sleep_duration,
  ia.was_completed as did_light_therapy,
  ia.duration_minutes as light_duration
FROM sleep_records sr
LEFT JOIN intervention_activities ia
  ON ia.user_id = sr.user_id
  AND ia.activity_date = sr.sleep_date    -- Intervention on same day as sleep
  AND ia.module_id = 'light'
WHERE sr.user_id = 'user123'
  AND sr.sleep_date >= date('now', '-30 days');
```

---

### 6. User Sleep Baselines Table

Stores computed personal averages for "you vs your average" comparisons.

```sql
CREATE TABLE user_sleep_baselines (
  id TEXT PRIMARY KEY,                    -- UUID
  user_id TEXT NOT NULL,

  -- Baseline type
  baseline_type TEXT NOT NULL CHECK(baseline_type IN ('7_day', '30_day', 'all_time')),

  -- Metric
  metric_name TEXT NOT NULL,              -- 'avg_deep_sleep', 'avg_total_sleep', etc.
  metric_value REAL NOT NULL,

  -- Data range
  data_range_start DATE NOT NULL,
  data_range_end DATE NOT NULL,

  -- Metadata
  computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(user_id, baseline_type, metric_name, data_range_end)
);

CREATE INDEX idx_baselines_user ON user_sleep_baselines(user_id, baseline_type, metric_name);
```

**How it works:**
- Background job runs nightly to compute rolling averages
- Example: "Last 7 days, this user's average deep sleep = 85 minutes"
- UI queries this table instead of recalculating on-the-fly
- Multiple baseline types: 7-day (recent), 30-day (trend), all-time (lifetime)

**Example data:**
```sql
INSERT INTO user_sleep_baselines
  (id, user_id, baseline_type, metric_name, metric_value, data_range_start, data_range_end)
VALUES
  ('uuid1', 'user123', '7_day', 'avg_deep_sleep', 85.5, '2025-10-23', '2025-10-29'),
  ('uuid2', 'user123', '7_day', 'avg_total_sleep', 420.0, '2025-10-23', '2025-10-29'),
  ('uuid3', 'user123', '30_day', 'avg_deep_sleep', 88.2, '2025-09-30', '2025-10-29');
```

---

## Optional: Future Tables

### Sleep Stages Time-Series (Future)

For fine-grained intra-night data (minute-by-minute sleep stages).

```sql
CREATE TABLE sleep_stages_timeseries (
  id TEXT PRIMARY KEY,
  sleep_record_id TEXT NOT NULL,
  timestamp TIMESTAMP NOT NULL,

  -- Stage at this timestamp
  stage TEXT CHECK(stage IN ('deep', 'rem', 'light', 'awake')),

  -- Biometrics at this timestamp (if available)
  heart_rate REAL,
  hrv REAL,
  breathing_rate REAL,
  movement_level REAL,                    -- Accelerometer data

  FOREIGN KEY (sleep_record_id) REFERENCES sleep_records(id) ON DELETE CASCADE
);

CREATE INDEX idx_sleep_stages_record ON sleep_stages_timeseries(sleep_record_id, timestamp);
```

**When to add this:**
- Only if you need advanced analysis (e.g., "deep sleep cycles per night")
- Most features work fine with aggregates
- Adds complexity to wearable sync logic

---

## Correlation Queries

### Example 1: Light Therapy vs Deep Sleep

```sql
-- Does light therapy improve deep sleep?
SELECT
  ia.was_completed,
  AVG(sr.deep_sleep_duration) as avg_deep_sleep,
  COUNT(*) as nights
FROM sleep_records sr
LEFT JOIN intervention_activities ia
  ON ia.user_id = sr.user_id
  AND ia.activity_date = sr.sleep_date
  AND ia.module_id = 'light'
WHERE sr.user_id = 'user123'
  AND sr.sleep_date >= date('now', '-30 days')
GROUP BY ia.was_completed;
```

**Output:**
```
was_completed | avg_deep_sleep | nights
--------------|----------------|-------
false         | 75.5           | 12
true          | 92.3           | 18
```

### Example 2: Multi-Module Correlation

```sql
-- Compare sleep when using Light+Sport vs neither
WITH daily_modules AS (
  SELECT
    user_id,
    activity_date,
    GROUP_CONCAT(module_id) as modules_used
  FROM intervention_activities
  WHERE was_completed = true
  GROUP BY user_id, activity_date
)
SELECT
  CASE
    WHEN dm.modules_used LIKE '%light%sport%' THEN 'Light+Sport'
    WHEN dm.modules_used IS NULL THEN 'None'
    ELSE 'Other'
  END as intervention_combo,
  AVG(sr.total_sleep_time) as avg_sleep,
  AVG(sr.deep_sleep_duration) as avg_deep_sleep
FROM sleep_records sr
LEFT JOIN daily_modules dm
  ON dm.user_id = sr.user_id
  AND dm.activity_date = sr.sleep_date
WHERE sr.user_id = 'user123'
GROUP BY intervention_combo;
```

### Example 3: Individual Baseline Comparison

```sql
-- Show today vs 7-day average
SELECT
  sr.sleep_date,
  sr.deep_sleep_duration as tonight_deep_sleep,
  b.metric_value as avg_deep_sleep_7day,
  (sr.deep_sleep_duration - b.metric_value) as difference
FROM sleep_records sr
CROSS JOIN user_sleep_baselines b
WHERE sr.user_id = 'user123'
  AND sr.sleep_date = date('now')
  AND b.user_id = 'user123'
  AND b.baseline_type = '7_day'
  AND b.metric_name = 'avg_deep_sleep'
  AND b.data_range_end = date('now', '-1 day');
```

---

## Migration Strategy

### Phase 1: Local SQLite (Now)

1. Create all core tables (users, sleep_records, modules, user_module_configurations, intervention_activities, user_sleep_baselines)
2. Implement migrations in `core/database/migrations/`
3. Version 1 schema
4. Focus on Light module as pilot

### Phase 2: Additional Modules (Weeks 2-8)

1. Add Sport, Meditation, etc. (no schema changes needed!)
2. Just add configuration JSON and module-specific data fields
3. Migrate existing user configurations if needed

### Phase 3: PostgreSQL Sync (Future)

1. Set up PostgreSQL backend with identical schema
2. Implement sync logic in `core/database/sync/`
3. Use `synced_at` timestamps to track what needs syncing
4. Conflict resolution: last-write-wins initially
5. Soft deletes ensure deletions propagate correctly

### Phase 4: Granular Data (Optional Future)

1. Add `sleep_stages_timeseries` table
2. Update wearable sync to store minute-by-minute data
3. Existing aggregate queries still work (no breaking changes)
4. New advanced analytics can use granular data

---

## Schema Migrations

### Migration Version 1 (Initial Schema)

**File:** `lib/core/database/migrations/migration_v1.dart`

```dart
const String MIGRATION_V1 = '''
  -- Create users table
  CREATE TABLE users (...);

  -- Create sleep_records table
  CREATE TABLE sleep_records (...);

  -- Create modules table
  CREATE TABLE modules (...);
  INSERT INTO modules (id, name, display_name) VALUES (...);

  -- Create user_module_configurations table
  CREATE TABLE user_module_configurations (...);

  -- Create intervention_activities table
  CREATE TABLE intervention_activities (...);

  -- Create user_sleep_baselines table
  CREATE TABLE user_sleep_baselines (...);

  -- Create indexes
  CREATE INDEX idx_sleep_records_user_date ON sleep_records(user_id, sleep_date);
  CREATE INDEX idx_intervention_activities_user_date ON intervention_activities(user_id, activity_date);
  CREATE INDEX idx_baselines_user ON user_sleep_baselines(user_id, baseline_type, metric_name);
''';
```

### Example Migration v2 (Future)

```dart
const String MIGRATION_V2 = '''
  -- Add new column to users table
  ALTER TABLE users ADD COLUMN occupation_type TEXT;

  -- Add new table for granular sleep data
  CREATE TABLE sleep_stages_timeseries (...);
''';
```

---

## Design Decisions Summary

| Decision | Approach | Rationale |
|----------|----------|-----------|
| **Schema Style** | Hybrid (typed + JSON) | Balance between flexibility and performance |
| **ID Generation** | UUIDs (TEXT) | Local-first compatible, no server coordination needed |
| **Data Granularity** | Aggregates first, granular later | Simpler queries, faster UI, can add detail later |
| **Module Storage** | Single `intervention_activities` table | Easier multi-module correlation, less sync complexity |
| **Baseline Calculation** | Pre-computed, stored | Fast UI queries, no real-time calculation overhead |
| **Sync Strategy** | Timestamps + soft deletes | Standard pattern for distributed systems |
| **Notification Config** | JSON in user_module_configurations | Complex nested structure, rarely queried |

---

## Implementation Checklist

- [ ] Create `database_helper.dart` with version management
- [ ] Implement Migration v1 (all core tables)
- [ ] Create repository interfaces in domain layer
- [ ] Implement SQLite repositories in data layer
- [ ] Add UUID generator utility
- [ ] Build sync queue infrastructure (basic)
- [ ] Test with Light module (pilot)
- [ ] Implement baseline calculation service
- [ ] Document common queries for features
- [ ] Add database constants file

---

## Resources

- [SQLite JSON Functions](https://www.sqlite.org/json1.html)
- [sqflite Flutter Package](https://pub.dev/packages/sqflite)
- [UUID Package](https://pub.dev/packages/uuid)
- [PostgreSQL Migration Guide](https://www.postgresql.org/docs/current/app-pg-dumpall.html)
