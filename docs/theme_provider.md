# Theme Provider Implementation

## Overview

The Theme provider manages the Material 3 theme for the launcher application, supporting light, dark, and system-following modes with dynamic color generation.

## Provider Details

- **Provider Name**: Theme
- **Keywords**: refresh theme
- **Settings Keys**: `Theme.Mode`, `Theme.Dark`, `Theme.Transparent`
- **Dependencies**: ThemeModel, InfoModel

## Features

### Theme Mode Support

Three theme modes are supported:
- **Light**: Always use light theme
- **Dark**: Always use dark theme
- **System**: Follow system brightness settings

### Material 3 Design

- Uses `ColorScheme.fromSeed()` for dynamic color generation
- Seed color: Indigo
- Full Material 3 support with `useMaterial3: true`

### Transparent Cards

Optional transparent card backgrounds with configurable opacity:
- Controlled by `Theme.Transparent` setting
- Uses `Global.cardOpacity` for transparency level
- Card color set to `colorScheme.surface.withValues(alpha: opacity)`

## Implementation

### Provider Structure

```dart
MyProvider providerTheme = MyProvider(
    name: "Theme",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Actions

- **Refresh theme**: Manually refresh the current theme

### Theme Generation Process

1. Get theme mode from settings (`Theme.Mode`)
2. Determine brightness (light, dark, or system-following)
3. Generate ColorScheme from Indigo seed color
4. Apply transparent card color if enabled
5. Set ThemeData with Material 3 configuration
6. Refresh InfoModel to update UI

### Settings Integration

- **Theme.Mode**: Stores current theme mode (light/dark/system)
- **Theme.Dark**: Legacy boolean for dark mode (deprecated)
- **Theme.Transparent**: Toggle for transparent card backgrounds

## Model (ThemeModel)

Located in `lib/data.dart`:

```dart
class ThemeModel with ChangeNotifier {
  ThemeData? _themeData;
  ThemeData get themeData => _themeData ?? ThemeData();

  set themeData(ThemeData value) {
    _themeData = value;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}
```

## Theme Application

The theme is applied in `MyApp` widget:

```dart
return MaterialApp(
  theme: context.watch<ThemeModel>().themeData,
  home: MyHomePage(),
  navigatorKey: navigatorKey,
);
```

## System Brightness Detection

```dart
Brightness _getSystemBrightness() {
  return SchedulerBinding.instance.platformDispatcher.platformBrightness;
}
```

## Usage

### Changing Theme Mode

Users can change theme mode through the Settings provider's `DarkModeOptionSelector` widget:

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

### Refreshing Theme

The theme automatically refreshes when:
1. App initializes
2. Theme mode setting changes
3. Platform brightness changes (for system mode)
4. Card opacity changes
5. Manual refresh action triggered

## Color Scheme Properties

Material 3 ColorScheme provides:
- Primary, secondary, tertiary colors
- Surface and background colors
- Error colors
- On-color variants for text

## Testing

Tests verify:
- ThemeModel functionality
- Material 3 enabled
- ColorScheme generation
- Theme mode selection widget

## Related Files

- `lib/providers/provider_theme.dart` - Provider implementation
- `lib/data.dart` - ThemeModel definition
- `lib/main.dart` - Theme application in MaterialApp
- `docs/material3_upgrade.md` - Material 3 implementation guide