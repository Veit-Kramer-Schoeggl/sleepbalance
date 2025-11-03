import 'package:sqflite/sqflite.dart';
import '../../domain/models/user_module_config.dart';
import '../../../../shared/constants/database_constants.dart';

/// Local datasource for module configuration CRUD operations
///
/// Performs SQLite queries on user_module_configurations table.
class ModuleConfigLocalDataSource {
  final Database database;

  ModuleConfigLocalDataSource({required this.database});

  /// Get module config by user and module ID
  Future<UserModuleConfig?> getModuleConfig(String userId, String moduleId) async {
    final results = await database.query(
      TABLE_USER_MODULE_CONFIGURATIONS,
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_MODULE_ID = ?',
      whereArgs: [userId, moduleId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    return UserModuleConfig.fromDatabase(results.first);
  }

  /// Get all configs for user
  Future<List<UserModuleConfig>> getAllModuleConfigs(String userId) async {
    final results = await database.query(
      TABLE_USER_MODULE_CONFIGURATIONS,
      where: '$USER_MODULE_CONFIGS_USER_ID = ?',
      whereArgs: [userId],
      orderBy: '$USER_MODULE_CONFIGS_ENROLLED_AT DESC',
    );

    return results.map((row) => UserModuleConfig.fromDatabase(row)).toList();
  }

  /// Get active configs for user
  Future<List<UserModuleConfig>> getActiveModuleConfigs(String userId) async {
    final results = await database.query(
      TABLE_USER_MODULE_CONFIGURATIONS,
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_IS_ENABLED = 1',
      whereArgs: [userId],
      orderBy: '$USER_MODULE_CONFIGS_ENROLLED_AT DESC',
    );

    return results.map((row) => UserModuleConfig.fromDatabase(row)).toList();
  }

  /// Get active module IDs only
  Future<List<String>> getActiveModuleIds(String userId) async {
    final results = await database.query(
      TABLE_USER_MODULE_CONFIGURATIONS,
      columns: [USER_MODULE_CONFIGS_MODULE_ID],
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_IS_ENABLED = 1',
      whereArgs: [userId],
    );

    return results.map((row) => row[USER_MODULE_CONFIGS_MODULE_ID] as String).toList();
  }

  /// Insert new config
  Future<void> insertModuleConfig(UserModuleConfig config) async {
    await database.insert(
      TABLE_USER_MODULE_CONFIGURATIONS,
      config.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.fail, // Throw error if exists
    );
  }

  /// Update existing config
  Future<void> updateModuleConfig(UserModuleConfig config) async {
    final rowsUpdated = await database.update(
      TABLE_USER_MODULE_CONFIGURATIONS,
      config.toDatabase(),
      where: '$USER_MODULE_CONFIGS_ID = ?',
      whereArgs: [config.id],
    );

    if (rowsUpdated == 0) {
      throw Exception('Module config not found: ${config.id}');
    }
  }

  /// Update is_enabled flag
  Future<void> updateModuleEnabled(String userId, String moduleId, bool isEnabled) async {
    final rowsUpdated = await database.update(
      TABLE_USER_MODULE_CONFIGURATIONS,
      {
        USER_MODULE_CONFIGS_IS_ENABLED: isEnabled ? 1 : 0,
        USER_MODULE_CONFIGS_UPDATED_AT: DateTime.now().toIso8601String(),
      },
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_MODULE_ID = ?',
      whereArgs: [userId, moduleId],
    );

    if (rowsUpdated == 0) {
      throw Exception('Module config not found for user $userId, module $moduleId');
    }
  }

  /// Delete config
  Future<void> deleteModuleConfig(String userId, String moduleId) async {
    await database.delete(
      TABLE_USER_MODULE_CONFIGURATIONS,
      where: '$USER_MODULE_CONFIGS_USER_ID = ? AND $USER_MODULE_CONFIGS_MODULE_ID = ?',
      whereArgs: [userId, moduleId],
    );
  }
}
