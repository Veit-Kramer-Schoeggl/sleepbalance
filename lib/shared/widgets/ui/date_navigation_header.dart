import 'package:flutter/material.dart';
import 'package:sleepbalance/core/utils/date_formatter.dart';

/// A reusable header widget with left/right arrows for date navigation
/// Displays current date and weekday in localized format
class DateNavigationHeader extends StatelessWidget {
  final DateTime currentDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const DateNavigationHeader({
    super.key,
    required this.currentDate,
    required this.onPreviousDay,
    required this.onNextDay,
    this.height = 60,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left arrow button
          IconButton(
            onPressed: onPreviousDay,
            icon: const Icon(Icons.arrow_back_ios),
            iconSize: 20,
            color: Theme.of(context).colorScheme.onSurface,
            tooltip: 'Previous day',
          ),
          
          // Date display in center
          Expanded(
            child: Center(
              child: Text(
                DateFormatter.formatForHeader(currentDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Right arrow button
          IconButton(
            onPressed: onNextDay,
            icon: const Icon(Icons.arrow_forward_ios),
            iconSize: 20,
            color: Theme.of(context).colorScheme.onSurface,
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }
}