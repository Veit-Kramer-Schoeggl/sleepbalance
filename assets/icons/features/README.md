# Feature Icons

This folder contains icons used throughout the app features and screens.

## What Goes Here

Custom icons and illustrations for specific features:
- Sleep tracking icons
- Health metrics icons (heart rate, breathing, etc.)
- Action/recommendation icons
- Habit tracking icons
- Status indicators
- Any other feature-specific iconography

## Organization

Consider organizing by feature if you have many icons:
```
features/
  ├── sleep/
  │   ├── deep_sleep.png
  │   ├── light_sleep.png
  │   └── rem_sleep.png
  ├── health/
  │   ├── heart_rate.png
  │   ├── breathing.png
  │   └── temperature.png
  └── actions/
      ├── recommendation.png
      ├── alert.png
      └── success.png
```

## Recommended Specifications

- **Size**: Multiple sizes (24dp, 32dp, 48dp depending on usage)
- **Format**: PNG with transparency or SVG
- **Style**: Consistent with your app's design language
- **Color**: Consider single-color icons for easy theming

## Usage Example

```dart
Image.asset(
  'assets/icons/features/deep_sleep.png',
  width: 32,
  height: 32,
  color: Theme.of(context).colorScheme.primary,
)
```

## Alternative: Icon Fonts

For a large icon set, consider using custom icon fonts or packages like:
- `flutter_svg` for SVG icons
- Custom icon fonts generated from tools like IcoMoon or Fontello
