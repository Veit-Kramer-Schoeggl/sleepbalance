import 'package:flutter/material.dart';
import '../../shared/domain/interfaces/module_interface.dart';
import '../../shared/domain/models/user_module_config.dart';
import '../../shared/constants/module_metadata.dart';
import '../presentation/screens/sport_config_standard_screen.dart';

/// Sport Module
///
/// Placeholder implementation of ModuleInterface (MVP).
/// Configuration and validation will be expanded in future iterations.
class SportModule implements ModuleInterface {
  @override
  String get moduleId => 'sport';

  @override
  ModuleMetadata getMetadata() {
    return moduleMetadata['sport']!;
  }

  @override
  Widget getConfigurationScreen({
    required String userId,
    UserModuleConfig? config,
  }) {
    return const SportConfigStandardScreen();
  }

  @override
  Map<String, dynamic> getDefaultConfiguration({
    required String userId,
    TimeOfDay? userWakeTime,
    TimeOfDay? userBedTime,
  }) {
    return {
      'info': 'Sport module placeholder (MVP)',
    };
  }

  @override
  String? validateConfiguration(Map<String, dynamic> config) {
    return null; // Placeholder
  }

  @override
  Future<void> onModuleActivated({
    required String userId,
    required Map<String, dynamic> config,
  }) async {}

  @override
  Future<void> onModuleDeactivated({
    required String userId,
  }) async {}

  @override
  Future<void> onSleepScheduleChanged({
    required String userId,
    required TimeOfDay newWakeTime,
    required TimeOfDay newBedTime,
  }) async {}
}
