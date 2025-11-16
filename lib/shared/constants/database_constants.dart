// ignore_for_file: constant_identifier_names

/// Database Constants
///
/// Centralized definition of all database table and column names.
/// Prevents typos and enables safe refactoring across the codebase.
library;

// ============================================================================
// Database Configuration
// ============================================================================

const String DATABASE_NAME = 'sleepbalance.db';
const int DATABASE_VERSION = 6;

// ============================================================================
// Table Names
// ============================================================================

const String TABLE_USERS = 'users';
const String TABLE_SLEEP_RECORDS = 'sleep_records';
const String TABLE_MODULES = 'modules';
const String TABLE_USER_MODULE_CONFIGURATIONS = 'user_module_configurations';
const String TABLE_INTERVENTION_ACTIVITIES = 'intervention_activities';
const String TABLE_USER_SLEEP_BASELINES = 'user_sleep_baselines';

// ============================================================================
// Users Table Columns
// ============================================================================

const String USERS_ID = 'id';
const String USERS_EMAIL = 'email';
const String USERS_PASSWORD_HASH = 'password_hash';
const String USERS_FIRST_NAME = 'first_name';
const String USERS_LAST_NAME = 'last_name';
const String USERS_BIRTH_DATE = 'birth_date';
const String USERS_TIMEZONE = 'timezone';
const String USERS_TARGET_SLEEP_DURATION = 'target_sleep_duration';
const String USERS_TARGET_BED_TIME = 'target_bed_time';
const String USERS_TARGET_WAKE_TIME = 'target_wake_time';
const String USERS_HAS_SLEEP_DISORDER = 'has_sleep_disorder';
const String USERS_SLEEP_DISORDER_TYPE = 'sleep_disorder_type';
const String USERS_TAKES_SLEEP_MEDICATION = 'takes_sleep_medication';
const String USERS_PREFERRED_UNIT_SYSTEM = 'preferred_unit_system';
const String USERS_LANGUAGE = 'language';
const String USERS_CREATED_AT = 'created_at';
const String USERS_UPDATED_AT = 'updated_at';
const String USERS_SYNCED_AT = 'synced_at';
const String USERS_IS_DELETED = 'is_deleted';

// ============================================================================
// Sleep Records Table Columns
// ============================================================================

const String SLEEP_RECORDS_ID = 'id';
const String SLEEP_RECORDS_USER_ID = 'user_id';
const String SLEEP_RECORDS_SLEEP_DATE = 'sleep_date';
const String SLEEP_RECORDS_BED_TIME = 'bed_time';
const String SLEEP_RECORDS_SLEEP_START_TIME = 'sleep_start_time';
const String SLEEP_RECORDS_SLEEP_END_TIME = 'sleep_end_time';
const String SLEEP_RECORDS_WAKE_TIME = 'wake_time';
const String SLEEP_RECORDS_TOTAL_SLEEP_TIME = 'total_sleep_time';
const String SLEEP_RECORDS_DEEP_SLEEP_DURATION = 'deep_sleep_duration';
const String SLEEP_RECORDS_REM_SLEEP_DURATION = 'rem_sleep_duration';
const String SLEEP_RECORDS_LIGHT_SLEEP_DURATION = 'light_sleep_duration';
const String SLEEP_RECORDS_AWAKE_DURATION = 'awake_duration';
const String SLEEP_RECORDS_AVG_HEART_RATE = 'avg_heart_rate';
const String SLEEP_RECORDS_MIN_HEART_RATE = 'min_heart_rate';
const String SLEEP_RECORDS_MAX_HEART_RATE = 'max_heart_rate';
const String SLEEP_RECORDS_AVG_HRV = 'avg_hrv';
const String SLEEP_RECORDS_AVG_HEART_RATE_VARIABILITY = 'avg_heart_rate_variability';
const String SLEEP_RECORDS_AVG_BREATHING_RATE = 'avg_breathing_rate';
const String SLEEP_RECORDS_QUALITY_RATING = 'quality_rating';
const String SLEEP_RECORDS_QUALITY_NOTES = 'quality_notes';
const String SLEEP_RECORDS_DATA_SOURCE = 'data_source';
const String SLEEP_RECORDS_CREATED_AT = 'created_at';
const String SLEEP_RECORDS_UPDATED_AT = 'updated_at';
const String SLEEP_RECORDS_SYNCED_AT = 'synced_at';
const String SLEEP_RECORDS_IS_DELETED = 'is_deleted';

// ============================================================================
// Modules Table Columns
// ============================================================================

const String MODULES_ID = 'id';
const String MODULES_NAME = 'name';
const String MODULES_DISPLAY_NAME = 'display_name';
const String MODULES_DESCRIPTION = 'description';
const String MODULES_ICON = 'icon';
const String MODULES_IS_ACTIVE = 'is_active';
const String MODULES_CREATED_AT = 'created_at';

// ============================================================================
// User Module Configurations Table Columns
// ============================================================================

const String USER_MODULE_CONFIGS_ID = 'id';
const String USER_MODULE_CONFIGS_USER_ID = 'user_id';
const String USER_MODULE_CONFIGS_MODULE_ID = 'module_id';
const String USER_MODULE_CONFIGS_IS_ENABLED = 'is_enabled';
const String USER_MODULE_CONFIGS_CONFIGURATION = 'configuration';
const String USER_MODULE_CONFIGS_ENROLLED_AT = 'enrolled_at';
const String USER_MODULE_CONFIGS_UPDATED_AT = 'updated_at';
const String USER_MODULE_CONFIGS_SYNCED_AT = 'synced_at';

// ============================================================================
// Intervention Activities Table Columns
// ============================================================================

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
const String INTERVENTION_ACTIVITIES_SYNCED_AT = 'synced_at';
const String INTERVENTION_ACTIVITIES_IS_DELETED = 'is_deleted';

// ============================================================================
// User Sleep Baselines Table Columns
// ============================================================================

const String USER_SLEEP_BASELINES_ID = 'id';
const String USER_SLEEP_BASELINES_USER_ID = 'user_id';
const String USER_SLEEP_BASELINES_BASELINE_TYPE = 'baseline_type';
const String USER_SLEEP_BASELINES_METRIC_NAME = 'metric_name';
const String USER_SLEEP_BASELINES_METRIC_VALUE = 'metric_value';
const String USER_SLEEP_BASELINES_DATA_RANGE_START = 'data_range_start';
const String USER_SLEEP_BASELINES_DATA_RANGE_END = 'data_range_end';
const String USER_SLEEP_BASELINES_COMPUTED_AT = 'computed_at';

// ============================================================================
// Daily Actions Table
// ============================================================================

const String TABLE_DAILY_ACTIONS = 'daily_actions';
const String DAILY_ACTIONS_ID = 'id';
const String DAILY_ACTIONS_USER_ID = 'user_id';
const String DAILY_ACTIONS_TITLE = 'title';
const String DAILY_ACTIONS_ICON_NAME = 'icon_name';
const String DAILY_ACTIONS_IS_COMPLETED = 'is_completed';
const String DAILY_ACTIONS_ACTION_DATE = 'action_date';
const String DAILY_ACTIONS_CREATED_AT = 'created_at';
const String DAILY_ACTIONS_COMPLETED_AT = 'completed_at';
