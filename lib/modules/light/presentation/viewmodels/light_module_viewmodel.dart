import 'package:flutter/foundation.dart';
// import 'package:sleepbalance/core/notifications/notification_service.dart'; // TODO: Implement NotificationService
import 'package:sleepbalance/core/utils/uuid_generator.dart';
import 'package:sleepbalance/modules/light/domain/models/light_activity.dart';
import 'package:sleepbalance/modules/light/domain/models/light_config.dart';
import 'package:sleepbalance/modules/light/domain/repositories/light_repository.dart';
import 'package:sleepbalance/modules/shared/domain/models/intervention_activity.dart';
import 'package:sleepbalance/modules/shared/domain/models/user_module_config.dart';

/// Light Module ViewModel
///
/// Manages state and business logic for Light Therapy module.
/// Follows Phase 5 error handling pattern with proper loading and error states.
///
/// State includes:
/// - Module configuration (LightConfig)
/// - Module enabled status
/// - Activities for current date
/// - Loading and error states
class LightModuleViewModel extends ChangeNotifier {
  final LightRepository _repository;
  // final NotificationService _notificationService; // TODO: Implement NotificationService

  // =========================================================================
  // State
  // =========================================================================

  UserModuleConfig? _config;
  LightConfig? _lightConfig;
  List<InterventionActivity> _activities = [];
  bool _isEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  // =========================================================================
  // Getters
  // =========================================================================

  UserModuleConfig? get config => _config;
  LightConfig? get lightConfig => _lightConfig;
  List<InterventionActivity> get activities => List.unmodifiable(_activities);
  bool get isEnabled => _isEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  LightModuleViewModel({
    required LightRepository repository,
    // required NotificationService notificationService, // TODO: Add when NotificationService is implemented
  }) : _repository = repository;
        // _notificationService = notificationService;

  // =========================================================================
  // Configuration Operations
  // =========================================================================

  /// Load Light module configuration for user
  ///
  /// If no configuration exists, initializes with standard mode defaults.
  /// Sets loading and error states appropriately.
  Future<void> loadConfig(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _config = await _repository.getUserConfig(userId);

      if (_config != null) {
        // Parse configuration JSON to LightConfig
        _lightConfig = LightConfig.fromJson(_config!.configuration);
        _isEnabled = _config!.isEnabled;
      } else {
        // First time - use defaults
        _lightConfig = LightConfig.standardDefault();
        _isEnabled = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load configuration: $e';
      debugPrint('LightModuleViewModel: Error in loadConfig: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save Light module configuration
  ///
  /// Creates or updates UserModuleConfig with LightConfig JSON.
  /// Schedules notifications if module is enabled.
  Future<void> saveConfig(String userId, LightConfig lightConfig) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Validate configuration
      final validationError = lightConfig.validate();
      if (validationError != null) {
        throw Exception('Invalid configuration: $validationError');
      }

      // Create or update UserModuleConfig
      final now = DateTime.now();
      final newConfig = UserModuleConfig(
        id: _config?.id ?? UuidGenerator.generate(),
        userId: userId,
        moduleId: 'light',
        isEnabled: _isEnabled,
        configuration: lightConfig.toJson(),
        enrolledAt: _config?.enrolledAt ?? now,
        updatedAt: now,
      );

      await _repository.saveConfig(newConfig);

      _config = newConfig;
      _lightConfig = lightConfig;

      // Schedule notifications if enabled
      if (_isEnabled) {
        await scheduleNotifications(userId, lightConfig);
      }
    } catch (e) {
      _errorMessage = 'Failed to save configuration: $e';
      debugPrint('LightModuleViewModel: Error in saveConfig: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle Light module on/off
  ///
  /// When enabled: schedules notifications
  /// When disabled: cancels all notifications
  Future<void> toggleModule(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final newEnabledState = !_isEnabled;

      // Update config with new enabled state
      if (_config != null && _lightConfig != null) {
        final updatedConfig = UserModuleConfig(
          id: _config!.id,
          userId: userId,
          moduleId: 'light',
          isEnabled: newEnabledState,
          configuration: _lightConfig!.toJson(),
          enrolledAt: _config!.enrolledAt,
          updatedAt: DateTime.now(),
        );

        await _repository.saveConfig(updatedConfig);

        _config = updatedConfig;
        _isEnabled = newEnabledState;

        // Handle notifications
        if (newEnabledState && _lightConfig != null) {
          await scheduleNotifications(userId, _lightConfig!);
        } else {
          await cancelNotifications();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to toggle module: $e';
      debugPrint('LightModuleViewModel: Error in toggleModule: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // Activity Operations
  // =========================================================================

  /// Load Light activities for specific date
  ///
  /// Loads all light therapy sessions logged on the given date.
  Future<void> loadActivities(String userId, DateTime date) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _activities = await _repository.getActivitiesForDate(userId, date);
    } catch (e) {
      _errorMessage = 'Failed to load activities: $e';
      debugPrint('LightModuleViewModel: Error in loadActivities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Log new Light therapy activity
  ///
  /// Records a light therapy session with all details.
  /// Refreshes activities list after successful insert.
  Future<void> logActivity(String userId, LightActivity activity) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.logActivity(activity);

      // Refresh activities for the activity's date
      await loadActivities(userId, activity.activityDate);
    } catch (e) {
      _errorMessage = 'Failed to log activity: $e';
      debugPrint('LightModuleViewModel: Error in logActivity: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update existing Light activity
  ///
  /// Modifies an existing activity record.
  /// Refreshes activities list after successful update.
  Future<void> updateActivity(String userId, LightActivity activity) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.updateActivity(activity);

      // Refresh activities for the activity's date
      await loadActivities(userId, activity.activityDate);
    } catch (e) {
      _errorMessage = 'Failed to update activity: $e';
      debugPrint('LightModuleViewModel: Error in updateActivity: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete Light activity
  ///
  /// Removes an activity record.
  /// Refreshes activities list after successful delete.
  Future<void> deleteActivity(String userId, String activityId,
      DateTime activityDate) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.deleteActivity(activityId);

      // Refresh activities for the deleted activity's date
      await loadActivities(userId, activityDate);
    } catch (e) {
      _errorMessage = 'Failed to delete activity: $e';
      debugPrint('LightModuleViewModel: Error in deleteActivity: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // Notification Operations
  // =========================================================================

  /// Schedule all Light module notifications
  ///
  /// Schedules up to 3 notification types:
  /// 1. Morning reminder (if enabled)
  /// 2. Evening dim reminder (if enabled)
  /// 3. Blue blocker reminder (if enabled)
  ///
  /// Cancels existing notifications first to avoid duplicates.
  ///
  /// TODO: Implement when NotificationService is available
  Future<void> scheduleNotifications(
      String userId, LightConfig config) async {
    try {
      // Cancel existing notifications first
      await cancelNotifications();

      if (!_isEnabled) return;

      // TODO: Implement notification scheduling when NotificationService is available
      debugPrint('LightModuleViewModel: Notification scheduling not yet implemented');

      // // Schedule morning reminder
      // if (config.morningReminderEnabled) {
      //   await _notificationService.scheduleNotification(
      //     id: 'light_morning',
      //     title: 'Light Therapy Reminder',
      //     body: 'Time for your morning bright light session!',
      //     scheduledTime: _parseTimeOfDay(config.morningReminderTime),
      //   );
      // }

      // // Schedule evening dim reminder
      // if (config.eveningDimReminderEnabled) {
      //   await _notificationService.scheduleNotification(
      //     id: 'light_evening_dim',
      //     title: 'Dim Lights Reminder',
      //     body: 'Start dimming lights to support melatonin production',
      //     scheduledTime: _parseTimeOfDay(config.eveningDimTime),
      //   );
      // }

      // // Schedule blue blocker reminder
      // if (config.blueBlockerReminderEnabled) {
      //   await _notificationService.scheduleNotification(
      //     id: 'light_blue_blocker',
      //     title: 'Blue Blocker Reminder',
      //     body: 'Put on blue blocking glasses',
      //     scheduledTime: _parseTimeOfDay(config.blueBlockerTime),
      //   );
      // }
    } catch (e) {
      _errorMessage = 'Failed to schedule notifications: $e';
      debugPrint('LightModuleViewModel: Error in scheduleNotifications: $e');
    }
  }

  /// Cancel all Light module notifications
  ///
  /// Cancels all 3 notification types.
  /// Safe to call even if notifications don't exist (idempotent).
  ///
  /// TODO: Implement when NotificationService is available
  Future<void> cancelNotifications() async {
    try {
      // TODO: Implement notification cancellation when NotificationService is available
      debugPrint('LightModuleViewModel: Notification cancellation not yet implemented');

      // await _notificationService.cancelNotification('light_morning');
      // await _notificationService.cancelNotification('light_evening_dim');
      // await _notificationService.cancelNotification('light_blue_blocker');
    } catch (e) {
      _errorMessage = 'Failed to cancel notifications: $e';
      debugPrint('LightModuleViewModel: Error in cancelNotifications: $e');
    }
  }

  // =========================================================================
  // Helper Methods
  // =========================================================================

  /// Parse time string (HH:mm) to DateTime
  ///
  /// Returns DateTime for today at the specified time.
  /// Used for notification scheduling.
  DateTime _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Clear error message
  ///
  /// Call this after user acknowledges error to reset error state.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
