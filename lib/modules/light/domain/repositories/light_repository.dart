import 'package:sleepbalance/modules/shared/domain/repositories/intervention_repository.dart';

/// Light Module Repository Interface
///
/// Extends InterventionRepository with light-specific analytics methods.
///
/// Inherits from InterventionRepository:
/// - getUserConfig(userId) - Get user's light module configuration
/// - saveConfig(config) - Save light module configuration
/// - getActivitiesForDate(userId, date) - Get light activities for specific date
/// - getActivitiesBetween(userId, startDate, endDate) - Get activities in date range
/// - logActivity(activity) - Log new light therapy session
/// - updateActivity(activity) - Update existing activity
/// - deleteActivity(activityId) - Delete activity
/// - getCompletionCount(userId, startDate, endDate) - Count completed sessions
/// - getCompletionRate(userId, startDate, endDate) - Calculate completion percentage
abstract class LightRepository extends InterventionRepository {
  /// Get distribution of light types used in date range
  ///
  /// Returns a map of light type to count:
  /// ```dart
  /// {
  ///   'natural_sunlight': 15,
  ///   'light_box': 8,
  ///   'blue_light': 2,
  ///   'red_light': 1
  /// }
  /// ```
  ///
  /// Used for analytics and insights to show which light types
  /// the user prefers or finds most effective.
  ///
  /// Parameters:
  /// - [userId]: User's ID
  /// - [startDate]: Start of date range (inclusive)
  /// - [endDate]: End of date range (inclusive)
  ///
  /// Returns: Map of light type string to occurrence count
  Future<Map<String, int>> getLightTypeDistribution(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}
