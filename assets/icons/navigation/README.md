# Navigation Icons

This folder contains custom icons for the bottom navigation bar.

## What Goes Here

Custom icons for the 4 bottom navigation tabs:
- **Dashboard icon** - Currently using Material Icons `dashboard`
- **Night Review icon** - Currently using Material Icons `bedtime`
- **Habits Lab icon** - Currently using Material Icons `science`
- **Action Center icon** - Currently using Material Icons `task_alt`

## Usage

If you want to use custom icons instead of Material Icons, place your icon files here and update the MainNavigation widget.

Example file names:
```
dashboard.png
dashboard_filled.png        # Selected state
night.png
night_filled.png           # Selected state
habits.png
habits_filled.png          # Selected state
action.png
action_filled.png          # Selected state
```

## Recommended Specifications

- **Size**: 24x24 dp (72x72 px @3x)
- **Format**: PNG with transparency
- **Color**: Single color (white/black) for easy theming
- Consider using SVG format with flutter_svg package for scalability

## How to Use Custom Icons

In `lib/shared/widgets/main_navigation.dart`, replace:
```dart
Icon(Icons.dashboard)
```

With:
```dart
Image.asset('assets/icons/navigation/dashboard.png', width: 24, height: 24)
```
