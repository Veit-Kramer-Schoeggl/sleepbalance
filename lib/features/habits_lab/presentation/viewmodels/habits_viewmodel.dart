import 'package:flutter/material.dart';
import 'package:sleepbalance/modules/shared/domain/repositories/module_config_repository.dart';
import 'package:sleepbalance/modules/shared/constants/module_metadata.dart';
import 'package:sleepbalance/modules/shared/domain/models/user_module_config.dart';
import 'package:sleepbalance/shared/notifiers/action_refresh_notifier.dart';

/// ViewModel for the Habits Lab, managing available modules and user configurations.
class HabitsViewModel extends ChangeNotifier {
  /// Repository for module configuration data.
  final ModuleConfigRepository repository;

  /// Creates a [HabitsViewModel] with the required repository.
  HabitsViewModel({required this.repository});

  /// List of modules available to the user.
  List<ModuleMetadata> _availableModules = [];
  /// List of current user module configurations.
  List<UserModuleConfig> _userConfigs = [];
  /// Whether the data is currently being loaded.
  bool _isLoading = false;
  /// Error message if loading or saving failed.
  String? _errorMessage;

  /// Returns the list of available modules.
  List<ModuleMetadata> get availableModules => _availableModules;
  /// Returns whether data is currently loading.
  bool get isLoading => _isLoading;
  /// Returns the current error message, if any.
  String? get errorMessage => _errorMessage;

  /// Checks if a module with the given [moduleId] is active.
  bool isModuleActive(String moduleId) {
    return _userConfigs.any(
          (config) => config.moduleId == moduleId && config.isEnabled,
    );
  }

  /// Loads available modules and user configurations for [userId].
  Future<void> loadModules(String userId) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      _availableModules = getAllModules();
      _userConfigs = await repository.getAllModuleConfigs(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles the activation state of a module locally.
  Future<void> toggleModule(String userId, String moduleId) async {
    try {
      _errorMessage = null;

      // Toggle only in local state. Persist happens on Save Habits.
      final index = _userConfigs.indexWhere((c) => c.moduleId == moduleId);

      if (index >= 0) {
        final current = _userConfigs[index];
        _userConfigs[index] = UserModuleConfig(
          id: current.id,
          userId: current.userId,
          moduleId: current.moduleId,
          isEnabled: !current.isEnabled,
          configuration: current.configuration,
          enrolledAt: current.enrolledAt,
          updatedAt: DateTime.now(),
        );
      } else {
        final now = DateTime.now();
        _userConfigs.add(
          UserModuleConfig(
            id: '${userId}_$moduleId',
            userId: userId,
            moduleId: moduleId,
            isEnabled: true,
            configuration: <String, dynamic>{},
            enrolledAt: now,
            updatedAt: now,
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }


  /// Persists all local module configurations to the repository for [userId].
  Future<void> saveModuleConfigs(String userId) async {
    try {
      _errorMessage = null;

      for (final module in _availableModules) {
        if (!module.isAvailable) continue;

        final isActive = isModuleActive(module.id);

        // Persist selection
        await repository.setModuleEnabled(
            userId,
            module.id,
            isActive);

      }

      // Trigger Action Center reload after saving habits.
      triggerActionRefresh();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

}
