import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget sleepTargetSlider(
    int? targetMinutes,
    Function(double) onChanged,
    { Color textColor = Colors.white }) {
  return  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ziel-Schlafdauer',
        style: TextStyle(color: textColor),
      ),
      const SizedBox(height: 8),
      Text(
        '${targetMinutes ?? 360} Minuten '
            '(${((targetMinutes ?? 360) / 60).toStringAsFixed(1)} h)',
        style: TextStyle(color: textColor),
      ),
      Slider(
      value: (targetMinutes ?? 360).toDouble(),
      min: 360,
      max: 600,
      divisions: 24,
      label: '${targetMinutes ?? 360} min',
      onChanged: onChanged
      )
    ],
  );
}