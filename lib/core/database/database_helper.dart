import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../shared/constants/database_constants.dart';
import '../utils/database_date_utils.dart';
import '../utils/uuid_generator.dart';
import 'migrations/migration_v1.dart';
import 'migrations/migration_v2.dart';
import 'migrations/migration_v3.dart';
import 'migrations/migration_v4.dart';
import 'migrations/migration_v5.dart';
// import 'migrations/migration_v6.dart'; // Disabled due to multi-statement issues
import 'migrations/migration_v7.dart';
import 'migrations/migration_v8.dart';

/// Database Helper - Singleton for managing SQLite database lifecycle
///
/// Responsibilities:
/// - Initialize database on first access (lazy initialization)
/// - Handle database versioning and migrations
/// - Provide single database instance throughout app
/// - Execute schema migrations in correct order
class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Cached database instance
  static Database? _database;

  // Private constructor to prevent instantiation
  DatabaseHelper._privateConstructor();

  /// Get database instance (lazy initialization)
  ///
  /// Returns existing database or initializes a new one if null.
  /// Ensures only one database connection exists at a time.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  ///
  /// Steps:
  /// 1. Get application documents directory path
  /// 2. Construct full database file path
  /// 3. Open database with version and callbacks
  /// 4. Return database instance
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, DATABASE_NAME);

    return await openDatabase(
      path,
      version: DATABASE_VERSION,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database callback
  ///
  /// Called when database is created for the first time.
  /// Executes all migrations up to the current version.
  ///
  /// For fresh installs at V8:
  /// - Executes MIGRATION_V1 (base schema)
  /// - Executes MIGRATION_V2 (daily_actions table)
  /// - Executes MIGRATION_V3 (sleep_records and user_sleep_baselines tables)
  /// - Executes MIGRATION_V4 (users table)
  /// - Executes MIGRATION_V5 (user_module_configurations table)
  /// - Executes MIGRATION_V7 (wearable_connections and wearable_sync_history tables)
  /// - Executes MIGRATION_V8 (email_verification_tokens table and email_verified column)
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('DatabaseHelper: Creating database version $version');

    // Always execute V1 first (base schema)
    debugPrint('DatabaseHelper: Executing MIGRATION_V1...');
    await _executeMultiStatement(db, MIGRATION_V1);
    debugPrint('DatabaseHelper: MIGRATION_V1 completed ✓');

    // Execute subsequent migrations to reach target version
    if (version >= 2) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V2...');
      await _executeMultiStatement(db, MIGRATION_V2);
      debugPrint('DatabaseHelper: MIGRATION_V2 completed ✓');
    }
    if (version >= 3) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V3...');
      await _executeMultiStatement(db, MIGRATION_V3);
      debugPrint('DatabaseHelper: MIGRATION_V3 completed ✓');
    }
    if (version >= 4) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V4...');
      await _executeMultiStatement(db, MIGRATION_V4);
      debugPrint('DatabaseHelper: MIGRATION_V4 completed ✓');
    }
    if (version >= 5) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V5...');
      await _executeMultiStatement(db, MigrationV5.MIGRATION_V5);
      debugPrint('DatabaseHelper: MIGRATION_V5 completed ✓');
    }
    // TODO: Fix Migration V6 - currently disabled due to multi-statement execution issues
    // The index and triggers are nice-to-have optimizations, not required for functionality
    // if (version >= 6) {
    //   await executeMigrationV6(db);
    // }
    if (version >= 7) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V7...');
      await _executeMultiStatement(db, MIGRATION_V7);
      debugPrint('DatabaseHelper: MIGRATION_V7 completed ✓');
    }
    if (version >= 8) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V8...');
      await db.execute(MIGRATION_V8_CREATE_TABLE);
      await db.execute(MIGRATION_V8_INDEX_EMAIL);
      await db.execute(MIGRATION_V8_INDEX_EXPIRES);
      await db.execute(MIGRATION_V8_ALTER_USERS);
      debugPrint('DatabaseHelper: MIGRATION_V8 completed ✓');
    }

    // Insert default user only for versions before V8
    // V8+ uses proper authentication with signup/email verification
    if (version >= 4 && version < 8) {
      await _createDefaultUser(db);
    }

    debugPrint('DatabaseHelper: Database creation completed successfully!');
  }

  /// Create default user
  ///
  /// Inserts a default user for first-time app setup.
  /// This user will be used until proper authentication is implemented.
  Future<void> _createDefaultUser(Database db) async {
    final defaultUserId = UuidGenerator.generate();
    final now = DateTime.now();

    final defaultUser = {
      USERS_ID: defaultUserId,
      USERS_EMAIL: 'default@sleepbalance.app',
      USERS_FIRST_NAME: 'Sleep',
      USERS_LAST_NAME: 'User',
      USERS_BIRTH_DATE: DatabaseDateUtils.toDateString(DateTime(1990, 1, 1)),
      USERS_TIMEZONE: 'UTC',
      USERS_TARGET_SLEEP_DURATION: 480,
      USERS_PREFERRED_UNIT_SYSTEM: 'metric',
      USERS_LANGUAGE: 'en',
      USERS_HAS_SLEEP_DISORDER: 0,
      USERS_TAKES_SLEEP_MEDICATION: 0,
      USERS_EMAIL_VERIFIED: 1, // Default user is pre-verified
      USERS_CREATED_AT: DatabaseDateUtils.toTimestamp(now),
      USERS_UPDATED_AT: DatabaseDateUtils.toTimestamp(now),
      USERS_IS_DELETED: 0,
    };

    await db.insert(TABLE_USERS, defaultUser);
  }

  /// Upgrade database callback
  ///
  /// Called when database version increases.
  /// Executes migrations sequentially from oldVersion to newVersion.
  ///
  /// Example: If user has v1 and app requires v5:
  /// - Execute migration v1→v2
  /// - Then execute migration v2→v3
  /// - Then execute migration v3→v4
  /// - Then execute migration v4→v5
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('DatabaseHelper: Upgrading database from v$oldVersion to v$newVersion');

    // Execute migrations sequentially
    if (oldVersion < 2) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V2...');
      await _executeMultiStatement(db, MIGRATION_V2);
      debugPrint('DatabaseHelper: MIGRATION_V2 completed ✓');
    }
    if (oldVersion < 3) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V3...');
      await _executeMultiStatement(db, MIGRATION_V3);
      debugPrint('DatabaseHelper: MIGRATION_V3 completed ✓');
    }
    if (oldVersion < 4) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V4...');
      await _executeMultiStatement(db, MIGRATION_V4);
      debugPrint('DatabaseHelper: MIGRATION_V4 completed ✓');
    }
    if (oldVersion < 5) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V5...');
      await _executeMultiStatement(db, MigrationV5.MIGRATION_V5);
      debugPrint('DatabaseHelper: MIGRATION_V5 completed ✓');
    }
    // TODO: Fix Migration V6 - currently disabled
    // if (oldVersion < 6) {
    //   await executeMigrationV6(db);
    // }
    if (oldVersion < 7) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V7...');
      await _executeMultiStatement(db, MIGRATION_V7);
      debugPrint('DatabaseHelper: MIGRATION_V7 completed ✓');
    }
    if (oldVersion < 8) {
      debugPrint('DatabaseHelper: Executing MIGRATION_V8...');
      await db.execute(MIGRATION_V8_CREATE_TABLE);
      await db.execute(MIGRATION_V8_INDEX_EMAIL);
      await db.execute(MIGRATION_V8_INDEX_EXPIRES);
      await db.execute(MIGRATION_V8_ALTER_USERS);
      debugPrint('DatabaseHelper: MIGRATION_V8 completed ✓');
    }

    debugPrint('DatabaseHelper: Database upgrade completed successfully!');

    // Note: Default user is only created for new installations (in _onCreate),
    // not during upgrades, to avoid creating duplicate users
  }

  /// Close database connection
  ///
  /// Properly closes the database and clears cached instance.
  /// Should be called when app is shutting down (rarely needed in Flutter).
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete database file
  ///
  /// Useful for:
  /// - Testing and development
  /// - User logout/data reset
  /// - Troubleshooting corrupted databases
  ///
  /// WARNING: This permanently deletes all local data!
  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, DATABASE_NAME);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Execute multi-statement SQL string
  ///
  /// Splits SQL string by semicolons and executes each statement individually.
  /// This is necessary because sqflite's execute() only handles single statements.
  ///
  /// Filters out:
  /// - Empty statements
  /// - Comment-only lines
  /// - Whitespace-only lines
  static Future<void> _executeMultiStatement(Database db, String sql) async {
    // First, remove all comment lines (lines starting with --)
    final lines = sql.split('\n');
    final sqlWithoutComments = lines
        .where((line) => !line.trim().startsWith('--'))
        .join('\n');

    // Split by semicolon and filter out empty statements
    final statements = sqlWithoutComments
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    debugPrint('DatabaseHelper: Executing ${statements.length} SQL statements...');

    for (int i = 0; i < statements.length; i++) {
      final statement = statements[i];
      try {
        await db.execute(statement);
        debugPrint('DatabaseHelper: Statement ${i + 1}/${statements.length} completed');
      } catch (e) {
        debugPrint('DatabaseHelper: Failed to execute statement ${i + 1}/${statements.length}:');
        debugPrint('  ${statement.substring(0, statement.length > 100 ? 100 : statement.length)}...');
        debugPrint('DatabaseHelper: Error: $e');
        rethrow;
      }
    }
  }
}
