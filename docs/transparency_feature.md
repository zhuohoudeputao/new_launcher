# Transparency Feature Documentation

## Overview

The transparency feature allows users to adjust the opacity of info cards in the launcher. Card opacity can be adjusted via the Settings page and dynamically updates all cards.

## Implementation Details

### Storage

- **Key**: `CardOpacity`
- **Default Value**: `0.7` (70%)
- **Range**: 10% - 100%

### Components

1. **Global** (`lib/data.dart`)
   - Stores `cardOpacityValue` as static variable
   - Provides `cardOpacity` getter
   - Loads saved opacity on app startup
   - `_refreshTheme()` notifies both themeModel and infoModel

2. **All Card Widgets** (`lib/ui.dart`, `lib/providers/*.dart`)
   - All Card widgets explicitly use `color: Theme.of(context).cardColor`
   - Card.filled and Card.outlined variants require explicit color property
   - Dynamically updates when theme changes
   - Builder widget used for standalone functions that need context

3. **CardOpacitySlider** (`lib/ui.dart`)
   - UI widget for adjusting opacity in settings
   - Uses Material Slider (9 divisions: 0.1 to 1.0)
   - Displays current value as percentage

4. **Provider Theme** (`lib/providers/provider_theme.dart`)
   - Uses `Global.cardOpacity` when creating card colors
   - Applies opacity to both light and dark themes
   - Calls `Global.infoModel.notifyListeners()` to trigger rebuild

### Usage Flow

1. User opens Settings
2. User adjusts Card Opacity slider
3. `_refreshTheme()` is called
4. Theme provider is re-initialized with new opacity
5. `infoModel.notifyListeners()` triggers rebuild of all cards
6. All Card widgets read new `ThemeData.cardColor`
7. UI updates to show new opacity

### Code Example

```dart
// Card.filled requires explicit color for transparency
return Card.filled(
  color: Theme.of(context).cardColor,
  child: ListTile(...),
);

// Card.outlined also requires explicit color
return Card.outlined(
  color: Theme.of(context).cardColor,
  child: Container(...),
);

// Standard Card uses theme card color
return Card(
  color: Theme.of(context).cardColor,
  elevation: 0,
  child: ListTile(...),
);

// Standalone functions use Builder to get context
Widget _buildAppCard(ApplicationWithIcon app) {
  return Builder(
    builder: (context) => Card(
      color: Theme.of(context).cardColor,
      child: ListTile(...),
    ),
  );
}

// Provider theme sets card color with opacity
Color cardColor = colorScheme.surface.withValues(alpha: Global.cardOpacity);
```

### Updated Widgets

All card widgets have been updated to use `Theme.of(context).cardColor`:
- SearchTextField (main.dart)
- InfoCard (ui.dart)
- customTextSettingWidget (ui.dart)
- CustomBoolSettingWidget (ui.dart)
- CardOpacitySlider (ui.dart)
- WallpaperPickerButton (ui.dart)
- LogViewerWidget (ui.dart)
- DarkModeOptionSelector (data.dart)
- RecentlyUsedAppsCard (provider_app.dart)
- AllAppsCard (provider_app.dart)
- AppStatisticsCard (provider_app.dart)
- _buildAppCard (provider_app.dart)
- WeatherCard (provider_weather.dart)

## Related Settings

- `CardOpacity` - Card transparency level
- `Theme.Dark` - Enable dark mode
- `Theme.Transparent` - Enable transparent cards