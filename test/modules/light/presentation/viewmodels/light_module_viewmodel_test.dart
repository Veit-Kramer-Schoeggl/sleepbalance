import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/modules/light/domain/models/light_config.dart';
import 'package:sleepbalance/modules/light/domain/models/light_activity.dart';
import 'package:sleepbalance/modules/light/domain/repositories/light_repository.dart';
import 'package:sleepbalance/modules/light/presentation/viewmodels/light_module_viewmodel.dart';
import 'package:sleepbalance/modules/shared/domain/models/intervention_activity.dart';
import 'package:sleepbalance/modules/shared/domain/models/user_module_config.dart';

/// Mock Repository for Testing
///
/// Simple manual mock that allows controlling return values and exceptions.
class MockLightRepository implements LightRepository {
  // Control flags for test scenarios
  bool shouldThrowError = false;
  String errorMessage = 'Test error';

  // Storage for test verification
  UserModuleConfig? storedConfig;
  List<InterventionActivity> storedActivities = [];

  // Return values
  UserModuleConfig? _configToReturn;
  List<InterventionActivity> _activitiesToReturn = [];

  void setConfigToReturn(UserModuleConfig? config) {
    _configToReturn = config;
  }

  void setActivitiesToReturn(List<InterventionActivity> activities) {
    _activitiesToReturn = activities;
  }

  @override
  Future<UserModuleConfig?> getUserConfig(String userId) async {
    if (shouldThrowError) throw Exception(errorMessage);
    return _configToReturn;
  }

  @override
  Future<void> saveConfig(UserModuleConfig config) async {
    if (shouldThrowError) throw Exception(errorMessage);
    storedConfig = config;
  }

  @override
  Future<List<InterventionActivity>> getActivitiesForDate(
    String userId,
    DateTime date,
  ) async {
    if (shouldThrowError) throw Exception(errorMessage);
    return _activitiesToReturn;
  }

  @override
  Future<List<InterventionActivity>> getActivitiesBetween(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (shouldThrowError) throw Exception(errorMessage);
    return _activitiesToReturn;
  }

  @override
  Future<void> logActivity(InterventionActivity activity) async {
    if (shouldThrowError) throw Exception(errorMessage);
    storedActivities.add(activity);
  }

  @override
  Future<void> updateActivity(InterventionActivity activity) async {
    if (shouldThrowError) throw Exception(errorMessage);
    final index = storedActivities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      storedActivities[index] = activity;
    }
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    if (shouldThrowError) throw Exception(errorMessage);
    storedActivities.removeWhere((a) => a.id == activityId);
  }

  @override
  Future<int> getCompletionCount(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (shouldThrowError) throw Exception(errorMessage);
    return storedActivities.where((a) => a.wasCompleted).length;
  }

  @override
  Future<double> getCompletionRate(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (shouldThrowError) throw Exception(errorMessage);
    if (storedActivities.isEmpty) return 0.0;
    final completed = storedActivities.where((a) => a.wasCompleted).length;
    return (completed / storedActivities.length) * 100.0;
  }

  @override
  Future<Map<String, int>> getLightTypeDistribution(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (shouldThrowError) throw Exception(errorMessage);
    final distribution = <String, int>{};
    for (final activity in storedActivities) {
      if (activity.moduleSpecificData != null) {
        final lightType = activity.moduleSpecificData!['light_type'] as String?;
        if (lightType != null) {
          distribution[lightType] = (distribution[lightType] ?? 0) + 1;
        }
      }
    }
    return distribution;
  }

  void reset() {
    shouldThrowError = false;
    storedConfig = null;
    storedActivities.clear();
    _configToReturn = null;
    _activitiesToReturn = [];
  }
}

void main() {
  group('LightModuleViewModel', () {
    late MockLightRepository mockRepository;
    late LightModuleViewModel viewModel;

    setUp(() {
      mockRepository = MockLightRepository();
      viewModel = LightModuleViewModel(repository: mockRepository);
    });

    tearDown(() {
      mockRepository.reset();
    });

    group('loadConfig', () {
      test('loads existing configuration successfully', () async {
        final testConfig = UserModuleConfig(
          id: 'config-1',
          userId: 'user-1',
          moduleId: 'light',
          isEnabled: true,
          configuration: LightConfig.standardDefault().toJson(),
          enrolledAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        mockRepository.setConfigToReturn(testConfig);

        expect(viewModel.isLoading, false);
        expect(viewModel.config, null);

        await viewModel.loadConfig('user-1');

        expect(viewModel.isLoading, false);
        expect(viewModel.config, isNotNull);
        expect(viewModel.lightConfig, isNotNull);
        expect(viewModel.lightConfig!.mode, 'standard');
        expect(viewModel.isEnabled, true);
        expect(viewModel.hasError, false);
      });

      test('initializes with defaults when no config exists', () async {
        mockRepository.setConfigToReturn(null);

        await viewModel.loadConfig('user-1');

        expect(viewModel.config, null);
        expect(viewModel.lightConfig, isNotNull);
        expect(viewModel.lightConfig!.mode, 'standard');
        expect(viewModel.isEnabled, false);
        expect(viewModel.hasError, false);
      });

      test('sets loading state during execution', () async {
        mockRepository.setConfigToReturn(null);

        bool wasLoadingDuringExecution = false;
        viewModel.addListener(() {
          if (viewModel.isLoading) {
            wasLoadingDuringExecution = true;
          }
        });

        await viewModel.loadConfig('user-1');

        expect(wasLoadingDuringExecution, true);
        expect(viewModel.isLoading, false);
      });

      test('handles errors gracefully', () async {
        mockRepository.shouldThrowError = true;
        mockRepository.errorMessage = 'Database connection failed';

        await viewModel.loadConfig('user-1');

        expect(viewModel.hasError, true);
        expect(viewModel.errorMessage, contains('Failed to load configuration'));
        expect(viewModel.errorMessage, contains('Database connection failed'));
        expect(viewModel.isLoading, false);
      });
    });

    group('saveConfig', () {
      test('saves valid configuration successfully', () async {
        final config = LightConfig.standardDefault();

        await viewModel.saveConfig('user-1', config);

        expect(mockRepository.storedConfig, isNotNull);
        expect(mockRepository.storedConfig!.userId, 'user-1');
        expect(mockRepository.storedConfig!.moduleId, 'light');
        expect(viewModel.lightConfig, isNotNull);
        expect(viewModel.hasError, false);
      });

      test('rejects invalid configuration', () async {
        final invalidConfig = LightConfig(
          mode: 'standard',
          // Missing required fields
        );

        await viewModel.saveConfig('user-1', invalidConfig);

        expect(viewModel.hasError, true);
        expect(viewModel.errorMessage, contains('Invalid configuration'));
        expect(mockRepository.storedConfig, null);
      });

      test('handles save errors gracefully', () async {
        mockRepository.shouldThrowError = true;
        final config = LightConfig.standardDefault();

        await viewModel.saveConfig('user-1', config);

        expect(viewModel.hasError, true);
        expect(viewModel.errorMessage, contains('Failed to save configuration'));
        expect(viewModel.isLoading, false);
      });

      test('updates timestamps correctly', () async {
        final config = LightConfig.standardDefault();
        final before = DateTime.now();

        await viewModel.saveConfig('user-1', config);

        final after = DateTime.now();
        final savedConfig = mockRepository.storedConfig!;

        expect(savedConfig.updatedAt.isAfter(before) ||
               savedConfig.updatedAt.isAtSameMomentAs(before), true);
        expect(savedConfig.updatedAt.isBefore(after) ||
               savedConfig.updatedAt.isAtSameMomentAs(after), true);
      });
    });

    group('toggleModule', () {
      test('enables module when currently disabled', () async {
        // Setup: Load config first
        final testConfig = UserModuleConfig(
          id: 'config-1',
          userId: 'user-1',
          moduleId: 'light',
          isEnabled: false,
          configuration: LightConfig.standardDefault().toJson(),
          enrolledAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        mockRepository.setConfigToReturn(testConfig);
        await viewModel.loadConfig('user-1');

        expect(viewModel.isEnabled, false);

        await viewModel.toggleModule('user-1');

        expect(viewModel.isEnabled, true);
        expect(mockRepository.storedConfig!.isEnabled, true);
        expect(viewModel.hasError, false);
      });

      test('disables module when currently enabled', () async {
        // Setup: Load enabled config first
        final testConfig = UserModuleConfig(
          id: 'config-1',
          userId: 'user-1',
          moduleId: 'light',
          isEnabled: true,
          configuration: LightConfig.standardDefault().toJson(),
          enrolledAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        mockRepository.setConfigToReturn(testConfig);
        await viewModel.loadConfig('user-1');

        expect(viewModel.isEnabled, true);

        await viewModel.toggleModule('user-1');

        expect(viewModel.isEnabled, false);
        expect(mockRepository.storedConfig!.isEnabled, false);
      });

      test('handles toggle errors gracefully', () async {
        // Setup
        final testConfig = UserModuleConfig(
          id: 'config-1',
          userId: 'user-1',
          moduleId: 'light',
          isEnabled: false,
          configuration: LightConfig.standardDefault().toJson(),
          enrolledAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        mockRepository.setConfigToReturn(testConfig);
        await viewModel.loadConfig('user-1');

        mockRepository.shouldThrowError = true;

        await viewModel.toggleModule('user-1');

        expect(viewModel.hasError, true);
        expect(viewModel.errorMessage, contains('Failed to toggle module'));
      });
    });

    group('loadActivities', () {
      test('loads activities for specific date', () async {
        final testDate = DateTime(2025, 1, 15);
        final activities = [
          LightActivity(
            id: 'activity-1',
            userId: 'user-1',
            activityDate: testDate,
            wasCompleted: true,
            createdAt: DateTime.now(),
            lightType: 'natural_sunlight',
          ),
        ];
        mockRepository.setActivitiesToReturn(activities);

        await viewModel.loadActivities('user-1', testDate);

        expect(viewModel.activities.length, 1);
        expect(viewModel.hasError, false);
      });

      test('handles empty activity list', () async {
        mockRepository.setActivitiesToReturn([]);

        await viewModel.loadActivities('user-1', DateTime.now());

        expect(viewModel.activities.isEmpty, true);
        expect(viewModel.hasError, false);
      });

      test('handles load errors gracefully', () async {
        mockRepository.shouldThrowError = true;

        await viewModel.loadActivities('user-1', DateTime.now());

        expect(viewModel.hasError, true);
        expect(viewModel.errorMessage, contains('Failed to load activities'));
      });
    });

    group('logActivity', () {
      test('logs activity and refreshes list', () async {
        final testDate = DateTime(2025, 1, 15);
        final activity = LightActivity(
          id: 'activity-1',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: DateTime.now(),
          lightType: 'light_box',
          durationMinutes: 30,
        );

        await viewModel.logActivity('user-1', activity);

        expect(mockRepository.storedActivities.length, 1);
        expect(mockRepository.storedActivities.first.id, 'activity-1');
        expect(viewModel.hasError, false);
      });

      test('handles log errors gracefully', () async {
        mockRepository.shouldThrowError = true;
        final activity = LightActivity(
          id: 'activity-1',
          userId: 'user-1',
          activityDate: DateTime.now(),
          wasCompleted: true,
          createdAt: DateTime.now(),
          lightType: 'blue_light',
        );

        await viewModel.logActivity('user-1', activity);

        expect(viewModel.hasError, true);
        expect(viewModel.errorMessage, contains('Failed to log activity'));
      });
    });

    group('updateActivity', () {
      test('updates existing activity', () async {
        final testDate = DateTime(2025, 1, 15);
        final original = LightActivity(
          id: 'activity-1',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: DateTime.now(),
          lightType: 'natural_sunlight',
          durationMinutes: 20,
        );
        mockRepository.storedActivities.add(original);

        final updated = original.copyWithLight(durationMinutes: 40);

        await viewModel.updateActivity('user-1', updated);

        expect(mockRepository.storedActivities.first.durationMinutes, 40);
        expect(viewModel.hasError, false);
      });

      test('handles update errors gracefully', () async {
        mockRepository.shouldThrowError = true;
        final activity = LightActivity(
          id: 'activity-1',
          userId: 'user-1',
          activityDate: DateTime.now(),
          wasCompleted: true,
          createdAt: DateTime.now(),
          lightType: 'red_light',
        );

        await viewModel.updateActivity('user-1', activity);

        expect(viewModel.hasError, true);
        expect(viewModel.errorMessage, contains('Failed to update activity'));
      });
    });

    group('deleteActivity', () {
      test('deletes activity successfully', () async {
        final testDate = DateTime(2025, 1, 15);
        final activity = LightActivity(
          id: 'activity-1',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: DateTime.now(),
          lightType: 'light_box',
        );
        mockRepository.storedActivities.add(activity);

        expect(mockRepository.storedActivities.length, 1);

        await viewModel.deleteActivity('user-1', 'activity-1', testDate);

        expect(mockRepository.storedActivities.isEmpty, true);
        expect(viewModel.hasError, false);
      });

      test('handles delete errors gracefully', () async {
        mockRepository.shouldThrowError = true;

        await viewModel.deleteActivity('user-1', 'activity-1', DateTime.now());

        expect(viewModel.hasError, true);
        expect(viewModel.errorMessage, contains('Failed to delete activity'));
      });
    });

    group('error handling', () {
      test('clearError removes error message', () async {
        mockRepository.shouldThrowError = true;

        await viewModel.loadConfig('user-1');
        expect(viewModel.hasError, true);

        viewModel.clearError();

        expect(viewModel.hasError, false);
        expect(viewModel.errorMessage, null);
      });
    });

    group('state management', () {
      test('notifies listeners on state changes', () async {
        int notificationCount = 0;
        viewModel.addListener(() {
          notificationCount++;
        });

        mockRepository.setConfigToReturn(null);

        await viewModel.loadConfig('user-1');

        // Should notify at least twice: loading start and loading end
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });
  });
}
