import 'package:flutter/material.dart';
import '../../shared/domain/interfaces/module_interface.dart';
import '../../shared/domain/models/user_module_config.dart';
import '../../shared/constants/module_metadata.dart';
import '../presentation/screens/light_config_standard_screen.dart';

/// Light Therapy Module
///
/// Reference implementation of ModuleInterface.
/// Other modules should follow this pattern.
class LightModule implements ModuleInterface {
  @override
  String get moduleId => 'light';

  @override
  ModuleMetadata getMetadata() {
    return moduleMetadata['light']!;
  }

  @override
  Widget getConfigurationScreen({
    required String userId,
    UserModuleConfig? config,
  }) {
    return const LightConfigStandardScreen();
  }

  @override
  Map<String, dynamic> getDefaultConfiguration({
    required String userId,
    TimeOfDay? userWakeTime,
    TimeOfDay? userBedTime,
  }) {
    // Calculate default morning light time (30 min after wake)
    final wakeTime = userWakeTime ?? const TimeOfDay(hour: 7, minute: 0);
    final morningLightTime = _addMinutes(wakeTime, 30);

    return {
      'mode': 'standard', // 'standard' or 'advanced'
      'sessions': [
        {
          'type': 'sunlight', // sunlight, lightbox, bluelight, redlight
          'time': _formatTimeOfDay(morningLightTime),
          'duration': 20, // minutes
          'enabled': true,
          'notificationEnabled': true,
          'notificationOffset': 0, // minutes before session time
        }
      ],
    };
  }

  @override
  String? validateConfiguration(Map<String, dynamic> config) {
    // Validate mode
    final mode = config['mode'];
    if (mode == null || (mode != 'standard' && mode != 'advanced')) {
      return 'Invalid mode. Must be "standard" or "advanced".';
    }

    // Validate sessions
    final sessions = config['sessions'] as List?;
    if (sessions == null || sessions.isEmpty) {
      return 'At least one light session is required.';
    }

    // Validate each session
    for (final session in sessions) {
      if (session is! Map) {
        return 'Invalid session format.';
      }

      // Check required fields
      if (!session.containsKey('type') ||
          !session.containsKey('time') ||
          !session.containsKey('duration')) {
        return 'Session missing required fields (type, time, duration).';
      }

      // Validate duration
      final duration = session['duration'];
      if (duration is! int || duration < 5 || duration > 60) {
        return 'Session duration must be between 5 and 60 minutes.';
      }
    }

    return null; // Valid
  }

  @override
  Future<void> onModuleActivated({
    required String userId,
    required Map<String, dynamic> config,
  }) async {
    // TODO: Schedule notifications for light sessions
    // final notificationService = ...;
    // await notificationService.scheduleLightReminders(userId, config);

    // Lifecycle hook called - notifications would be scheduled here
  }

  @override
  Future<void> onModuleDeactivated({required String userId}) async {
    // TODO: Cancel all light module notifications
    // final notificationService = ...;
    // await notificationService.cancelModuleNotifications(userId, 'light');

    // Lifecycle hook called - notifications would be cancelled here
  }

  @override
  Future<void> onSleepScheduleChanged({
    required String userId,
    required TimeOfDay newWakeTime,
    required TimeOfDay newBedTime,
  }) async {
    // TODO: Recalculate morning light session time
    // Get user's config, update session time to 30 min after new wake time
    // Save updated config

    // Lifecycle hook called - session times would be recalculated here
  }

  // ========================================================================
  // Helper Methods
  // ========================================================================

  /// Add minutes to a TimeOfDay
  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute + minutes;
    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Format TimeOfDay as HH:MM string
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
