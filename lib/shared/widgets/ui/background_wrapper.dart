import 'package:flutter/material.dart';

/// A reusable widget that wraps screen content with a background image.
/// Screens can optionally use this widget for consistent theming.
class BackgroundWrapper extends StatelessWidget {
  /// The child widget to display on top of the background
  final Widget child;

  /// The path to the background image asset
  final String? imagePath;

  /// Opacity of the overlay (0.0 to 1.0) for better text readability
  final double overlayOpacity;

  /// Color of the overlay
  final Color overlayColor;

  const BackgroundWrapper({
    super.key,
    required this.child,
    this.imagePath,
    this.overlayOpacity = 0.3,
    this.overlayColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    // If no image path is provided, just return the child
    if (imagePath == null || imagePath!.isEmpty) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient if image fails to load
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                  ],
                ),
              ),
            );
          },
        ),
        // Semi-transparent overlay for better text readability
        if (overlayOpacity > 0)
          Container(
            color: overlayColor.withValues(alpha: overlayOpacity),
          ),
        // Content on top
        child,
      ],
    );
  }
}
