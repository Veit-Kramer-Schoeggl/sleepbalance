# App Icons

This folder contains the app launcher icons and splash screen assets.

## What Goes Here

- **App launcher icon** - The icon that appears on the device home screen
- **Adaptive icons** - Android adaptive icon variants (foreground/background)
- **iOS app icons** - Various sizes for iOS (if not using flutter_launcher_icons)
- **Splash screen logo** - Logo displayed during app startup

## Typical Files

```
icon.png                    # Main app icon (1024x1024 recommended)
icon_foreground.png         # Android adaptive icon foreground
icon_background.png         # Android adaptive icon background
splash_logo.png             # Logo for splash screen
```

## Recommended Tool

Consider using the `flutter_launcher_icons` package to automatically generate all required sizes:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

## Notes

- Keep source files at high resolution (1024x1024 or higher)
- Use PNG format with transparency where needed
- Android requires adaptive icons (API 26+)
