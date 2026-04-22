# Material 3 Upgrade Documentation

## Overview

The app has been fully upgraded to Material 3, providing a modern, consistent design language with dynamic colors, card variants, and Material 3 specific components.

## Implementation Details

### Phase 1: Basic Material 3 Setup

1. **Theme Configuration** (`lib/providers/provider_theme.dart`)
   - Enabled `useMaterial3: true` in ThemeData
   - Implemented dynamic color scheme using `ColorScheme.fromSeed()`
   - Seed color: Indigo for both light and dark themes

2. **Card Styling**
   - Zero elevation for flat design
   - 12dp rounded corners
   - Updated all Card components to use Material 3 shape

### Phase 2: Material 3 Components

1. **SegmentedButton** (New Material 3 Component)
   - Replaced three TextButtons with `SegmentedButton<String>` for theme mode selection
   - Includes icons: light_mode, dark_mode, settings_suggest
   - Location: `lib/data.dart` - `DarkModeOptionSelector`

2. **Card Variants**
   - `Card.filled()`: For primary content (search input, recently used apps, weather)
   - `Card.outlined()`: For secondary content (all apps, app statistics)
   - Standard Card with elevation: 0: For settings items

3. **Button Styling**
   - Suggestions use `ElevatedButton` with `elevation: 0` (Material 3 tonal button style)
   - Clear button in LogViewer uses Material 3 styled ElevatedButton

### Color Scheme Usage

All hardcoded colors replaced with ColorScheme:

| Component | Old Color | New ColorScheme Property |
|-----------|-----------|--------------------------|
| Log level error | Colors.red | colorScheme.error |
| Log level warning | Colors.orange | colorScheme.tertiary |
| Log level info | Colors.blue | colorScheme.primary |
| Log level debug | Colors.grey | colorScheme.onSurfaceVariant |
| AppBar background | Colors.transparent | colorScheme.surface.withValues(alpha: 0) |
| Scaffold background | Colors.transparent | colorScheme.surface.withValues(alpha: 0) |
| Text colors | Colors.white/black | colorScheme.onSurface |
| IconButton color | hardcoded | IconButton.styleFrom(foregroundColor: colorScheme.primary) |

### Settings Page Improvements

- AppBar uses `scrolledUnderElevation: 0` (Material 3 standard)
- IconButton uses `IconButton.styleFrom()` with ColorScheme
- Background gradient uses ColorScheme surface colors

### Search Input

- Uses `Card.filled()` for Material 3 appearance
- Result count indicator uses ColorScheme.onSurface.withValues(alpha: 0.6)

## Component Variants Summary

| Component | Card Variant | Usage |
|-----------|--------------|-------|
| Search Input | Card.filled | Primary interaction |
| Recently Used Apps | Card.filled | Quick access |
| Weather Card | Card.filled | Primary information |
| All Apps Grid | Card.outlined | Secondary browsing |
| App Statistics | Card.outlined | Secondary information |
| Settings Items | Card.filled | Primary settings |
| Theme Mode Selector | Card.filled | Primary settings |

## Code Examples

### SegmentedButton Implementation

```dart
SegmentedButton<String>(
  segments: [
    ButtonSegment(value: "light", label: Text("Light"), icon: Icon(Icons.light_mode)),
    ButtonSegment(value: "dark", label: Text("Dark"), icon: Icon(Icons.dark_mode)),
    ButtonSegment(value: "system", label: Text("System"), icon: Icon(Icons.settings_suggest)),
  ],
  selected: {currentMode},
  onSelectionChanged: (Set<String> newSelection) {
    onChanged(newSelection.first);
  },
)
```

### ColorScheme Color Usage

```dart
// Log level colors
Color _getLevelColor(LogLevel level) {
  final colorScheme = Theme.of(context).colorScheme;
  switch (level) {
    case LogLevel.error: return colorScheme.error;
    case LogLevel.warning: return colorScheme.tertiary;
    case LogLevel.info: return colorScheme.primary;
    case LogLevel.debug: return colorScheme.onSurfaceVariant;
  }
}

// IconButton with ColorScheme
IconButton(
  icon: Icon(Icons.photo_library),
  style: IconButton.styleFrom(
    foregroundColor: colorScheme.primary,
  ),
  onPressed: onTap,
)
```

## Benefits

1. **Visual Consistency**: All components use Material 3 design language
2. **Dynamic Colors**: ColorScheme provides cohesive color palette
3. **Modern Components**: SegmentedButton, Card.filled/outlined
4. **Accessibility**: Material 3 design includes accessibility improvements
5. **Visual Hierarchy**: Card variants distinguish primary vs secondary content

## Files Modified

- `lib/providers/provider_theme.dart` - Theme setup
- `lib/data.dart` - DarkModeOptionSelector with SegmentedButton
- `lib/ui.dart` - All card components, buttons, log viewer
- `lib/setting.dart` - Settings page AppBar and colors
- `lib/main.dart` - Scaffold, search input
- `lib/providers/provider_app.dart` - App cards with variants
- `lib/providers/provider_weather.dart` - Weather card variant

## Future Improvements

- User-selectable seed colors
- Dynamic color extraction from wallpaper (Material You)
- DropdownMenu instead of DropdownButton
- NavigationBar for bottom navigation
- Material 3 motion and animation system