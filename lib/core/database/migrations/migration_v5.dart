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
