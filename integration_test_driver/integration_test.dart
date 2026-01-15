import 'package:integration_test/integration_test_driver.dart';

/// Integration test driver
///
/// Runs integration tests on a real device or emulator.
///
/// Usage:
/// ```bash
/// flutter drive \
///   --driver=integration_test_driver/integration_test.dart \
///   --target=integration_test/auth_flow_test.dart
/// ```
Future<void> main() => integrationDriver();
