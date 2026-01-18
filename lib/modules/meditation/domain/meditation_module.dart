import 'package:flutter/material.dart';
import '../../shared/domain/interfaces/module_interface.dart';
import '../../shared/domain/models/user_module_config.dart';
import '../../shared/constants/module_metadata.dart';
import '../presentation/screens/meditation_config_standard_screen.dart';

/// Meditation Module
///
/// Placeholder implementation of ModuleInterface (MVP).
/// Configuration and validation will be expanded in future iterations.
class MeditationModule implements ModuleInterface {
  /// Unique identifier for the meditation module.
  @override
  String get moduleId => 'meditation';

  /// Retrieves metadata for the meditation module, including name and icon.
  @override
  ModuleMetadata getMetadata() {
    return moduleMetadata['meditation']!;
  }

  /// Returns the configuration screen for the meditation module.
  @override
  Widget getConfigurationScreen({
    required String userId,
    UserModuleConfig? config,
  }) {
    return const MeditationConfigStandardScreen();
  }

  /// Returns the default configuration for the meditation module (MVP placeholder).
  @override
  Map<String, dynamic> getDefaultConfiguration({
    required String userId,
    TimeOfDay? userWakeTime,
    TimeOfDay? userBedTime,
  }) {
    return {
      'info': 'Meditation module placeholder (MVP)',
    };
  }

  /// Validates the meditation module's configuration.
  @override
  String? validateConfiguration(Map<String, dynamic> config) {
    return null; // Placeholder
  }

  /// Lifecycle hook called when the meditation module is activated.
  @override
  Future<void> onModuleActivated({
    required String userId,
    required Map<String, dynamic> config,
  }) async {}

  /// Lifecycle hook called when the meditation module is deactivated.
  @override
  Future<void> onModuleDeactivated({
    required String userId,
  }) async {}

  /// Lifecycle hook called when the user's sleep schedule changes.
  @override
  Future<void> onSleepScheduleChanged({
    required String userId,
    required TimeOfDay newWakeTime,
    required TimeOfDay newBedTime,
  }) async {}
}
