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
  @override
  String get moduleId => 'meditation';

  @override
  ModuleMetadata getMetadata() {
    return moduleMetadata['meditation']!;
  }

  @override
  Widget getConfigurationScreen({
    required String userId,
    UserModuleConfig? config,
  }) {
    return const MeditationConfigStandardScreen();
  }

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

  @override
  String? validateConfiguration(Map<String, dynamic> config) {
    return null;
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
