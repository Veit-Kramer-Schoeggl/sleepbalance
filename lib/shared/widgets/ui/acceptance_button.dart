import 'package:flutter/material.dart';

/// A standard acceptance button with floating effect
/// Used for confirming actions, submissions, etc.
class AcceptanceButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  const AcceptanceButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: enabled
                    ? [
                        backgroundColor ?? Theme.of(context).colorScheme.primary,
                        (backgroundColor ?? Theme.of(context).colorScheme.primary)
                            .withOpacity(0.8),
                      ]
                    : [
                        Colors.grey.withOpacity(0.5),
                        Colors.grey.withOpacity(0.3),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: padding,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: enabled 
                      ? (textColor ?? Colors.white)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}