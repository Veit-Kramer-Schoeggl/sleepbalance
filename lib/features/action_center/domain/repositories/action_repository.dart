import '../models/daily_action.dart';

/// Abstract repository interface for DailyAction operations
///
/// Defines contract for action data access. Concrete implementations
/// can use different data sources (local DB, remote API, mock data).
///
/// Benefits of abstraction:
/// - Easy to swap implementations for testing
/// - Business logic doesn't depend on data source details
/// - Can combine multiple data sources (local + remote sync)
abstract class ActionRepository {
  /// Retrieves all actions for a specific user and date
  ///
  /// Returns empty list if no actions found.
  /// Throws exception if database operation fails.
  Future<List<DailyAction>> getActionsForDate(String userId, DateTime date);

  /// Saves (inserts or updates) an action
  ///
  /// If action.id already exists, updates the existing record.
  /// Otherwise, inserts a new record.
  Future<void> saveAction(DailyAction action);

  /// Toggles completion status of an action
  ///
  /// Flips isCompleted boolean and updates completedAt timestamp.
  /// - If completing: sets completedAt to now
  /// - If uncompleting: sets completedAt to null
  Future<void> toggleActionCompletion(String actionId);

  /// Counts completed actions for a specific user and date
  ///
  /// Used for progress tracking and statistics.
  /// Returns 0 if no completed actions found.
  Future<int> getCompletionCount(String userId, DateTime date);
}
