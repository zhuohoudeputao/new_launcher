# App Statistics Feature

## Overview

The App Statistics feature tracks app usage patterns and displays statistics to help users understand their app usage behavior. It records launch counts and last launch times for each app, and presents the most frequently used apps in a dedicated card.

## Implementation

### AppStatisticsModel

Located in `lib/providers/provider_app.dart`, the `AppStatisticsModel` class manages app usage statistics:

```dart
class AppStatisticsModel extends ChangeNotifier {
  final Map<String, int> _launchCounts = {};
  final Map<String, DateTime> _lastLaunchTime = {};
  
  static const int maxStatsEntries = 50;
  
  List<String> get mostUsedApps;
  int getLaunchCount(String appName);
  DateTime? getLastLaunchTime(String appName);
  int get totalLaunches;
  int get uniqueApps;
  
  void recordLaunch(String appName);
  void clearStats();
  void loadStats(Map<String, int> counts, Map<String, DateTime> times);
}
```

### Key Features

1. **Launch Tracking**: Records each app launch with timestamp
2. **Sorted Display**: Shows apps sorted by launch count (most used first)
3. **Time Context**: Displays relative time since last launch (e.g., "5m ago", "2h ago")
4. **Entry Limit**: Maintains maximum 50 entries to prevent memory overflow
5. **Statistics Summary**: Shows total launches and unique apps count

### AppStatisticsCard Widget

Displays the top 5 most used apps in a compact card format:

- Header with statistics summary (unique apps, total launches)
- List of top apps with:
  - App icon (if available)
  - App name
  - Launch count and time since last launch
  - Bold launch count indicator

### Integration

The statistics are integrated with the app provider:

1. **Recording Launches**: When an app is launched via action, `appStatisticsModel.recordLaunch()` is called
2. **Logging**: App launches are logged via `Global.loggerModel.info()`
3. **Display**: The `AppStatisticsCard` is added to the info widgets list

## Testing

Tests are located in `test/widget_test.dart`:

- Model initialization tests
- Launch count increment tests
- Last launch time tracking tests
- Sorting by launch count tests
- Clear stats functionality tests
- Notify listeners tests
- Max entries limit tests
- Widget rendering tests (empty and populated states)

## Usage

Users can see their app usage statistics on the home screen in the App Statistics card. The feature automatically tracks usage when apps are launched through the launcher interface.