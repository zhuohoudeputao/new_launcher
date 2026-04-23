# Settings Provider Feature

## Overview

Created a dedicated Settings provider following the established `MyProvider` pattern. This ensures consistency with other providers (Weather, Time, App, Theme, Wallpaper, System) and properly integrates the Settings card into the main info list.

## Previous Implementation

Settings was previously added manually in `Global._addSettingsToInfo()` during initialization, bypassing the provider system. This created an inconsistency in the architecture.

## New Implementation

### provider_settings.dart

Created a new provider file at `lib/providers/provider_settings.dart`:

```dart
MyProvider providerSettings = MyProvider(
    name: "Settings",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Key Components

#### 1. Actions

Registers an "Open settings" action with keywords:
- `settings`
- `launcher`
- `configuration`
- `options`
- `preferences`

This allows users to search for and access settings via the search field.

#### 2. SettingsCard Widget

A Material 3 `Card.filled` widget displaying:
- Settings icon (leading)
- "Settings" title
- "Tap to customize launcher" subtitle
- Chevron right icon (trailing)
- Tap action to navigate to settings page

```dart
class SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card.filled(
      child: ListTile(
        leading: Icon(Icons.settings, color: colorScheme.primary),
        title: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Tap to customize launcher"),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (context) => Setting()));
        },
      ),
    );
  }
}
```

### Integration Changes

#### lib/data.dart

1. Added import for `provider_settings.dart`
2. Removed import for `setting.dart` (no longer needed)
3. Removed `_addSettingsToInfo()` method and its call
4. Added `providerSettings` to `providerList` (first position)

```dart
static List<MyProvider> providerList = [
  providerSettings,
  providerWallpaper,
  providerTheme,
  providerTime,
  providerWeather,
  providerApp,
  providerSystem,
];
```

## Benefits

1. **Consistency**: Settings now follows the same pattern as all other providers
2. **Enablable**: Settings can be enabled/disabled via `Settings.Enabled` preference
3. **Searchable**: Settings action appears in suggestions when searching
4. **Material 3**: Uses Card.filled for proper Material 3 styling
5. **Visibility**: Settings card appears first in providerList, ensuring it's initialized early

## Provider Order

Settings is now first in the provider list:
1. Settings
2. Wallpaper
3. Theme
4. Time
5. Weather
6. App
7. System

This ensures Settings is always visible and accessible.

## Testing

Added 7 new tests in `test/widget_test.dart`:

### Settings Provider Tests (4 tests)
- `providerSettings exists in Global.providerList`
- `Settings provider has correct actions`
- `Settings provider initActions adds SettingsCard`
- `Open settings action keywords are correct`

### SettingsCard Tests (3 tests)
- `SettingsCard renders correctly`
- `SettingsCard uses Card.filled`
- `SettingsCard is tappable`

Updated existing tests:
- `Global.providerList contains all providers`: Updated count from 6 to 7
- `Global.providerList names are correct`: Added 'Settings' check

## Architecture Alignment

The Settings provider follows the same structure as other providers:

| Provider | Actions | Info Widgets | Settings |
|----------|---------|--------------|----------|
| Settings | Open settings | SettingsCard | Settings.Enabled |
| Weather | Weather now | WeatherCard | Weather.Enabled |
| Time | Time now | TimeWidget | Time.Enabled |
| App | Per-app actions | AppCards | App.Enabled |
| Theme | - | ThemeCard | Theme.Enabled |
| Wallpaper | - | WallpaperPicker | Wallpaper.Enabled |
| System | Quick launch | - | System.Enabled |

## Future Enhancements

Potential improvements:
- Add inline settings toggles (e.g., quick theme switcher)
- Add settings categories/subpages
- Add settings search within settings page
- Add settings backup/restore functionality