# Sleep Tracker Provider

## Overview

The Sleep Tracker provider enables users to track their sleep patterns, including duration and quality. It provides insights into sleep habits through averages and goal tracking.

## Features

- **Sleep logging**: Record sleep duration (0-12 hours) and quality (5 levels)
- **Quality levels**: Terrible, Poor, Fair, Good, Excellent with emoji indicators
- **Custom date logging**: Log sleep for past dates (within 30 days)
- **Optional notes**: Add notes for each sleep entry
- **Statistics**: Average hours, average quality, nights meeting 7-hour goal
- **History view**: View and manage past sleep entries
- **Delete entries**: Remove individual entries via swipe or button
- **Clear all**: Reset entire sleep history with confirmation

## Implementation

### SleepQuality Enum

```dart
enum SleepQuality {
  terrible,    // 1 - 😫
  poor,        // 2 - 😴
  fair,        // 3 - 😐
  good,        // 4 - 😊
  excellent,   // 5 - 😄
}
```

### SleepEntry Class

```dart
class SleepEntry {
  final DateTime date;
  final double hours;
  final int qualityValue;
  final String? note;
}
```

### SleepModel

```dart
class SleepModel extends ChangeNotifier {
  static const int maxHistoryDays = 30;
  
  // Key methods
  Future<void> init()
  void logSleep(double hours, SleepQuality quality, {String? note, DateTime? customDate})
  void deleteEntry(int index)
  Future<void> clearHistory()
  
  // Statistics getters
  double get averageHours
  double get averageQuality
  int get nightsGoalMet
  SleepEntry? get lastNightEntry
}
```

## UI Components

### SleepCard

- Displays last night's sleep data (hours and quality)
- Shows statistics: average hours, average quality, nights meeting goal
- Log button to add new entries
- History button to view and manage entries

### SleepLogDialog

- Slider for hours (0-12, 0.5-hour increments)
- Emoji selector for quality rating
- Optional date picker for past entries
- Optional note input field

## Data Persistence

Sleep entries are stored in SharedPreferences as a JSON string list:
- Key: `sleep_entries`
- Maximum entries: 30 days
- Oldest entries removed when limit exceeded

## Usage

### Keywords

```
sleep rest nap bed track night hours quality bedtime
```

### Adding from Provider

The Sleep provider is automatically added to:
- `Global.providerList` in `lib/data.dart`
- `MultiProvider` in `lib/main.dart`

## Statistics Calculations

- **Average Hours**: Mean of all logged sleep hours
- **Average Quality**: Mean of quality values (1-5)
- **Nights Goal Met**: Count of entries with ≥7 hours

## Tests

Located in `test/widget_test.dart` under "Sleep provider tests":
- SleepQuality enum and extension tests
- SleepEntry class tests
- SleepModel method tests
- Widget rendering tests
- Provider existence tests

Total: 35 tests

## Integration

The Sleep provider follows the standard provider pattern:
1. Model (`SleepModel`) manages state and persistence
2. Provider (`providerSleep`) registers actions and widgets
3. Card (`SleepCard`) displays data and statistics
4. Dialog (`SleepLogDialog`) handles user input

## Date

2026-04-24