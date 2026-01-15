import 'package:flutter/material.dart';

import '../../domain/validators/password_validator.dart';

/// Password Strength Indicator Widget
///
/// Displays a visual indicator of password strength with:
/// - Colored progress bar (red/orange/green)
/// - Text label (Weak/Medium/Strong)
///
/// Used in SignupScreen for real-time password feedback.
///
/// Example:
/// ```dart
/// PasswordStrengthIndicator(
///   strength: PasswordStrength.strong,
/// )
/// ```
class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _getProgressValue(),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getLabel(),
              style: TextStyle(
                color: _getColor(),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Gets progress value based on strength (0.0 to 1.0)
  double _getProgressValue() {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  /// Gets color based on strength
  Color _getColor() {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  /// Gets text label based on strength
  String _getLabel() {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}
