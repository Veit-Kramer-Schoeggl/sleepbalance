CREATE TABLE users (
-- Your required fields
id TEXT PRIMARY KEY,
email TEXT UNIQUE NOT NULL,
password_hash TEXT,
first_name TEXT NOT NULL,
last_name TEXT NOT NULL,
birth_date DATE NOT NULL,

    -- Sleep-specific additions
    timezone TEXT NOT NULL,  -- Critical for sleep timing!

    -- Sleep preferences/goals
    target_sleep_duration INTEGER,  -- minutes (e.g., 480 = 8 hours)
    target_bed_time TEXT,  -- e.g., "22:30"
    target_wake_time TEXT,  -- e.g., "06:30"

    -- Health context (useful for analysis)
    has_sleep_disorder BOOLEAN DEFAULT FALSE,
    sleep_disorder_type TEXT,  -- 'insomnia', 'sleep_apnea', 'restless_legs', etc.
    takes_sleep_medication BOOLEAN DEFAULT FALSE,

    -- Lifestyle factors (can affect sleep)
    occupation_type TEXT,  -- 'shift_work', 'regular_hours', 'flexible', etc.
    caffeine_sensitivity TEXT,  -- 'low', 'medium', 'high'

    -- Preferences
    preferred_unit_system TEXT DEFAULT 'metric',  -- 'metric' or 'imperial'
    language TEXT DEFAULT 'en',

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);


I want to remove the default user that is beeing created here database_helper.dart and use a different
way of prepopulating the database pls give me some options on how we can do this.

Step 2: Create Module Model (30 minutes)

File: lib/modules/shared/domain/models/module.dart

What to implement:
- Simple model class with 7 fields (id, name, displayName, description, icon, isActive, createdAt)
- Add @JsonSerializable() decorator
- Implement fromJson() and toJson() methods
- Implement fromDatabase() and toDatabase() methods
- isActive: stored as INTEGER (1/0) in SQLite, bool in Dart
- Template available in SHARED_PLAN.md lines 291-345

Note: Module metadata is hardcoded in lib/modules/shared/constants/module_metadata.dart since Phase 7, but this model still needed for database queries and type safety.

could we remove the hardcoded metadata and simply add it here since we need this class anyway?

1. Start with Essential Foundation (Phase S.1) - Implement only what's immediately needed: base domain models (InterventionActivity, UserModuleConfig, Module), DateTimeHelpers utility, and database constants.
   This takes ~6 hours and provides zero-guesswork foundation.
2. Build Light Module Inline (Phase 2) - Implement the complete Light module WITHOUT extracting shared components yet. Build time slider, color scheme logic, and notification scheduling directly inside the Light
   module. This validates the patterns work in real-world usage before committing to abstractions.
3. Validate Thoroughly - Test the Light module completely to ensure TimeSlider works well, color feedback is useful, and notifications fire correctly. If anything doesn't work well, redesign it NOW before
   extracting.
4. Extract Proven Patterns (Phase S.3) - ONLY AFTER Light works perfectly, extract the validated components (TimeSliderWidget, ColorSchemeHelper) to shared infrastructure. Refactor Light to use these shared
   components and verify nothing breaks.
5. Use Shared Components for Subsequent Modules - Sport module (Phase 4) will use the extracted shared components, validating they're truly reusable. Each subsequent module either uses existing shared components
   or identifies new patterns to extract.
   Step L.9: Build TimeSlider Inline (NOT extracted - will be in Phase 3)

Step L.9: Build TimeSlider Inline (NOT extracted - will be in Phase 3)
1. Module Enable/Disable:
- Navigate to Settings → Manage Modules → Light Therapy
- Toggle enable switch → verify UI shows/hides config
- Disable → verify notifications cancelled
- Re-enable → verify notifications rescheduled
2. Configuration:
- Set target time → save → restart app → verify persists
- Adjust duration slider → verify updates immediately
- Change light type → verify saves correctly
- Toggle notifications → verify individual toggles work
3. Notifications:
- Enable morning reminder → set time 1 minute in future → wait → verify fires
- Enable evening dim reminder → verify scheduled
- Enable blue blocker → verify scheduled
- Disable all → verify cancelled
4. Database Validation:
   -- Verify configuration saved
   SELECT * FROM user_module_configurations WHERE module_id = 'light';

-- Check configuration JSON structure
SELECT configuration FROM user_module_configurations WHERE module_id = 'light';
5. Analyzer Check:
   flutter analyze lib/modules/light/
- Zero warnings
- Zero errors
6. Run All Tests:
   flutter test test/modules/light/
- All tests passing

we need to check if we need to update any other existing usages of  timezone with flutter_timezone
within the existing code.

within README.md update/create new references to the respective documentation documents within
documentation/

now pls create a dedicated detailed step by step implementation plan for **FR-2: User Login** 
of the AUTH_PLAN.md