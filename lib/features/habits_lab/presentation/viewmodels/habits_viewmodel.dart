import 'package:flutter/material.dart';
import 'package:sleepbalance/modules/shared/domain/repositories/module_config_repository.dart';
import 'package:sleepbalance/modules/shared/constants/module_metadata.dart';
import 'package:sleepbalance/modules/shared/domain/models/user_module_config.dart';
import 'package:sleepbalance/shared/notifiers/action_refresh_notifier.dart';

import 'package:sleepbalance/features/action_center/domain/repositories/action_repository.dart';


class HabitsViewModel extends ChangeNotifier {
  final ModuleConfigRepository repository;


  HabitsViewModel({
    required this.repository
  });

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


  Future<void> saveModuleConfigs(String userId) async {
    try {
      _errorMessage = null;

      for (final module in _availableModules) {
        final isActive = isModuleActive(module.id);

        // Persist selection
        await repository.setModuleEnabled(
            userId,
            module.id,
            isActive);

      }

      //Trigger Action Center reload after saving habits
      triggerActionRefresh();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }


}
