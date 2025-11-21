import 'package:flutter/material.dart';
import 'package:sleepbalance/modules/shared/domain/repositories/module_config_repository.dart';
import 'package:sleepbalance/modules/shared/constants/module_metadata.dart';
import 'package:sleepbalance/modules/shared/domain/models/user_module_config.dart';

class HabitsViewModel extends ChangeNotifier {
  final ModuleConfigRepository repository;

  HabitsViewModel({required this.repository});

  List<ModuleMetadata> _availableModules = [];
  List<UserModuleConfig> _userConfigs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ModuleMetadata> get availableModules => _availableModules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isModuleActive(String moduleId) {
    return _userConfigs.any((config) =>
    config.moduleId == moduleId && config.isEnabled == true);
  }

  Future<void> loadModules(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _availableModules = getAvailableModules();

      _userConfigs = await repository.getAllModuleConfigs(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleModule(String userId, String moduleId) async {
    try {
      final isActive = isModuleActive(moduleId);

      await repository.setModuleEnabled(
        userId,
        moduleId,
        !isActive,
      );

      await loadModules(userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> saveModuleConfigs(String userId) async {
    try {
      for (final module in _availableModules) {
        final isActive = isModuleActive(module.id);

        await repository.setModuleEnabled(
          userId,
          module.id,
          isActive,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

}
