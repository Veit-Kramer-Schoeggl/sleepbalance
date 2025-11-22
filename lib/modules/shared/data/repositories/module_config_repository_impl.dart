import '../../domain/repositories/module_config_repository.dart';
import '../../domain/models/user_module_config.dart';
import '../../domain/services/module_registry.dart';
import '../datasources/module_config_local_datasource.dart';

/// Repository implementation for module configurations
///
/// Delegates database operations to datasource.
/// Adds business logic for module lifecycle hooks.
class ModuleConfigRepositoryImpl implements ModuleConfigRepository {
  final ModuleConfigLocalDataSource dataSource;

  ModuleConfigRepositoryImpl({required this.dataSource});

  @override
  Future<UserModuleConfig?> getModuleConfig(String userId, String moduleId) {
    return dataSource.getModuleConfig(userId, moduleId);
  }

  @override
  Future<List<UserModuleConfig>> getAllModuleConfigs(String userId) {
    return dataSource.getAllModuleConfigs(userId);
  }

  @override
  Future<List<UserModuleConfig>> getActiveModuleConfigs(String userId) {
    return dataSource.getActiveModuleConfigs(userId);
  }

  @override
  Future<List<String>> getActiveModuleIds(String userId) {
    return dataSource.getActiveModuleIds(userId);
  }

  @override
  Future<void> addModuleConfig(UserModuleConfig config) async {
    // Insert into database
    await dataSource.insertModuleConfig(config);

    // Call module lifecycle hook
    if (config.isEnabled) {
      final module = ModuleRegistry.getModule(config.moduleId);
      if (module != null) {
        await module.onModuleActivated(
          userId: config.userId,
          config: config.configuration,
        );
      }
    }
  }

  @override
  Future<void> updateModuleConfig(UserModuleConfig config) async {
    await dataSource.updateModuleConfig(config);
  }

  @override
  Future<void> setModuleEnabled(String userId, String moduleId, bool isEnabled) async {
    // Get current config to pass to lifecycle hooks
    final currentConfig = await dataSource.getModuleConfig(userId, moduleId);
    if (currentConfig == null) {
      throw Exception('Cannot enable/disable non-existent module config');
    }

    // Update database
    await dataSource.updateModuleEnabled(userId, moduleId, isEnabled);

    // Call appropriate lifecycle hook
    final module = ModuleRegistry.getModule(moduleId);
    if (module != null) {
      if (isEnabled) {
        await module.onModuleActivated(
          userId: userId,
          config: currentConfig.configuration,
        );
      } else {
        await module.onModuleDeactivated(userId: userId);
      }
    }
  }

  @override
  Future<void> deleteModuleConfig(String userId, String moduleId) async {
    // Ensure module is deactivated first
    final config = await dataSource.getModuleConfig(userId, moduleId);
    if (config != null && config.isEnabled) {
      await setModuleEnabled(userId, moduleId, false);
    }

    // Delete from database
    await dataSource.deleteModuleConfig(userId, moduleId);
  }
}
