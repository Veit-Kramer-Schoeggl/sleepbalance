import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sleepbalance/main.dart';

void main() {
  testWidgets('SleepBalance app loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SleepBalanceApp());

    expect(find.text('SleepBalance Dashboard'), findsOneWidget);
    expect(find.text('SleepBalance'), findsOneWidget);
  });
}
