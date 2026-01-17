import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sleepbalance/features/night_review/domain/models/sleep_record.dart';
import 'package:sleepbalance/features/night_review/domain/models/sleep_record_sleep_phase.dart';
import 'package:sleepbalance/features/night_review/domain/repositories/sleep_record_repository.dart';
import 'package:sleepbalance/features/settings/domain/repositories/user_repository.dart';

/// ViewModel for the Night Review screen.
///
/// Manages the state for displaying sleep records, ratings, and user targets.
/// Fetches data from repositories and provides it to the UI.
class NightReviewViewmodel extends ChangeNotifier {
  final SleepRecordRepository _repository;
  final UserRepository _userRepository;

  /// Creates a new instance of [NightReviewViewmodel].
  NightReviewViewmodel({
    required SleepRecordRepository repository,
    required UserRepository userRepository
  }) : _repository = repository, _userRepository = userRepository;

  // --- State ---
  /// The currently selected date in the UI.
  DateTime? _currentDate;
  /// The sleep record for the [_currentDate].
  SleepRecord? _currentRecord;
  /// Whether the ViewModel is currently fetching data.
  bool _isLoading = false;
  /// An error message if a fetch fails.
  String? _errorMessage;

  /// The user's target sleep duration in minutes.
  int? sleepTarget;
  /// The user's target bedtime.
  DateTime? bedTime;
  /// The user's target wake-up time.
  DateTime? wakeTime;
  /// A map of ratings for the week leading up to the current date.
  Map<DateTime, String?>? previousRatings;
  /// A list of sleep phases for the current sleep record.
  List<SleepRecordSleepPhase>? currentRecordSleepPhases;

  // --- Getters ---
  /// Exposes the current sleep record to the UI.
  SleepRecord? get currentRecord => _currentRecord;
  /// Exposes the loading state to the UI.
  bool get isLoading => _isLoading;
  /// Exposes the error message to the UI.
  String? get errorMessage => _errorMessage;


  /// Clears any error message.
  ///
  /// Useful for dismissing error banners in UI.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sets the current date and fetches the corresponding sleep record.
  Future<void> setDateAndFetchRecord(DateTime newDate) async {
    _currentDate = newDate;
    await getRecord();
  }

  /// Fetches the sleep record for the currently selected date.
  ///
  /// Also loads user targets, previous ratings, and detailed sleep phases.
  Future<void> getRecord() async {
    if (_currentDate == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await setTargets();
      final userId = await _userRepository.getCurrentUserId();
      if (userId == null) throw Exception("User not found");

      _currentRecord = await _repository.getRecordForDate(userId, _currentDate!);
      await _loadPreviousRatings();

      if (_currentRecord != null) {
        await _loadSleepPhasesForRecord(_currentRecord!.id);
      } else {
        currentRecordSleepPhases = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _currentRecord = null;
      currentRecordSleepPhases = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the quality rating for the current sleep record.
  Future<void> updateRating(String rating) async {
    if (_currentRecord == null) {
      throw Exception("Cannot rate non existent sleep record!");
    }

    await _repository.updateQualityRating(_currentRecord!.id, rating, null);
    await getRecord();
  }

  /// Loads the quality ratings for the week prior to the current date.
  Future<void> _loadPreviousRatings() async {
    if (_currentDate == null) {
      throw Exception("Current Date must not be null!");
    }

    final userId = await _userRepository.getCurrentUserId();
    if (userId == null) return;

    previousRatings = await _repository.getPreviousQualityRatings(userId, _currentDate!);
  }

  /// Loads the detailed sleep phases for the given sleep record ID.
  Future<void> _loadSleepPhasesForRecord(String recordId) async {
    final sleepPhases = await _repository.getSleepPhasesForRecord(recordId);
    currentRecordSleepPhases = sleepPhases;
  }

  /// Fetches and sets the user's sleep-related targets (duration, bedtime, etc.).
  Future<void> setTargets() async {
    final userId = await _userRepository.getCurrentUserId();

    if (userId == null) {
      return;
    }

    final user =  await _userRepository.getUserById(userId);

    final bedTimeString =  user?.targetBedTime;
    final wakeTimeString = user?.targetWakeTime;

    sleepTarget = user?.targetSleepDuration;
    bedTime = bedTimeString != null ? DateTime.tryParse(bedTimeString) : null;
    wakeTime = wakeTimeString != null ? DateTime.tryParse(wakeTimeString) : null;
  }
}
