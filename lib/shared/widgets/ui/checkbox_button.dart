import 'package:flutter/material.dart';

/// A checkbox button with icon, text, and floating effect
/// Layout: [Icon] [Text] [Checkbox]
class CheckboxButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final Color? checkboxColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  const CheckboxButton({
    super.key,
    required this.text,
    required this.icon,
    required this.isChecked,
    required this.onChanged,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.checkboxColor,
    this.width,
    this.height = 60,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          onTap: enabled ? () => onChanged(!isChecked) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: enabled
                    ? [
                        backgroundColor ?? Colors.white.withOpacity(0.1),
                        (backgroundColor ?? Colors.white.withOpacity(0.1))
                            .withOpacity(0.05),
                      ]
                    : [
                        Colors.grey.withOpacity(0.1),
                        Colors.grey.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: padding,
            child: Row(
              children: [
                // Left icon
                Icon(
                  icon,
                  color: enabled 
                      ? (iconColor ?? Colors.white)
                      : Colors.white.withOpacity(0.5),
                  size: 24,
                ),
                
                const SizedBox(width: 12),
                
                // Center text
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: enabled 
                          ? (textColor ?? Colors.white)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Right checkbox
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: isChecked,
                    onChanged: enabled ? onChanged : null,
                    activeColor: checkboxColor ?? Theme.of(context).colorScheme.primary,
                    checkColor: Colors.white,
                    side: BorderSide(
                      color: enabled 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}