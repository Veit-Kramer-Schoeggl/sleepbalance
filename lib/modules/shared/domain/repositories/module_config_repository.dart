import '../models/user_module_config.dart';

/// Repository for managing user module configurations
///
/// Provides CRUD operations for user_module_configurations table.
/// Concrete implementation in data layer.
abstract class ModuleConfigRepository {
  /// Get specific module configuration for user
  ///
  /// Returns null if user hasn't configured this module yet.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - moduleId: Module identifier (e.g., 'light')
  ///
  /// Returns: UserModuleConfig or null
  Future<UserModuleConfig?> getModuleConfig(String userId, String moduleId);

  /// Get all module configurations for user
  ///
  /// Returns all modules user has ever activated (active and inactive).
  /// Empty list if user hasn't configured any modules.
  ///
  /// Parameters:
  /// - userId: User's ID
  ///
  /// Returns: List of UserModuleConfig
  Future<List<UserModuleConfig>> getAllModuleConfigs(String userId);

  /// Get only active module configurations
  ///
  /// Returns modules where is_enabled = true.
  /// Used by Action Center to show only active modules.
  ///
  /// Parameters:
  /// - userId: User's ID
  ///
  /// Returns: List of UserModuleConfig
  Future<List<UserModuleConfig>> getActiveModuleConfigs(String userId);

  /// Get list of active module IDs
  ///
  /// Convenience method to get just the module IDs.
  /// Useful when you only need to know which modules are active.
  ///
  /// Parameters:
  /// - userId: User's ID
  ///
  /// Returns: List of module IDs (e.g., ['light', 'sport'])
  Future<List<String>> getActiveModuleIds(String userId);

  /// Add new module configuration
  ///
  /// Called when user activates a module for the first time.
  /// Also calls module's onModuleActivated lifecycle hook.
  ///
  /// Parameters:
  /// - config: UserModuleConfig to save
  ///
  /// Throws: Exception if config already exists for this user+module
  Future<void> addModuleConfig(UserModuleConfig config);

  /// Update existing module configuration
  ///
  /// Called when user changes module settings.
  /// Updates configuration JSON and updated_at timestamp.
  ///
  /// Parameters:
  /// - config: UserModuleConfig with updated values
  Future<void> updateModuleConfig(UserModuleConfig config);

  /// Enable/disable module
  ///
  /// Sets is_enabled flag without changing configuration.
  /// When disabling: calls module's onModuleDeactivated hook.
  /// When enabling: calls module's onModuleActivated hook.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - moduleId: Module to enable/disable
  /// - isEnabled: true to enable, false to disable
  Future<void> setModuleEnabled(String userId, String moduleId, bool isEnabled);

  /// Delete module configuration
  ///
  /// Permanently removes configuration and all related data.
  /// WARNING: This is destructive. Consider setModuleEnabled(false) instead.
  ///
  /// Parameters:
  /// - userId: User's ID
  /// - moduleId: Module to delete
  Future<void> deleteModuleConfig(String userId, String moduleId);
}
