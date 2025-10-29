import 'package:flutter/material.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../../shared/widgets/ui/date_navigation_header.dart';
import '../../../../shared/widgets/ui/expandable_calendar.dart';

/// Night Review screen for reviewing previous night's sleep data
class NightScreen extends StatefulWidget {
  const NightScreen({super.key});

  @override
  State<NightScreen> createState() => _NightScreenState();
}

class _NightScreenState extends State<NightScreen> {
  DateTime _currentDate = DateTime.now();
  bool _isCalendarExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Night Review', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            DateNavigationHeader(
              currentDate: _currentDate,
              onPreviousDay: () {
                setState(() {
                  _currentDate = _currentDate.subtract(const Duration(days: 1));
                });
              },
              onNextDay: () {
                setState(() {
                  _currentDate = _currentDate.add(const Duration(days: 1));
                });
              },
              onDateTap: () {
                setState(() {
                  _isCalendarExpanded = !_isCalendarExpanded;
                });
              },
            ),
            ExpandableCalendar(
              selectedDate: _currentDate,
              isExpanded: _isCalendarExpanded,
              onDateSelected: (date) {
                setState(() {
                  _currentDate = date;
                });
              },
              onToggleExpansion: () {
                setState(() {
                  _isCalendarExpanded = !_isCalendarExpanded;
                });
              },
            ),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bedtime,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Night Review',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Review your previous night\'s sleep',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
