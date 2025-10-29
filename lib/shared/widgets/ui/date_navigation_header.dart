import 'package:flutter/material.dart';
import 'package:sleepbalance/core/utils/date_formatter.dart';

/// A reusable header widget with left/right arrows for date navigation
/// Displays current date and weekday in localized format
class DateNavigationHeader extends StatelessWidget {
  final DateTime currentDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback? onDateTap;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const DateNavigationHeader({
    super.key,
    required this.currentDate,
    required this.onPreviousDay,
    required this.onNextDay,
    this.onDateTap,
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
            color: Colors.white,
            tooltip: 'Previous day',
          ),
          
          // Date display in center
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: onDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: onDateTap != null ? BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.1),
                  ) : null,
                  child: Text(
                    DateFormatter.formatForHeader(currentDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          
          // Right arrow button
          IconButton(
            onPressed: onNextDay,
            icon: const Icon(Icons.arrow_forward_ios),
            iconSize: 20,
            color: Colors.white,
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }
}