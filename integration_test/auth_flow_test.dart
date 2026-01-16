import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sleepbalance/main.dart' as app;

/// Integration test for complete authentication flow
///
/// Tests the full user journey:
/// DATA PRIVACY
/// 1. App opens to SignupScreen (no user exists)
/// 2. User fills signup form
/// 3. User submits registration
/// 4. App navigates to EmailVerificationScreen
/// 5. User enters verification code
/// 6. User verifies email
/// 7. App navigates to MainNavigation
///
/// Prerequisites:
/// - Database should be empty (no users)
/// - Test environment configured
/// Helper: Accepts the Privacy dialog if it appears.
/// This MUST happen BEFORE any login/signup interactions.

Future<void> acceptPrivacyIfShown(WidgetTester tester) async {
  // Give the UI a moment to show any first-run dialog
  await tester.pumpAndSettle();

  // Look for a privacy/consent dialog (tolerant match)
  final privacyHeadline = find.textContaining('Privacy');
  final privacyTitleAlt = find.textContaining('Data Privacy');
  final acceptTextButton = find.text('Accept');

  final dialogIsVisible = privacyHeadline.evaluate().isNotEmpty ||
      privacyTitleAlt.evaluate().isNotEmpty ||
      acceptTextButton.evaluate().isNotEmpty;

  if (!dialogIsVisible) return;

  // If there is a checkbox, tick it first (common consent UX)
  final checkbox = find.byType(Checkbox);
  if (checkbox.evaluate().isNotEmpty) {
    await tester.tap(checkbox.first);
    await tester.pumpAndSettle();
  }

  // Tap "Accept" (works for TextButton/ElevatedButton, etc.)
  if (acceptTextButton.evaluate().isNotEmpty) {
    await tester.tap(acceptTextButton);
    await tester.pumpAndSettle();
    return;
  }

  // Fallback: Accept button might be an ElevatedButton
  final acceptElevated = find.widgetWithText(ElevatedButton, 'Accept');
  if (acceptElevated.evaluate().isNotEmpty) {
    await tester.tap(acceptElevated);
    await tester.pumpAndSettle();
    return;
  }

  // Fallback: Accept button might be a TextButton
  final acceptTextBtn = find.widgetWithText(TextButton, 'Accept');
  if (acceptTextBtn.evaluate().isNotEmpty) {
    await tester.tap(acceptTextBtn);
    await tester.pumpAndSettle();
    return;
  }
}

/// Boots the app in a test-friendly way (DO NOT call app.main() in widget tests).
/// Ensures privacy consent is handled BEFORE any authentication steps.
Future<void> launchAppAndAcceptPrivacy(WidgetTester tester) async {
  // IMPORTANT:
  // Your main.dart should expose a root widget like `SleepBalanceApp`
  // so tests can do pumpWidget instead of calling main().
  await tester.pumpWidget(const app.SleepBalanceApp());
  await tester.pumpAndSettle();

  // Privacy consent must be accepted BEFORE login/signup screen interactions
  await acceptPrivacyIfShown(tester);

  // After accepting privacy, allow navigation/transitions to settle
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('Complete signup and verification flow', (WidgetTester tester) async {
      // Start the app (test-friendly) + accept privacy BEFORE anything else
      await launchAppAndAcceptPrivacy(tester);

      // ========================================================================
      // Step 1: Verify we're on the SignupScreen
      // ========================================================================
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);

      // ========================================================================
      // Step 2: Fill out the signup form
      // ========================================================================

      await tester.enterText(
        find.widgetWithText(TextFormField, 'First Name'),
        'John',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last Name'),
        'Doe',
      );
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'john.doe@example.com');
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'SecurePass123');
      await tester.pumpAndSettle();

      expect(find.text('Strong'), findsOneWidget);

      final datePickerField = find.widgetWithText(InputDecorator, 'Birth Date');
      await tester.tap(datePickerField);
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // ========================================================================
      // Step 3: Submit the signup form
      // ========================================================================

      final signupButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.tap(signupButton);
      await tester.pumpAndSettle();

      // Wait for navigation to EmailVerificationScreen
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ========================================================================
      // Step 4: Verify we're on the EmailVerificationScreen
      // ========================================================================

      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget);

      // Verification code should be displayed in test mode
      expect(find.text('TEST MODE - Verification Code:'), findsOneWidget);

      // ========================================================================
      // Step 5: Verify verification screen UI elements
      // ========================================================================

      expect(find.text('Verify Email'), findsOneWidget);
      expect(find.text('Resend Code'), findsOneWidget);
      expect(find.textContaining('Code expires in:'), findsOneWidget);

      // ========================================================================
      // Step 6: Test Resend Code functionality
      // ========================================================================

      final resendButton = find.text('Resend Code');
      await tester.tap(resendButton);
      await tester.pumpAndSettle();

      expect(find.text('New verification code sent!'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('Signup validation - invalid email', (WidgetTester tester) async {
      await launchAppAndAcceptPrivacy(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'First Name'),
        'John',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last Name'),
        'Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalid-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'SecurePass123',
      );

      await tester.tap(find.widgetWithText(InputDecorator, 'Birth Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email address'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Signup validation - weak password', (WidgetTester tester) async {
      await launchAppAndAcceptPrivacy(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'First Name'),
        'John',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last Name'),
        'Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'john@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'weak',
      );
      await tester.pumpAndSettle();

      expect(find.text('Weak'), findsOneWidget);
      expect(find.textContaining('Password Requirements:'), findsOneWidget);

      await tester.tap(find.widgetWithText(InputDecorator, 'Birth Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Password'), findsWidgets);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      await launchAppAndAcceptPrivacy(tester);

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'TestPassword123');
      await tester.pumpAndSettle();

      final visibilityToggle = find.descendant(
        of: passwordField,
        matching: find.byIcon(Icons.visibility),
      );

      expect(visibilityToggle, findsOneWidget);

      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Timezone auto-detection displays value', (WidgetTester tester) async {
      await launchAppAndAcceptPrivacy(tester);

      final timezoneField = find.widgetWithText(TextFormField, 'Timezone');
      expect(timezoneField, findsOneWidget);

      expect(
        find.descendant(
          of: timezoneField,
          matching: find.byIcon(Icons.lock),
        ),
        findsOneWidget,
      );
    });
  });

  group('Email Verification Screen', () {
    testWidgets('Code input validates 6-digit format', (WidgetTester tester) async {
      // This would require navigation to the verification screen in a dedicated setup.
      // Kept as a placeholder as in your original file.
    });

    testWidgets('Countdown timer displays and updates', (WidgetTester tester) async {
      // Placeholder as in your original file.
    });

    testWidgets('Resend code generates new verification', (WidgetTester tester) async {
      // Placeholder as in your original file.
    });
  });
}