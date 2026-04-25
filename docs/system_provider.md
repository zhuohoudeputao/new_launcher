# System Provider Implementation

## Overview

The System provider provides quick access to system apps and utilities like camera, clock, calculator, settings, and a log viewer.

## Provider Details

- **Provider Name**: System
- **Keywords**: Various per action (logs, camera, settings, clock, calculator, date, time)
- **Dependencies**: device_apps package, LoggerModel

## Features

### Quick Launch Actions

| Action | Keywords | Description |
|--------|----------|-------------|
| Open camera | camera, photo, picture, capture | Opens device camera app |
| Open settings | settings, system, android, device | Opens Android settings app |
| Open clock | clock, time, alarm, timer | Opens device clock/alarm app |
| Open calculator | calculator, math, compute | Opens device calculator app |
| Open date and time settings | date, time, settings, clock, calendar, configure | Opens settings with guidance |
| View logs | logs, debug, error, view | Displays app log viewer |

### Log Viewer Widget

`LogViewerWidget` displays:
- Log entries from LoggerModel
- Color-coded log levels (info, warning, error)
- Timestamp and source information
- Scrollable list view

## Implementation

### Provider Structure

```dart
MyProvider providerSystem = MyProvider(
    name: "System",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### App Detection Logic

Uses `device_apps` package to find and launch apps:
- Searches by package name substring (e.g., "camera", "clock")
- Searches by app name for calculators
- Opens first matching app found

### Camera Launch

```dart
final apps = await DeviceApps.getInstalledApplications(
  includeSystemApps: true,
  onlyAppsWithLaunchIntent: true,
);
for (var app in apps) {
  if (app.packageName.toLowerCase().contains('camera')) {
    DeviceApps.openApp(app.packageName);
    return;
  }
}
```

### Settings Launch

Directly opens `com.android.settings` package.

### Date/Time Settings

Opens settings with guidance message:
- Title: "Settings opened"
- Subtitle: "Navigate to Date & Time section to configure"

## Error Handling

- Logs errors to LoggerModel
- Displays info message if app not found
- Shows error details in info card

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching for each action
- Action callbacks execute without errors

## Related Files

- `lib/providers/provider_system.dart` - Provider implementation
- `lib/logger.dart` - LoggerModel and LogViewerWidget
- `docs/logging_system.md` - Logging documentation