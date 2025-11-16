import 'package:flutter/material.dart';

/// DateTime operations used by all intervention modules.
///
/// Provides utilities for time-based interventions including:
/// - Calculating times relative to sleep schedule
/// - Parsing and formatting TimeOfDay
/// - Time arithmetic with overnight handling
/// - Time categorization
class DateTimeHelpers {
  /// Calculate time relative to wake time.
  ///
  /// Example: 30 minutes after waking
  /// ```dart
  /// final wakeTime = DateTime(2025, 1, 1, 7, 0);
  /// final lightTherapyTime = DateTimeHelpers.calculateTimeRelativeToWake(
  ///   Duration(minutes: 30),
  ///   wakeTime,
  /// ); // Returns: DateTime(2025, 1, 1, 7, 30)
  /// ```
  static DateTime calculateTimeRelativeToWake(
      Duration offset, DateTime wakeTime) {
    return wakeTime.add(offset);
  }

  /// Calculate time relative to bed time.
  ///
  /// Example: 2 hours before bed
  /// ```dart
  /// final bedTime = DateTime(2025, 1, 1, 22, 0);
  /// final meditationTime = DateTimeHelpers.calculateTimeRelativeToBed(
  ///   Duration(hours: 2),
  ///   bedTime,
  /// ); // Returns: DateTime(2025, 1, 1, 20, 0)
  /// ```
  static DateTime calculateTimeRelativeToBed(
      Duration offset, DateTime bedTime) {
    return bedTime.subtract(offset);
  }

  /// Format relative time description.
  ///
  /// Returns human-readable time difference.
  ///
  /// Examples:
  /// - "30 min after"
  /// - "2 hours before"
  /// - "1 hour 15 min after"
  static String formatRelativeTime(
    DateTime time,
    DateTime referenceTime, {
    bool isBeforeReference = false,
  }) {
    final difference = isBeforeReference
        ? referenceTime.difference(time)
        : time.difference(referenceTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ${isBeforeReference ? "before" : "after"}';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (minutes == 0) {
        return '$hours hour${hours != 1 ? "s" : ""} ${isBeforeReference ? "before" : "after"}';
      }
      return '$hours hour${hours != 1 ? "s" : ""} $minutes min ${isBeforeReference ? "before" : "after"}';
    }
  }

  /// Parse TimeOfDay from HH:mm string.
  ///
  /// Example:
  /// ```dart
  /// final time = DateTimeHelpers.parseTimeOfDay('07:30');
  /// // Returns: TimeOfDay(hour: 7, minute: 30)
  /// ```
  static TimeOfDay parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  /// Convert TimeOfDay to DateTime on a specific date.
  ///
  /// Example:
  /// ```dart
  /// final time = TimeOfDay(hour: 7, minute: 30);
  /// final date = DateTime(2025, 1, 1);
  /// final dateTime = DateTimeHelpers.timeOfDayToDateTime(time, date);
  /// // Returns: DateTime(2025, 1, 1, 7, 30)
  /// ```
  static DateTime timeOfDayToDateTime(TimeOfDay time, DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  /// Format TimeOfDay to HH:mm string.
  ///
  /// Example:
  /// ```dart
  /// final time = TimeOfDay(hour: 7, minute: 30);
  /// final formatted = DateTimeHelpers.formatTimeOfDay(time);
  /// // Returns: '07:30'
  /// ```
  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Calculate hours between two TimeOfDay.
  ///
  /// Handles overnight transitions correctly.
  ///
  /// Examples:
  /// ```dart
  /// // Normal range
  /// calculateHoursBetween(
  ///   TimeOfDay(hour: 9, minute: 0),
  ///   TimeOfDay(hour: 17, minute: 0),
  /// ); // Returns: 8.0
  ///
  /// // Overnight range
  /// calculateHoursBetween(
  ///   TimeOfDay(hour: 22, minute: 0),
  ///   TimeOfDay(hour: 6, minute: 0),
  /// ); // Returns: 8.0
  /// ```
  static double calculateHoursBetween(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    var diff = endMinutes - startMinutes;
    if (diff < 0) diff += 24 * 60; // Handle overnight

    return diff / 60.0;
  }

  /// Add hours to TimeOfDay.
  ///
  /// Returns normalized time (handles day overflow).
  ///
  /// Examples:
  /// ```dart
  /// // Normal addition
  /// addHours(TimeOfDay(hour: 10, minute: 0), 2.0);
  /// // Returns: TimeOfDay(hour: 12, minute: 0)
  ///
  /// // Day overflow
  /// addHours(TimeOfDay(hour: 23, minute: 0), 2.0);
  /// // Returns: TimeOfDay(hour: 1, minute: 0)
  ///
  /// // Fractional hours
  /// addHours(TimeOfDay(hour: 10, minute: 0), 1.5);
  /// // Returns: TimeOfDay(hour: 11, minute: 30)
  /// ```
  static TimeOfDay addHours(TimeOfDay time, double hours) {
    final totalMinutes = time.hour * 60 + time.minute + (hours * 60).toInt();
    final normalizedMinutes = totalMinutes % (24 * 60);

    return TimeOfDay(
      hour: normalizedMinutes ~/ 60,
      minute: normalizedMinutes % 60,
    );
  }

  /// Subtract hours from TimeOfDay.
  ///
  /// Examples:
  /// ```dart
  /// // Normal subtraction
  /// subtractHours(TimeOfDay(hour: 14, minute: 0), 2.0);
  /// // Returns: TimeOfDay(hour: 12, minute: 0)
  ///
  /// // Day underflow
  /// subtractHours(TimeOfDay(hour: 1, minute: 0), 2.0);
  /// // Returns: TimeOfDay(hour: 23, minute: 0)
  /// ```
  static TimeOfDay subtractHours(TimeOfDay time, double hours) {
    return addHours(time, -hours);
  }

  /// Get midpoint between two TimeOfDay.
  ///
  /// Handles overnight ranges correctly.
  ///
  /// Examples:
  /// ```dart
  /// // Normal range
  /// midpoint(
  ///   TimeOfDay(hour: 6, minute: 0),
  ///   TimeOfDay(hour: 18, minute: 0),
  /// ); // Returns: TimeOfDay(hour: 12, minute: 0)
  ///
  /// // Overnight range
  /// midpoint(
  ///   TimeOfDay(hour: 22, minute: 0),
  ///   TimeOfDay(hour: 6, minute: 0),
  /// ); // Returns: TimeOfDay(hour: 2, minute: 0)
  /// ```
  static TimeOfDay midpoint(TimeOfDay start, TimeOfDay end) {
    final hoursBetween = calculateHoursBetween(start, end);
    return addHours(start, hoursBetween / 2);
  }

  /// Determine time of day category.
  ///
  /// Categories:
  /// - 'morning': 5:00 - 11:59
  /// - 'afternoon': 12:00 - 16:59
  /// - 'evening': 17:00 - 20:59
  /// - 'night': 21:00 - 4:59
  ///
  /// Examples:
  /// ```dart
  /// getTimeOfDayCategory(TimeOfDay(hour: 7, minute: 30));  // 'morning'
  /// getTimeOfDayCategory(TimeOfDay(hour: 14, minute: 0));  // 'afternoon'
  /// getTimeOfDayCategory(TimeOfDay(hour: 19, minute: 0));  // 'evening'
  /// getTimeOfDayCategory(TimeOfDay(hour: 23, minute: 0));  // 'night'
  /// ```
  static String getTimeOfDayCategory(TimeOfDay time) {
    if (time.hour >= 5 && time.hour < 12) return 'morning';
    if (time.hour >= 12 && time.hour < 17) return 'afternoon';
    if (time.hour >= 17 && time.hour < 21) return 'evening';
    return 'night';
  }
}
