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
    // Always execute V1 first (base schema)
    await db.execute(MIGRATION_V1);

    // Execute subsequent migrations to reach target version
    if (version >= 2) {
      await db.execute(MIGRATION_V2);
    }
    if (version >= 3) {
      await db.execute(MIGRATION_V3);
    }
    if (version >= 4) {
      await db.execute(MIGRATION_V4);

      // Insert default user after creating users table
      await _createDefaultUser(db);
    }
    if (version >= 5) {
      await db.execute(MigrationV5.MIGRATION_V5);
    }
    // TODO: Fix Migration V6 - currently disabled due to multi-statement execution issues
    // The index and triggers are nice-to-have optimizations, not required for functionality
    // if (version >= 6) {
    //   await executeMigrationV6(db);
    // }
    if (version >= 7) {
      await db.execute(MIGRATION_V7);
    }
    if (version >= 8) {
      await db.execute(MIGRATION_V8);
    }
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
    // Execute migrations sequentially
    if (oldVersion < 2) {
      await db.execute(MIGRATION_V2);
    }
    if (oldVersion < 3) {
      await db.execute(MIGRATION_V3);
    }
    if (oldVersion < 4) {
      await db.execute(MIGRATION_V4);

      // Create default user if upgrading to V4
      await _createDefaultUser(db);
    }
    if (oldVersion < 5) {
      await db.execute(MigrationV5.MIGRATION_V5);
    }
    // TODO: Fix Migration V6 - currently disabled
    // if (oldVersion < 6) {
    //   await executeMigrationV6(db);
    // }
    if (oldVersion < 7) {
      await db.execute(MIGRATION_V7);
    }
    if (oldVersion < 8) {
      await db.execute(MIGRATION_V8);
    }
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
}
