# App Statistics Feature

## Overview

The App Statistics feature tracks app usage patterns and displays statistics to help users understand their app usage behavior. It records launch counts and last launch times for each app, persists data across sessions using SharedPreferences, and presents the most frequently used apps in a dedicated card.

## Implementation

### AppStatisticsModel

Located in `lib/providers/provider_app.dart`, the `AppStatisticsModel` class manages app usage statistics with persistence support:

```dart
class AppStatisticsModel extends ChangeNotifier {
  final Map<String, int> _launchCounts = {};
  final Map<String, DateTime> _lastLaunchTime = {};
  
  static const int maxStatsEntries = 50;
  static const String _countsKey = 'AppStatistics.LaunchCounts';
  static const String _timesKey = 'AppStatistics.LastLaunchTimes';
  
  SharedPreferences? _prefs;
  
  // Key methods:
  Future<void> init() async;               // Initialize and load persisted data
  Future<void> _loadPersistedStats();      // Load from SharedPreferences
  Future<void> _saveStats();               // Save to SharedPreferences
  void recordLaunch(String appName);       // Record launch and save
  void clearStats();                       // Clear and save
}
```

### Persistence Format

Statistics are stored in SharedPreferences as strings:
- **Launch counts**: `"AppName1:Count1,AppName2:Count2,..."`
- **Launch times**: `"AppName1:ISO8601Time1,AppName2:ISO8601Time2,..."`

### Key Features

1. **Launch Tracking**: Records each app launch with timestamp
2. **Persistence**: Statistics survive app restarts via SharedPreferences
3. **Sorted Display**: Shows apps sorted by launch count (most used first)
4. **Time Context**: Displays relative time since last launch (e.g., "5m ago", "2h ago")
5. **Entry Limit**: Maintains maximum 50 entries to prevent memory overflow
6. **Statistics Summary**: Shows total launches and unique apps count

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

1. **Initialization**: `appStatisticsModel.init()` is called in `_initActions()`
2. **Recording Launches**: When an app is launched, `appStatisticsModel.recordLaunch()` is called
3. **Auto-Save**: Statistics are automatically saved after each launch
4. **Logging**: App launches and persistence events are logged

## Testing

Tests are located in `test/widget_test.dart`:

- Model initialization tests
- Launch count increment tests
- Last launch time tracking tests
- Sorting by launch count tests
- Clear stats functionality tests
- Notify listeners tests
- Max entries limit tests
- Persistence tests (requires SharedPreferences mock)
- Widget rendering tests (empty and populated states)

## Usage

Users can see their app usage statistics on the home screen in the App Statistics card. The feature automatically tracks and persists usage when apps are launched through the launcher interface. Statistics persist across app restarts.