import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Verification Code Input Widget
///
/// A specialized TextFormField for entering 6-digit verification codes.
///
/// Features:
/// - Number-only keyboard
/// - 6-digit max length
/// - Large centered text with letter spacing
/// - Auto-triggers onCompleted when 6 digits entered
/// - Validation for 6-digit format
///
/// Used in EmailVerificationScreen.
///
/// Example:
/// ```dart
/// VerificationCodeInput(
///   controller: _codeController,
///   onCompleted: (code) {
///     // Auto-trigger verification
///   },
/// )
/// ```
class VerificationCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onCompleted;
  final String? Function(String?)? validator;

  const VerificationCodeInput({
    super.key,
    required this.controller,
    this.onCompleted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Verification Code',
        labelStyle: TextStyle(color: Colors.white),
        hintText: '000000',
        hintStyle: TextStyle(color: Colors.white54),
        border: OutlineInputBorder(),
        counterText: '',
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 8,
      ),
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      maxLength: 6,
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter verification code';
            }
            if (value.length != 6) {
              return 'Code must be 6 digits';
            }
            return null;
          },
      onChanged: (value) {
        if (value.length == 6 && onCompleted != null) {
          onCompleted!(value);
        }
      },
    );
  }
}
