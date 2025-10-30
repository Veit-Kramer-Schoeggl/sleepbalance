import 'package:sqflite/sqflite.dart';
import '../../../../core/utils/database_date_utils.dart';
import '../../../../shared/constants/database_constants.dart';
import '../../domain/models/daily_action.dart';

/// Local data source for DailyAction using SQLite
///
/// Handles all SQLite CRUD operations for daily_actions table.
/// Separates raw database operations from business logic.
class ActionLocalDataSource {
  final Database database;

  ActionLocalDataSource({required this.database});

  /// Retrieves all actions for a specific user and date
  ///
  /// Orders results by creation time (oldest first).
  /// Returns empty list if no actions found.
  Future<List<DailyAction>> getActionsByDate(
      String userId, DateTime date) async {
    final dateStr = DatabaseDateUtils.toDateString(date);

    final results = await database.query(
      TABLE_DAILY_ACTIONS,
      where: '$DAILY_ACTIONS_USER_ID = ? AND $DAILY_ACTIONS_ACTION_DATE = ?',
      whereArgs: [userId, dateStr],
      orderBy: '$DAILY_ACTIONS_CREATED_AT ASC',
    );

    return results.map((map) => DailyAction.fromDatabase(map)).toList();
  }

  /// Inserts or updates an action
  ///
  /// Uses REPLACE conflict algorithm:
  /// - If action.id exists: updates existing record
  /// - If action.id is new: inserts new record
  Future<void> insertOrUpdateAction(DailyAction action) async {
    await database.insert(
      TABLE_DAILY_ACTIONS,
      action.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Toggles completion status of an action
  ///
  /// Steps:
  /// 1. Fetch current action state
  /// 2. Flip isCompleted boolean
  /// 3. Update completedAt timestamp (now if completing, null if uncompleting)
  /// 4. Save back to database
  Future<void> toggleCompletion(String actionId) async {
    // Fetch current state
    final result = await database.query(
      TABLE_DAILY_ACTIONS,
      where: '$DAILY_ACTIONS_ID = ?',
      whereArgs: [actionId],
      limit: 1,
    );

    if (result.isEmpty) return;

    final action = DailyAction.fromDatabase(result.first);
    final newCompleted = !action.isCompleted;

    await database.update(
      TABLE_DAILY_ACTIONS,
      {
        DAILY_ACTIONS_IS_COMPLETED: newCompleted ? 1 : 0,
        DAILY_ACTIONS_COMPLETED_AT: newCompleted
            ? DatabaseDateUtils.toTimestamp(DateTime.now())
            : null,
      },
      where: '$DAILY_ACTIONS_ID = ?',
      whereArgs: [actionId],
    );
  }

  /// Counts completed actions for a user on a specific date
  ///
  /// Uses SQL COUNT(*) for efficiency.
  /// Returns 0 if no completed actions found.
  Future<int> countCompletedActions(String userId, DateTime date) async {
    final dateStr = DatabaseDateUtils.toDateString(date);

    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM $TABLE_DAILY_ACTIONS '
      'WHERE $DAILY_ACTIONS_USER_ID = ? '
      'AND $DAILY_ACTIONS_ACTION_DATE = ? '
      'AND $DAILY_ACTIONS_IS_COMPLETED = 1',
      [userId, dateStr],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
