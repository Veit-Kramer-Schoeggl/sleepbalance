import 'package:flutter_test/flutter_test.dart';

import 'package:sleepbalance/main.dart';

void main() {
  testWidgets('SleepBalance app loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SleepBalanceApp());

    // Wait for splash screen timer and navigation
    await tester.pumpAndSettle();

    // App should start up without errors
    expect(find.byType(SleepBalanceApp), findsOneWidget);
  });
}
