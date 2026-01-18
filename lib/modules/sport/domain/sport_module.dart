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
  /// Unique identifier for the sport module.
  @override
  String get moduleId => 'sport';

  /// Retrieves metadata for the sport module, including name and icon.
  @override
  ModuleMetadata getMetadata() {
    return moduleMetadata['sport']!;
  }

  /// Returns the configuration screen for the sport module.
  @override
  Widget getConfigurationScreen({
    required String userId,
    UserModuleConfig? config,
  }) {
    return const SportConfigStandardScreen();
  }

  /// Returns the default configuration for the sport module (MVP placeholder).
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

  /// Validates the sport module's configuration.
  @override
  String? validateConfiguration(Map<String, dynamic> config) {
    return null; // Placeholder
  }

  /// Lifecycle hook called when the sport module is activated.
  @override
  Future<void> onModuleActivated({
    required String userId,
    required Map<String, dynamic> config,
  }) async {}

  /// Lifecycle hook called when the sport module is deactivated.
  @override
  Future<void> onModuleDeactivated({
    required String userId,
  }) async {}

  /// Lifecy cle hook called when the user's sleep schedule changes.
  @override
  Future<void> onSleepScheduleChanged({
    required String userId,
    required TimeOfDay newWakeTime,
    required TimeOfDay newBedTime,
  }) async {}
}
