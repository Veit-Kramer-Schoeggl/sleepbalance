import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../shared/constants/database_constants.dart';
import 'migrations/migration_v1.dart';

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
  /// Executes the appropriate migration based on version number.
  ///
  /// For version 1: Executes MIGRATION_V1 which creates:
  /// - 6 core tables (users, sleep_records, modules, etc.)
  /// - 6 performance indexes
  /// - Pre-populates 9 intervention modules
  Future<void> _onCreate(Database db, int version) async {
    // Execute initial schema creation
    if (version == 1) {
      await db.execute(MIGRATION_V1);
    }
  }

  /// Upgrade database callback
  ///
  /// Called when database version increases.
  /// Executes migrations sequentially from oldVersion to newVersion.
  ///
  /// Example: If user has v1 and app requires v3:
  /// - Execute migration v1→v2
  /// - Then execute migration v2→v3
  ///
  /// Currently placeholder for future migrations (v2, v3, etc.)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Execute migrations sequentially
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute(MIGRATION_V2);
    // }
    // if (oldVersion < 3) {
    //   await db.execute(MIGRATION_V3);
    // }
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
