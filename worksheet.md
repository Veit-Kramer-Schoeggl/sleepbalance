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
