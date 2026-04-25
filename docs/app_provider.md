# App Provider Implementation

## Overview

The App provider manages app launching functionality, displaying installed apps in the launcher with recently used apps, all apps grid, and usage statistics.

## Provider Details

- **Provider Name**: App
- **Keywords**: launch, app names, package names
- **Dependencies**: device_apps, SharedPreferences
- **Models**: appModel, allAppsModel, appStatisticsModel

## Features

### App Launching

- Type app name to launch via command box
- Tap app icon to launch from card
- Automatic keyword matching (app name + package name)

### Recently Used Apps Card

- Shows last 5 launched apps
- Horizontal scrollable list
- 80px height card.filled style
- Icons with app names

### All Apps Card

- GridView of all installed apps (120px height per row)
- Horizontal scrollable content
- Displays all apps without limit
- Card.outlined style
- Text overflow handling for long names

### App Statistics Card

- Tracks app launch counts
- Shows most frequently used apps
- Clear statistics button with confirmation
- Card.outlined style
- Dynamic height based on content

## Models

### AppModel (Recent Apps)

```dart
class AppModel with ChangeNotifier {
  final Map<String, Widget> _recentApps = Map<String, Widget>();
  int _maxRecentApps = 5;
  
  void addApp(String appName, Widget appWidget);
  void clearApps();
}
```

### AllAppsModel (All Apps)

```dart
class AllAppsModel with ChangeNotifier {
  List<ApplicationWithIcon> _apps = [];
  
  void setApps(List<ApplicationWithIcon> apps);
  List<ApplicationWithIcon> get apps;
}
```

### AppStatisticsModel (Launch Statistics)

```dart
class AppStatisticsModel with ChangeNotifier {
  Map<String, int> _launchCounts = {};
  final int _maxEntries = 20;
  
  void recordLaunch(String appName);
  void clearStatistics();
  List<MapEntry<String, int>> getSortedStatistics();
}
```

## Implementation

### App Enumeration

Uses `device_apps` package:
- `getInstalledApplications()` with icons
- `includeSystemApps: true`
- `onlyAppsWithLaunchIntent: true`
- Requires `QUERY_ALL_PACKAGES` permission for Android 11+

### Launch Recording

```dart
DeviceApps.openApp(app.packageName);
appStatisticsModel.recordLaunch(app.appName);
Global.loggerModel.info("Launched app: ${app.appName}", source: "App");
```

### Batch Widget Addition

```dart
Global.infoModel.addInfoWidgetsBatch(appWidgets, titles: appTitles);
```

## Permissions

Android 11+ requires:
```xml
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

## Testing

Tests verify:
- Provider existence in Global.providerList
- Models functionality
- Widget rendering
- Statistics tracking and clearing

## Performance Optimizations

- `RepaintBoundary` for app icons
- `cacheWidth` for image caching
- Batch widget addition (single notifyListeners)
- Lazy icon loading

## Related Files

- `lib/providers/provider_app.dart` - Provider implementation
- `docs/app_card_feature.md` - App card implementation
- `docs/app_statistics_feature.md` - Statistics tracking
- `docs/app_limit_removal.md` - Unlimited app display