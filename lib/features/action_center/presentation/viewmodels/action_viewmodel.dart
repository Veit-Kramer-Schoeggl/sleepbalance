import 'package:flutter/foundation.dart';

import 'package:sleepbalance/modules/shared/constants/module_metadata.dart';
import 'package:sleepbalance/modules/shared/domain/repositories/module_config_repository.dart';

import '../../../../core/utils/uuid_generator.dart';
import '../../domain/models/daily_action.dart';
import '../../domain/repositories/action_repository.dart';


/// ViewModel for Action Center screen
///
/// Manages state and business logic for daily actions feature.
/// Extends ChangeNotifier to enable reactive UI updates via Provider.
///
/// Responsibilities:
/// - Load actions from repository
/// - Handle user interactions (toggle, add)
/// - Manage loading and error states
/// - Notify UI of state changes
class ActionViewModel extends ChangeNotifier {
  /// Repository for daily actions.
  final ActionRepository _repository;
  /// Repository for module configurations.
  final ModuleConfigRepository _moduleConfigRepository;
  /// The current user ID.
  final String userId;

  /// Returns a [DateTime] with only the year, month, and day.
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Generates a string key for a date in the format YYYYMMDD.
  String _dateKey(DateTime d) {
    final dd = _dateOnly(d);
    final y = dd.year.toString().padLeft(4, '0');
    final m = dd.month.toString().padLeft(2, '0');
    final day = dd.day.toString().padLeft(2, '0');
    return '$y$m$day';
  }

  /// Creates an [ActionViewModel] with the required repositories and user ID.
  ActionViewModel({
    required ActionRepository repository,
    required ModuleConfigRepository moduleConfigRepository,
    required this.userId,
  }) : _repository = repository,
        _moduleConfigRepository = moduleConfigRepository;

  /// List of daily actions for the current date.
  List<DailyAction> _actions = [];
  /// Whether the data is currently being loaded.
  bool _isLoading = false;
  /// Error message if loading or performing an operation failed.
  String? _errorMessage;
  /// The currently selected date in the Action Center.
  DateTime _currentDate = DateTime.now();

  /// Returns the list of actions for the current date.
  List<DailyAction> get actions => _actions;
  /// Returns whether data is currently loading.
  bool get isLoading => _isLoading;
  /// Returns the current error message, if any.
  String? get errorMessage => _errorMessage;
  /// Returns the currently selected date.
  DateTime get currentDate => _currentDate;
  /// Returns the number of completed actions.
  int get completedCount => _actions.where((a) => a.isCompleted).length;

  /// Loads actions for the current date
  ///
  /// Sets loading state, fetches from repository, handles errors.
  /// Always calls notifyListeners() to update UI.
  Future<void> loadActions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _repository.getActionsForDate(userId, _currentDate);

      // Get currently active module IDs for this user.
      final activeModuleIds = await _moduleConfigRepository.getActiveModuleIds(userId);
      final activeSet = activeModuleIds.toSet();

      final date = _dateOnly(_currentDate);

      // Ensure there is one module action per active module for this date
      for (final moduleId in activeSet) {
        final exists = loaded.any(
                (a) => a.iconName == moduleId && _dateOnly(a.actionDate) == date);

        if (!exists) {
          final meta = getModuleMetadata(moduleId);

          // Deterministic id prevents duplicates across reloads
          final action = DailyAction(
            id: '${userId}_${moduleId}_${_dateKey(date)}',
            userId: userId,
            title: meta.displayName,
            iconName: moduleId,
            isCompleted: false,
            actionDate: date,
            createdAt: DateTime.now(),
          );

          await _repository.saveAction(action);
          loaded.add(action);
        }
      }

      // Show:
      // - non-module actions always
      // - module actions only if the module is currently active
      _actions = loaded.where((a) {
        final meta = getModuleMetadata(a.iconName);
        final isModuleAction = meta.id != 'unknown';

        if (!isModuleAction) return true;
        return activeSet.contains(a.iconName);
      }).toList();

    } catch (e) {
      _errorMessage = 'Failed to load actions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles completion status of an action
  ///
  /// Updates database, then reloads all actions to reflect changes.
  /// Reloading ensures UI stays in sync with database state.
  Future<void> toggleAction(String actionId) async {
    try {
      await _repository.toggleActionCompletion(actionId);
      await loadActions(); // Reload to get updated state
    } catch (e) {
      _errorMessage = 'Failed to toggle action: $e';
      notifyListeners();
    }
  }

  /// Changes the selected date
  ///
  /// Updates currentDate and loads actions for the new date.
  /// Used by date navigation (previous/next day buttons).
  Future<void> changeDate(DateTime newDate) async {
    _currentDate = newDate;
    await loadActions();
  }

  /// Adds default sample actions for testing
  ///
  /// Creates 3 predefined actions for the current date:
  /// - Drink water
  /// - Deep breaths
  /// - Stretching
  ///
  /// Useful for first-time users and testing.
  Future<void> addDefaultActions() async {
    final defaultActions = [
      DailyAction(
        id: UuidGenerator.generate(),
        userId: userId,
        title: 'Drink a glass of water',
        iconName: 'local_drink',
        isCompleted: false,
        actionDate: _currentDate,
        createdAt: DateTime.now(),
      ),
      DailyAction(
        id: UuidGenerator.generate(),
        userId: userId,
        title: 'Take 5 deep breaths',
        iconName: 'air',
        isCompleted: false,
        actionDate: _currentDate,
        createdAt: DateTime.now(),
      ),
      DailyAction(
        id: UuidGenerator.generate(),
        userId: userId,
        title: 'Stretch for 2 minutes',
        iconName: 'accessibility_new',
        isCompleted: false,
        actionDate: _currentDate,
        createdAt: DateTime.now(),
      ),
    ];

    for (final action in defaultActions) {
      await _repository.saveAction(action);
    }

    await loadActions();
  }
}
