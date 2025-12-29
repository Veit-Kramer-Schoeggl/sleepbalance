# Integration Tests

Integration tests for SleepBalance app using Flutter's integration_test package.

## Setup

Integration tests run on a real device or emulator and test the complete app flow end-to-end.

### Prerequisites

1. **Device or Emulator Running:**
   ```bash
   # List available devices
   flutter devices

   # Start Android emulator
   flutter emulators --launch <emulator_id>

   # Or connect physical device via USB
   ```

2. **Dependencies Installed:**
   ```bash
   flutter pub get
   ```

## Running Tests

### Run All Integration Tests

```bash
flutter test integration_test/
```

### Run Specific Test File

```bash
flutter drive \
  --driver=integration_test_driver/integration_test.dart \
  --target=integration_test/auth_flow_test.dart
```

### Run on Specific Device

```bash
flutter drive \
  --driver=integration_test_driver/integration_test.dart \
  --target=integration_test/auth_flow_test.dart \
  -d <device_id>
```

## Test Files

### auth_flow_test.dart
Tests complete authentication flow:
- User registration
- Email verification
- Form validation
- Password strength indicator
- Navigation flow

**Test Groups:**
1. Authentication Flow
   - Complete signup and verification flow
   - Signup validation (invalid email)
   - Signup validation (weak password)
   - Password visibility toggle
   - Timezone auto-detection

2. Email Verification Screen
   - Code input validation
   - Countdown timer
   - Resend code functionality

## Writing Integration Tests

### Basic Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sleepbalance/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('My test', (WidgetTester tester) async {
    // Start the app
    await app.main();
    await tester.pumpAndSettle();

    // Interact with UI
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // Verify results
    expect(find.text('Success'), findsOneWidget);
  });
}
```

### Common Patterns

**Finding Widgets:**
```dart
// By text
find.text('Sign Up')

// By type
find.byType(ElevatedButton)

// By widget with text
find.widgetWithText(TextFormField, 'Email')

// By icon
find.byIcon(Icons.visibility)

// Descendant widgets
find.descendant(
  of: find.byType(Form),
  matching: find.byType(TextFormField),
)
```

**Interacting with Widgets:**
```dart
// Enter text
await tester.enterText(find.byType(TextField), 'value');

// Tap button
await tester.tap(find.text('Submit'));

// Scroll
await tester.drag(find.byType(ListView), Offset(0, -200));

// Wait for animations
await tester.pumpAndSettle();

// Wait with timeout
await tester.pumpAndSettle(Duration(seconds: 2));
```

**Assertions:**
```dart
// Widget exists
expect(find.text('Hello'), findsOneWidget);

// Widget does not exist
expect(find.text('Error'), findsNothing);

// Multiple widgets
expect(find.byType(TextField), findsNWidgets(3));

// Widget property
expect(tester.widget<TextField>(find.byType(TextField)).enabled, true);
```

## Test Database

Integration tests use the same database as the app. To reset between tests:

```dart
setUp(() async {
  // Clear database before each test
  final db = await DatabaseHelper.instance.database;
  await db.delete('users');
  await db.delete('email_verification_tokens');
});
```

## Debugging Integration Tests

### Enable Verbose Logging

```bash
flutter drive \
  --driver=integration_test_driver/integration_test.dart \
  --target=integration_test/auth_flow_test.dart \
  --verbose
```

### Take Screenshots

```dart
testWidgets('My test', (WidgetTester tester) async {
  await app.main();
  await tester.pumpAndSettle();

  // Take screenshot
  await binding.convertFlutterSurfaceToImage();
  await binding.takeScreenshot('screenshot_name');
});
```

### Print Widget Tree

```dart
testWidgets('Debug test', (WidgetTester tester) async {
  await app.main();
  await tester.pumpAndSettle();

  // Print widget tree
  debugDumpApp();
});
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter drive \
          --driver=integration_test_driver/integration_test.dart \
          --target=integration_test/auth_flow_test.dart \
          -d iPhone
```

## Known Limitations

1. **Test Mode Required:** Some tests rely on test mode features (e.g., verification code display)
2. **Database State:** Tests may interfere with each other if database not properly reset
3. **Timing Issues:** UI animations may cause flaky tests - use `pumpAndSettle()` generously
4. **Platform Differences:** Some tests may behave differently on iOS vs Android

## Best Practices

1. **Use `pumpAndSettle()`:** Always wait for animations to complete
2. **Check Mounted State:** Verify widgets are mounted before interacting
3. **Cleanup:** Reset database state between tests
4. **Descriptive Names:** Use clear test names that describe what's being tested
5. **Test Independence:** Each test should be able to run independently
6. **Avoid Hardcoded Delays:** Use `pumpAndSettle()` instead of `Future.delayed()`

## Troubleshooting

### Test Hangs
- Ensure all async operations complete
- Check for infinite animations
- Use timeouts: `pumpAndSettle(Duration(seconds: 10))`

### Widget Not Found
- Verify widget is on screen (may need to scroll)
- Check if widget is in current route
- Use `debugDumpApp()` to inspect widget tree

### Platform-Specific Issues
- Test on both iOS and Android
- Check platform-specific widgets (Cupertino vs Material)
- Verify platform permissions are granted

## Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Integration Test Package](https://pub.dev/packages/integration_test)
- [WidgetTester API](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)
