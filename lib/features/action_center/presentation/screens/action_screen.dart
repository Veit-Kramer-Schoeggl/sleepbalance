import 'package:flutter/material.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../../shared/widgets/ui/date_navigation_header.dart';
import '../../../../shared/widgets/ui/checkbox_button.dart';
import '../../../../shared/widgets/ui/acceptance_button.dart';

/// Action Center screen for actionable sleep recommendations and tasks
class ActionScreen extends StatefulWidget {
  const ActionScreen({super.key});

  @override
  State<ActionScreen> createState() => _ActionScreenState();
}

class _ActionScreenState extends State<ActionScreen> {
  DateTime _currentDate = DateTime.now();
  
  // List of action items with checkbox states
  List<Map<String, dynamic>> _actionItems = [
    {
      'text': 'Drink a glass of water',
      'icon': Icons.local_drink,
      'isChecked': false,
    },
    {
      'text': 'Take 5 deep breaths',
      'icon': Icons.air,
      'isChecked': false,
    },
    {
      'text': 'Stretch for 2 minutes',
      'icon': Icons.accessibility_new,
      'isChecked': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Action Center', style: TextStyle(color: Colors.white)),
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
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  itemCount: _actionItems.length,
                  itemBuilder: (context, index) {
                    final item = _actionItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CheckboxButton(
                        text: item['text'],
                        icon: item['icon'],
                        isChecked: item['isChecked'],
                        onChanged: (value) {
                          setState(() {
                            _actionItems[index]['isChecked'] = value ?? false;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AcceptanceButton(
                text: 'Complete Actions',
                onPressed: () {
                  final completedCount = _actionItems.where((item) => item['isChecked']).length;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$completedCount of ${_actionItems.length} actions completed!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
