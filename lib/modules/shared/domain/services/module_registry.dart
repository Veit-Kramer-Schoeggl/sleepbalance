import '../interfaces/module_interface.dart';
import '../../constants/module_metadata.dart';

/// Central registry of all available modules
///
/// Modules register themselves at app startup in main.dart.
/// Habits Lab queries this registry to display available modules.
///
/// Usage in main.dart:
/// ```dart
/// void main() {
///   ModuleRegistry.register(LightModule());
///   ModuleRegistry.register(SportModule());
///   // ... register other modules
///
///   runApp(MyApp());
/// }
/// ```
///
/// Usage in Habits Lab:
/// ```dart
/// final availableModules = ModuleRegistry.getAllModules();
/// for (final module in availableModules) {
///   // Display module card
/// }
/// ```
class ModuleRegistry {
  /// Internal storage of registered modules
  /// Key: module_id, Value: ModuleInterface implementation
  static final Map<String, ModuleInterface> _modules = {};

  /// Register a module
  ///
  /// Called at app startup for each implemented module.
  /// If module already registered, it will be replaced.
  ///
  /// Parameters:
  /// - module: Module implementation (e.g., LightModule())
  ///
  /// Throws: ArgumentError if module.moduleId is empty
  static void register(ModuleInterface module) {
    if (module.moduleId.isEmpty) {
      throw ArgumentError('Module ID cannot be empty');
    }
    _modules[module.moduleId] = module;
  }

  /// Get all registered modules
  ///
  /// Returns list of all modules that have been registered.
  /// Used by Habits Lab to display available modules.
  ///
  /// Returns: List of ModuleInterface implementations
  static List<ModuleInterface> getAllModules() {
    return _modules.values.toList();
  }

  /// Get specific module by ID
  ///
  /// Used when:
  /// - User taps module → navigate to config screen
  /// - User activates module → call onModuleActivated
  /// - User deactivates module → call onModuleDeactivated
  ///
  /// Parameters:
  /// - moduleId: Module identifier (e.g., 'light', 'sport')
  ///
  /// Returns: ModuleInterface or null if not found
  static ModuleInterface? getModule(String moduleId) {
    return _modules[moduleId];
  }

  /// Get metadata for all registered modules
  ///
  /// Convenience method for getting metadata of all modules.
  ///
  /// Returns: Map of module_id → ModuleMetadata
  static Map<String, ModuleMetadata> getAllMetadata() {
    return Map.fromEntries(
      _modules.entries.map((e) => MapEntry(e.key, e.value.getMetadata())),
    );
  }

  /// Check if module is registered
  ///
  /// Useful for checking if module is available before trying to use it.
  ///
  /// Parameters:
  /// - moduleId: Module identifier
  ///
  /// Returns: true if module is registered, false otherwise
  static bool isRegistered(String moduleId) {
    return _modules.containsKey(moduleId);
  }

  /// Unregister all modules
  ///
  /// Only used in tests to reset registry state.
  /// Should NOT be called in production code.
  static void clearAll() {
    _modules.clear();
  }
}
