import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget sleepTargetSlider(
    String? start,
    String? end,
    int? targetMinutes,
    Function(String newStart, String newEnd, int newDuration) onChanged,
    {Color textColor = Colors.white}) {

  double parseToSliderValue(String? time) {
    if (time == null) return 720;
    final parts = time.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    int totalMins = h * 60 + m;

    if (totalMins < 720) totalMins += 1440;
    return (totalMins - 720).toDouble();
  }

  String formatFromSliderValue(double value) {
    int minutesFromNoon = value.round();
    int actualMinutes = minutesFromNoon + 720;
    if (actualMinutes >= 1440) actualMinutes -= 1440;

    final h = (actualMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (actualMinutes % 60).toString().padLeft(2, '0');
    return "$h:$m";
  }

  double startVal = start != null ? parseToSliderValue(start) : 600;
  double endVal = end != null ? parseToSliderValue(end) : 1080;

  if (startVal > endVal) endVal = startVal;

  var values = RangeValues(startVal, endVal);
  var labels = RangeLabels(
      formatFromSliderValue(startVal),
      formatFromSliderValue(endVal)
  );

  var label = "${((targetMinutes ?? 480) / 60).floor()}:${(targetMinutes ?? 480) % 60} h";

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ziel-Schlafdauer',
        style: TextStyle(color: textColor),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: TextStyle(color: textColor),
      ),
      RangeSlider(
        values: values,
        min: 0,
        max: 1440, // Represents 24 hours (Noon to Noon)
        divisions: 144, // 10-minute steps
        labels: labels,
        onChanged: (RangeValues newValues) {
          final newStartStr = formatFromSliderValue(newValues.start);
          final newEndStr = formatFromSliderValue(newValues.end);

          int duration = (newValues.end - newValues.start).round();

          onChanged(newStartStr, newEndStr, duration);
        },
      )
    ],
  );
}