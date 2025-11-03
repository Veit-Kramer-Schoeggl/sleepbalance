import 'package:flutter/material.dart';
import '../models/user_module_config.dart';
import '../../constants/module_metadata.dart';

/// Interface that all intervention modules must implement
///
/// This contract enables:
/// - Habits Lab to discover and display all modules
/// - Standard lifecycle hooks (activation, deactivation)
/// - Automatic navigation to module-specific screens
/// - Type-safe module interactions
///
/// Each module (Light, Sport, Meditation, etc.) creates a class
/// implementing this interface and registers it with ModuleRegistry.
abstract class ModuleInterface {
  /// Unique module identifier
  ///
  /// Must match:
  /// - moduleMetadata map key
  /// - module_id in database
  /// - module folder name
  ///
  /// Examples: 'light', 'sport', 'meditation'
  String get moduleId;

  /// Get module metadata (name, description, icon, colors)
  ///
  /// Returns metadata from moduleMetadata map.
  /// Used by Habits Lab to display module information.
  ModuleMetadata getMetadata();

  /// Get the configuration screen for this module
  ///
  /// This screen allows users to customize module settings.
  /// Called when user taps module in Habits Lab.
  ///
  /// Parameters:
  /// - userId: Current user's ID
  /// - config: Existing configuration (null if first time setup)
  ///
  /// Returns: Module-specific configuration screen widget
  ///
  /// Example: LightModule returns LightConfigScreen
  Widget getConfigurationScreen({
    required String userId,
    UserModuleConfig? config,
  });

  /// Get default configuration when module is first activated
  ///
  /// Returns Map containing science-based default settings.
  /// Stored in user_module_configurations.configuration as JSON.
  ///
  /// Parameters:
  /// - userId: User's ID (for personalization if needed)
  /// - userWakeTime: User's typical wake time (from settings)
  /// - userBedTime: User's typical bed time (from settings)
  ///
  /// Returns: JSON-serializable Map\<String, dynamic\>
  ///
  /// Example for Light module:
  /// ```dart
  /// {
  ///   'mode': 'standard',
  ///   'sessions': [
  ///     {
  ///       'type': 'sunlight',
  ///       'time': '07:30',  // 30 min after wake
  ///       'duration': 20,
  ///       'enabled': true,
  ///       'notificationEnabled': true,
  ///     }
  ///   ]
  /// }
  /// ```
  Map<String, dynamic> getDefaultConfiguration({
    required String userId,
    TimeOfDay? userWakeTime,
    TimeOfDay? userBedTime,
  });

  /// Validate module configuration before saving
  ///
  /// Called before updating user_module_configurations.
  /// Allows module to enforce business rules.
  ///
  /// Parameters:
  /// - config: Configuration Map to validate
  ///
  /// Returns:
  /// - null if valid
  /// - Error message string if invalid
  ///
  /// Example validations:
  /// - At least one session configured
  /// - Duration values in valid range (5-60 minutes)
  /// - Time values properly formatted
  String? validateConfiguration(Map<String, dynamic> config);

  /// Called when module is activated by user
  ///
  /// Use this hook to:
  /// - Schedule initial notifications
  /// - Initialize module-specific services
  /// - Log analytics events
  ///
  /// Parameters:
  /// - userId: User who activated the module
  /// - config: Module configuration (from getDefaultConfiguration or user customization)
  ///
  /// This method is async to support database/network operations.
  Future<void> onModuleActivated({
    required String userId,
    required Map<String, dynamic> config,
  });

  /// Called when module is deactivated by user
  ///
  /// Use this hook to:
  /// - Cancel all scheduled notifications
  /// - Clean up resources
  /// - Log analytics events
  ///
  /// IMPORTANT: Do NOT delete user data or activity history.
  /// Only cleanup active resources (notifications, listeners, etc.)
  ///
  /// Parameters:
  /// - userId: User who deactivated the module
  Future<void> onModuleDeactivated({
    required String userId,
  });

  /// Called when user's sleep schedule changes
  ///
  /// Modules can update their recommendations and reschedule
  /// notifications based on new wake/bed times.
  ///
  /// Optional to implement - modules with timing-dependent
  /// features should implement this.
  ///
  /// Parameters:
  /// - userId: User whose schedule changed
  /// - newWakeTime: New wake time
  /// - newBedTime: New bed time
  ///
  /// Example: Light module recalculates morning session time
  /// to be 30 minutes after new wake time.
  Future<void> onSleepScheduleChanged({
    required String userId,
    required TimeOfDay newWakeTime,
    required TimeOfDay newBedTime,
  }) async {
    // Default implementation: do nothing
    // Modules can override if they need to react to schedule changes
  }
}
