import 'sleep_baseline.dart';
import 'sleep_record.dart';

/// Sleep Comparison domain model
///
/// DTO (Data Transfer Object) for displaying "today vs average" comparisons.
/// Simplifies UI logic by pre-computing differences from baseline.
///
/// Usage example:
/// ```dart
/// final comparison = SleepComparison.calculate(todayRecord, baselinesList);
/// if (comparison.isAboveAverage('deep_sleep')) {
///   print('Deep sleep: ${comparison.getDifferenceText('deep_sleep')}');
/// }
/// ```
class SleepComparison {
  final SleepRecord todayRecord;
  final Map<String, double> baselines;
  final Map<String, double> differences;

  const SleepComparison({
    required this.todayRecord,
    required this.baselines,
    required this.differences,
  });

  /// Factory constructor that calculates comparisons
  ///
  /// Takes a sleep record and list of baselines, computes the differences
  /// between today's metrics and baseline averages.
  ///
  /// Parameters:
  /// - [record]: Tonight's sleep data
  /// - [baselinesList]: List of baseline metrics to compare against
  ///
  /// Returns a SleepComparison with pre-computed differences
  factory SleepComparison.calculate(
    SleepRecord record,
    List<SleepBaseline> baselinesList,
  ) {
    final baselines = <String, double>{};
    final differences = <String, double>{};

    for (final baseline in baselinesList) {
      baselines[baseline.metricName] = baseline.metricValue;

      // Calculate difference based on metric name
      double? actualValue;
      switch (baseline.metricName) {
        case 'avg_deep_sleep':
          actualValue = record.deepSleepDuration?.toDouble();
          break;
        case 'avg_rem_sleep':
          actualValue = record.remSleepDuration?.toDouble();
          break;
        case 'avg_light_sleep':
          actualValue = record.lightSleepDuration?.toDouble();
          break;
        case 'avg_total_sleep':
          actualValue = record.totalSleepTime?.toDouble();
          break;
        case 'avg_awake_duration':
          actualValue = record.awakeDuration?.toDouble();
          break;
        case 'avg_heart_rate':
          actualValue = record.avgHeartRate;
          break;
        case 'avg_hrv':
          actualValue = record.avgHrv;
          break;
        case 'avg_heart_rate_variability':
          actualValue = record.avgHeartRateVariability;
          break;
        case 'avg_breathing_rate':
          actualValue = record.avgBreathingRate;
          break;
        case 'avg_sleep_efficiency':
          actualValue = record.sleepEfficiency?.toDouble();
          break;
      }

      if (actualValue != null) {
        differences[baseline.metricName] = actualValue - baseline.metricValue;
      }
    }

    return SleepComparison(
      todayRecord: record,
      baselines: baselines,
      differences: differences,
    );
  }

  /// Checks if today's value is above the baseline average
  ///
  /// Returns true if difference is positive, false otherwise
  /// Returns false if metric is not available
  bool isAboveAverage(String metricName) {
    final diff = differences[metricName];
    return diff != null && diff > 0;
  }

  /// Gets formatted difference text for display
  ///
  /// Examples:
  /// - "+10 min" (above average)
  /// - "-5 min" (below average)
  /// - "+2.5 bpm" (heart rate)
  ///
  /// Returns empty string if metric is not available
  String getDifferenceText(String metricName, {String unit = 'min'}) {
    final diff = differences[metricName];
    if (diff == null) return '';

    final sign = diff >= 0 ? '+' : '';
    final value = diff.abs().toStringAsFixed(
          diff.abs() >= 10 ? 0 : 1,
        ); // Show decimal for small values

    return '$sign$value $unit';
  }

  /// Gets the baseline value for a specific metric
  ///
  /// Returns null if baseline doesn't exist
  double? getBaselineValue(String metricName) {
    return baselines[metricName];
  }

  /// Gets the actual value for a specific metric from today's record
  ///
  /// Returns null if value doesn't exist
  double? getActualValue(String metricName) {
    switch (metricName) {
      case 'avg_deep_sleep':
        return todayRecord.deepSleepDuration?.toDouble();
      case 'avg_rem_sleep':
        return todayRecord.remSleepDuration?.toDouble();
      case 'avg_light_sleep':
        return todayRecord.lightSleepDuration?.toDouble();
      case 'avg_total_sleep':
        return todayRecord.totalSleepTime?.toDouble();
      case 'avg_awake_duration':
        return todayRecord.awakeDuration?.toDouble();
      case 'avg_heart_rate':
        return todayRecord.avgHeartRate;
      case 'avg_hrv':
        return todayRecord.avgHrv;
      case 'avg_heart_rate_variability':
        return todayRecord.avgHeartRateVariability;
      case 'avg_breathing_rate':
        return todayRecord.avgBreathingRate;
      case 'avg_sleep_efficiency':
        return todayRecord.sleepEfficiency?.toDouble();
      default:
        return null;
    }
  }

  /// Gets percentage difference from baseline
  ///
  /// Example: If baseline is 80 and actual is 88, returns +10.0 (%)
  /// Returns null if baseline is zero or metric unavailable
  double? getPercentageDifference(String metricName) {
    final baseline = baselines[metricName];
    final diff = differences[metricName];

    if (baseline == null || diff == null || baseline == 0) {
      return null;
    }

    return (diff / baseline) * 100;
  }
}