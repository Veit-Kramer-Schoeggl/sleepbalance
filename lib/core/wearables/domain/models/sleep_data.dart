class SleepData {
  final DateTime timestamp;
  
  // Sleep phases (in minutes)
  final int lightSleepMinutes;
  final int deepSleepMinutes;
  final int remSleepMinutes;
  
  // Heart rate metrics (BPM)
  final int averageHeartRate;
  final int lowestHeartRate;
  final int highestHeartRate;
  final int heartRateVariability; // ms
  
  // Breathing rate (breaths per minute)
  final int breathingRate;
  
  // Sleep fragmentation
  final int fragmentationScore; // 0-100
  final int timesAwake;
  final int numberOfWakeUps;

  const SleepData({
    required this.timestamp,
    required this.lightSleepMinutes,
    required this.deepSleepMinutes,
    required this.remSleepMinutes,
    required this.averageHeartRate,
    required this.lowestHeartRate,
    required this.highestHeartRate,
    required this.heartRateVariability,
    required this.breathingRate,
    required this.fragmentationScore,
    required this.timesAwake,
    required this.numberOfWakeUps,
  });

  // Helper getters
  int get totalSleepMinutes => lightSleepMinutes + deepSleepMinutes + remSleepMinutes;
  
  String get totalSleepFormatted {
    final hours = totalSleepMinutes ~/ 60;
    final minutes = totalSleepMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  // Convert from JSON (for API responses)
  factory SleepData.fromJson(Map<String, dynamic> json) {
    return SleepData(
      timestamp: DateTime.parse(json['timestamp']),
      lightSleepMinutes: json['lightSleepMinutes'],
      deepSleepMinutes: json['deepSleepMinutes'],
      remSleepMinutes: json['remSleepMinutes'],
      averageHeartRate: json['averageHeartRate'],
      lowestHeartRate: json['lowestHeartRate'],
      highestHeartRate: json['highestHeartRate'],
      heartRateVariability: json['heartRateVariability'],
      breathingRate: json['breathingRate'],
      fragmentationScore: json['fragmentationScore'],
      timesAwake: json['timesAwake'],
      numberOfWakeUps: json['numberOfWakeUps'],
    );
  }

  // Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'lightSleepMinutes': lightSleepMinutes,
      'deepSleepMinutes': deepSleepMinutes,
      'remSleepMinutes': remSleepMinutes,
      'averageHeartRate': averageHeartRate,
      'lowestHeartRate': lowestHeartRate,
      'highestHeartRate': highestHeartRate,
      'heartRateVariability': heartRateVariability,
      'breathingRate': breathingRate,
      'fragmentationScore': fragmentationScore,
      'timesAwake': timesAwake,
      'numberOfWakeUps': numberOfWakeUps,
    };
  }
}