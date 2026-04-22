# App Card Feature

## Overview

The App Card feature provides a card-based interface for displaying and launching installed applications. Users can view all apps in a scrollable grid card and access recently used apps through a dedicated card.

## Architecture

### Models

- **AppModel**: Manages recently used apps
  - `recentApps`: Map of app name to widget
  - `addApp(key, widget)`: Adds an app to recent apps list
  - Notifies listeners when apps are added

- **AllAppsModel**: Manages the complete list of installed apps
  - `allApps`: List of `ApplicationWithIcon` objects
  - `setApps(apps)`: Updates the apps list
  - Notifies listeners when apps are set

### Widgets

- **AllAppsCard**: Horizontal GridView displaying all installed apps
  - 5 columns per row
  - Scrollable horizontally
  - Each item shows app icon and name
  - Tap to launch app

- **RecentlyUsedAppsCard**: Horizontal ListView of recently launched apps
  - Shows apps in reverse order (most recent first)
  - Circular button style for app icons

### Provider Integration

- **provider_app.dart**: Registers app-related providers
  - `provideActions`: Creates actions for each installed app
  - `initActions`: Adds AllAppsCard and RecentlyUsedAppsCard to info list
  - Uses `device_apps` package for app enumeration

### Provider Registration

Models are registered in `main.dart` MultiProvider:
```dart
ChangeNotifierProvider.value(value: appModel),
ChangeNotifierProvider.value(value: allAppsModel),
```

## Usage

1. **View All Apps**: Scroll through the AllAppsCard to see all installed apps
2. **Launch App**: Tap any app icon in the grid to launch
3. **Recent Apps**: Recently launched apps appear in the RecentlyUsedAppsCard
4. **Search**: Type app name in search box to filter cards

## Implementation Details

### App Enumeration

```dart
final apps = await DeviceApps.getInstalledApplications(
    includeSystemApps: true,
    includeAppIcons: true,
    onlyAppsWithLaunchIntent: false);
```

### Individual App Cards

All installed apps are added as individual info cards using batch adding for performance:
```dart
final appWidgets = allAppsWithIcons.map((app) => 
  MapEntry("app_${app.packageName}", _buildAppCard(app))
).toList();
final appTitles = Map.fromEntries(
  allAppsWithIcons.map((app) => MapEntry("app_${app.packageName}", app.appName))
);
Global.infoModel.addInfoWidgetsBatch(appWidgets, titles: appTitles);
```

Using `addInfoWidgetsBatch` instead of calling `addInfoWidget` for each app ensures only one `notifyListeners()` call, improving performance when loading many apps.

Each app card:
- Displays app icon and name
- Shows package name as subtitle
- Tap to launch the app
- Searchable by app name or key

### AllAppsCard (Compact View)

The AllAppsCard provides a compact horizontal grid view for quick app browsing:
- 5 columns per row
- Scrollable horizontally
- Each item shows app icon and name
- Tap to launch app

## Testing

Tests for AppModel and AllAppsModel are located in `test/widget_test.dart`:
- AppModel initialization and addApp functionality
- AllAppsModel initialization and setApps functionality
- RecentlyUsedAppsCard and AllAppsCard widget tests

## Dependencies

- `device_apps: ^2.2.0`: For app enumeration and launching
- `provider: ^6.0.0`: For state management