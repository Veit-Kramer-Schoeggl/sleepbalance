import 'package:flutter/foundation.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../domain/models/daily_action.dart';
import '../../domain/repositories/action_repository.dart';

import 'package:sleepbalance/modules/shared/domain/repositories/module_config_repository.dart';
import 'package:sleepbalance/modules/shared/constants/module_metadata.dart';

/// ViewModel for Action Center screen
///
/// Manages state and business logic for daily actions feature.
/// Extends ChangeNotifier to enable reactive UI updates via Provider.
///
/// Responsibilities:
/// - Load actions from repository
/// - Handle user interactions (toggle, add, delete)
/// - Manage loading and error states
/// - Notify UI of state changes
class ActionViewModel extends ChangeNotifier {
  final ActionRepository _repository;
  final ModuleConfigRepository _moduleConfigRepository;
  final String userId;

  ActionViewModel({
    required ActionRepository repository,
    required ModuleConfigRepository moduleConfigRepository,
    required this.userId,
  }) : _repository = repository,
        _moduleConfigRepository = moduleConfigRepository;

  // State
  List<DailyAction> _actions = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _currentDate = DateTime.now();

  // Getters - expose state to UI
  List<DailyAction> get actions => _actions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get currentDate => _currentDate;
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

// Get currently active module ids for this user
      final activeModuleIds = await _moduleConfigRepository.getActiveModuleIds(userId);
      final activeSet = activeModuleIds.toSet();

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
