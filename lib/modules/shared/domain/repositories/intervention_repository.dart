import '../models/intervention_activity.dart';
import '../models/user_module_config.dart';

/// Base repository interface for intervention modules that track daily activities.
///
/// Provides common CRUD operations for:
/// - Module configuration (settings)
/// - Activity tracking (daily completion)
/// - Analytics (completion rates, statistics)
///
/// Each module extends this interface with module-specific methods.
///
/// **Used by:** Light, Sport, Temperature, Mealtime, Meditation, Journaling modules
/// **Not used by:** Nutrition (educational module with different pattern)
///
/// Example:
/// ```dart
/// abstract class LightRepository extends InterventionRepository {
///   // Light-specific methods...
/// }
/// ```
abstract class InterventionRepository {
  // =========================================================================
  // Configuration Operations
  // =========================================================================

  /// Get user's configuration for this module.
  ///
  /// Returns null if user hasn't configured this module yet.
  ///
  /// Example:
  /// ```dart
  /// final config = await lightRepository.getUserConfig('user-123');
  /// final mode = config?.getConfigValue<String>('mode'); // 'standard' or 'advanced'
  /// ```
  Future<UserModuleConfig?> getUserConfig(String userId);

  /// Save or update user's module configuration.
  ///
  /// Stores module settings in user_module_configurations table.
  /// Configuration is validated by module before saving.
  ///
  /// Example:
  /// ```dart
  /// final newConfig = UserModuleConfig(
  ///   id: uuid.v4(),
  ///   userId: 'user-123',
  ///   moduleId: 'light',
  ///   isEnabled: true,
  ///   configuration: {'mode': 'advanced', 'sessions': [...]},
  ///   enrolledAt: DateTime.now(),
  /// );
  /// await lightRepository.saveConfig(newConfig);
  /// ```
  Future<void> saveConfig(UserModuleConfig config);

  // =========================================================================
  // Activity CRUD Operations
  // =========================================================================

  /// Get all activities for a specific date.
  ///
  /// Returns activities for this module on the given date.
  /// Used by daily tracking screens and calendar views.
  ///
  /// Parameters:
  /// - [userId]: User's ID
  /// - [date]: The date to query (time component ignored)
  ///
  /// Returns: List of activities, may be empty
  Future<List<InterventionActivity>> getActivitiesForDate(
    String userId,
    DateTime date,
  );

  /// Get activities within a date range.
  ///
  /// Used for analytics, trend visualization, and reports.
  ///
  /// Parameters:
  /// - [userId]: User's ID
  /// - [startDate]: Start of range (inclusive)
  /// - [endDate]: End of range (inclusive)
  ///
  /// Returns: List of activities ordered by date descending
  Future<List<InterventionActivity>> getActivitiesBetween(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Log a new activity.
  ///
  /// Called when user completes an intervention.
  /// Creates new record in intervention_activities table.
  ///
  /// Example:
  /// ```dart
  /// final activity = InterventionActivity(
  ///   id: uuid.v4(),
  ///   userId: 'user-123',
  ///   moduleId: 'light',
  ///   activityDate: DateTime.now(),
  ///   wasCompleted: true,
  ///   completedAt: DateTime.now(),
  ///   durationMinutes: 20,
  ///   timeOfDay: 'morning',
  ///   moduleSpecificData: {'type': 'sunlight', 'location': 'outdoors'},
  ///   createdAt: DateTime.now(),
  /// );
  /// await lightRepository.logActivity(activity);
  /// ```
  Future<void> logActivity(InterventionActivity activity);

  /// Update existing activity.
  ///
  /// Allows user to edit logged activities (fix mistakes, add notes).
  ///
  /// Parameters:
  /// - [activity]: Activity with updated fields
  ///
  /// Throws: Exception if activity doesn't exist
  Future<void> updateActivity(InterventionActivity activity);

  /// Delete activity.
  ///
  /// Permanently removes activity record.
  ///
  /// Parameters:
  /// - [activityId]: UUID of activity to delete
  Future<void> deleteActivity(String activityId);

  // =========================================================================
  // Analytics & Statistics
  // =========================================================================

  /// Get count of completed activities in date range.
  ///
  /// Only counts activities where wasCompleted = true.
  /// Used for streak tracking and milestone achievements.
  ///
  /// Example:
  /// ```dart
  /// final last30Days = await lightRepository.getCompletionCount(
  ///   'user-123',
  ///   DateTime.now().subtract(Duration(days: 30)),
  ///   DateTime.now(),
  /// ); // Returns: 23 (user completed light therapy 23 out of 30 days)
  /// ```
  Future<int> getCompletionCount(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get completion rate as percentage.
  ///
  /// Calculates: (completed activities / total days in range) * 100
  ///
  /// Returns:
  /// - 0.0 to 100.0 (percentage)
  /// - 0.0 if no activities in range
  ///
  /// Example:
  /// ```dart
  /// final rate = await lightRepository.getCompletionRate(
  ///   'user-123',
  ///   DateTime.now().subtract(Duration(days: 7)),
  ///   DateTime.now(),
  /// ); // Returns: 71.4 (5 out of 7 days = 71.4%)
  /// ```
  Future<double> getCompletionRate(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}
