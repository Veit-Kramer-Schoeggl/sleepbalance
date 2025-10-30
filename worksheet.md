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

That sounds like a great plan but I want you to split it up even further: pls create a dedicated
step by step plan for phase 1 that states for each file you want to create, the method headers/contents
of that file (just a very short description no code) save this file and name it PHASE_1.md then do
the same for each Phase. Then we will start implementation. Thank you.