# Logging System Documentation

## Overview

The logging system records application events for analysis and debugging. It tracks initialization, user actions, and errors.

## Implementation

### LoggerModel

- **Location**: `lib/logger.dart`
- **Pattern**: Singleton (shared instance)
- **Max logs**: 1000 entries

### Log Levels

| Level | Icon | Use Case |
|-------|------|----------|
| debug | bug_report | Development info |
| info | info | General events |
| warning | warning | Non-critical issues |
| error | error | Failures |

### API

```dart
// Get logger instance
final logger = LoggerModel();

// Log messages
logger.debug("Debug message", source: "Component");
logger.info("Info message", source: "Component");
logger.warning("Warning message", source: "Component");
logger.error("Error message", source: "Component");

// Query logs
final allLogs = logger.logs;
final errors = logger.filterByLevel(LogLevel.error);
final sourceLogs = logger.filterBySource("Weather");
final searchResults = logger.search("query");

// Clear logs
logger.clear();
```

### Integration

The logger is integrated into:

1. **Global initialization** - Logs each provider startup
2. **Weather provider** - Logs geolocation errors
3. **Settings changes** - Can be extended to log setting updates

### Display

Logs are available in memory. A `LogViewerWidget` is implemented in `lib/ui.dart`:

- Search bar for filtering by message content
- Dropdown filter for log level (All, Error, Warn, Info, Debug)
- Displays log icon, message, source, and timestamp
- Clear button to remove all logs

### View Logs Action

Added in `lib/providers/provider_system.dart`:

```dart
MyAction(
  name: 'View logs',
  keywords: 'logs debug error view',
  action: () {
    Global.infoModel.addInfoWidget("Logs", LogViewerWidget(), title: "Logs");
  },
)
```

Type "logs" in the search field to display the log viewer.

## Usage Examples

### Logging User Actions

```dart
logger.info("User opened app", source: "App");
logger.info("User searched: $query", source: "Search");
logger.info("User launched app: $appName", source: "AppLauncher");
```

### Logging Errors

```dart
try {
  await fetchWeather();
} catch (e) {
  logger.error("Weather fetch failed: $e", source: "Weather");
}
```

### Logging Performance

```dart
final stopwatch = Stopwatch()..start();
// operation
stopwatch.stop();
logger.debug("Operation took ${stopwatch.elapsedMilliseconds}ms", source: "Performance");
```

## Future Features

- Log persistence to file
- Log export functionality
- Crash reporting
- Analytics integration