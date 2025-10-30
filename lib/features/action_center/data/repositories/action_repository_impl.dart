import '../../domain/models/daily_action.dart';
import '../../domain/repositories/action_repository.dart';
import '../datasources/action_local_datasource.dart';

/// Concrete implementation of ActionRepository using local SQLite database
///
/// Delegates all operations to ActionLocalDataSource.
/// This pattern allows:
/// - Easy mocking for tests (mock the datasource)
/// - Future addition of remote datasource (API calls)
/// - Caching logic between datasource and UI
class ActionRepositoryImpl implements ActionRepository {
  final ActionLocalDataSource _dataSource;

  ActionRepositoryImpl({required ActionLocalDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<DailyAction>> getActionsForDate(String userId, DateTime date) {
    return _dataSource.getActionsByDate(userId, date);
  }

  @override
  Future<void> saveAction(DailyAction action) {
    return _dataSource.insertOrUpdateAction(action);
  }

  @override
  Future<void> toggleActionCompletion(String actionId) {
    return _dataSource.toggleCompletion(actionId);
  }

  @override
  Future<int> getCompletionCount(String userId, DateTime date) {
    return _dataSource.countCompletedActions(userId, date);
  }
}
