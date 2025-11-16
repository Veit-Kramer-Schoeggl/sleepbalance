import 'package:sleepbalance/modules/light/data/datasources/light_module_local_datasource.dart';
import 'package:sleepbalance/modules/light/domain/repositories/light_repository.dart';
import 'package:sleepbalance/modules/shared/domain/models/intervention_activity.dart';
import 'package:sleepbalance/modules/shared/domain/models/user_module_config.dart';

/// Light Module Repository Implementation
///
/// Implements LightRepository by delegating all operations to
/// LightModuleLocalDataSource.
///
/// This layer provides abstraction between domain and data layers,
/// allowing us to swap data sources (e.g., add remote sync) without
/// changing domain or presentation code.
class LightModuleRepositoryImpl implements LightRepository {
  final LightModuleLocalDataSource _dataSource;

  LightModuleRepositoryImpl({required LightModuleLocalDataSource dataSource})
      : _dataSource = dataSource;

  // =========================================================================
  // Configuration Operations (inherited from InterventionRepository)
  // =========================================================================

  @override
  Future<UserModuleConfig?> getUserConfig(String userId) {
    return _dataSource.getConfigForUser(userId);
  }

  @override
  Future<void> saveConfig(UserModuleConfig config) {
    return _dataSource.upsertConfig(config);
  }

  // =========================================================================
  // Activity CRUD Operations (inherited from InterventionRepository)
  // =========================================================================

  @override
  Future<List<InterventionActivity>> getActivitiesForDate(
    String userId,
    DateTime date,
  ) {
    return _dataSource.getActivitiesByDate(userId, date);
  }

  @override
  Future<List<InterventionActivity>> getActivitiesBetween(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _dataSource.getActivitiesBetween(userId, startDate, endDate);
  }

  @override
  Future<void> logActivity(InterventionActivity activity) {
    return _dataSource.insertActivity(activity);
  }

  @override
  Future<void> updateActivity(InterventionActivity activity) {
    return _dataSource.updateActivity(activity);
  }

  @override
  Future<void> deleteActivity(String activityId) {
    return _dataSource.deleteActivity(activityId);
  }

  // =========================================================================
  // Analytics Operations (inherited from InterventionRepository)
  // =========================================================================

  @override
  Future<int> getCompletionCount(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _dataSource.getCompletionCountBetween(userId, startDate, endDate);
  }

  @override
  Future<double> getCompletionRate(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _dataSource.getCompletionRateBetween(userId, startDate, endDate);
  }

  // =========================================================================
  // Light-Specific Operations
  // =========================================================================

  @override
  Future<Map<String, int>> getLightTypeDistribution(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _dataSource.getLightTypeDistribution(userId, startDate, endDate);
  }
}
