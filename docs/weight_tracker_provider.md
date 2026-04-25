# Weight Tracker Provider

## Overview

The Weight Tracker provider allows users to track daily body weight measurements for health monitoring. It supports both kg and lb units, goal weight setting with progress visualization, and provides statistics on weight trends over time.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_weight_tracker.dart`
- Tests: `test/widget_test.dart` (Weight Tracker Provider tests group)

### Provider Registration
```dart
MyProvider providerWeightTracker = MyProvider(
    name: "WeightTracker",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

## Features

### Weight Unit Support
- Kilograms (kg) - default unit
- Pounds (lb) - optional unit with automatic conversion
- Unit toggle with ActionChip buttons
- Conversion formula: 1 kg = 2.2046226218 lb, 1 lb = 0.45359237 kg (precise international conversion)

### Weight Logging
- Log weight with decimal precision
- Support for custom dates (within 30 days)
- Updates existing entry for same day
- Automatic sorting by date
- Maximum 30 entries stored (oldest removed when limit exceeded)

### Goal Weight
- Set target goal weight in either unit
- Progress percentage visualization
- LinearProgressIndicator showing progress toward goal
- Supports both weight loss and weight gain goals
- Goal progress calculated from first entry to current weight

### Statistics
- Average weight across all entries
- Minimum weight recorded
- Maximum weight recorded
- Total weight change (from first to latest entry)
- Weight trend indicator (up/down arrows)
- Number of days logged

### History Management
- History view showing all entries
- Delete individual entries
- Clear all history with confirmation dialog
- Entries persisted via SharedPreferences

## Data Models

### WeightUnit Enum
```dart
enum WeightUnit {
  kg,
  lb,
}
```

Extension methods:
- `label`: Returns unit symbol ('kg' or 'lb')
- `fullName`: Returns full unit name ('Kilograms' or 'Pounds')
- `toKg(double value)`: Converts to kilograms
- `fromKg(double value)`: Converts from kilograms

### WeightEntry Class
```dart
class WeightEntry {
  final DateTime date;
  final double weightKg;
}
```

Methods:
- `toJson()`: Serializes entry to JSON string
- `fromJson(String)`: Deserializes entry from JSON string
- `getDayKey(DateTime)`: Returns day identifier string
- `formatWeight(WeightUnit)`: Returns formatted weight string

### WeightTrackerModel Class
State management using ChangeNotifier pattern.

Properties:
- `history`: List of all weight entries
- `unit`: Current weight unit (kg or lb)
- `goalWeightKg`: Goal weight in kilograms
- `hasGoal`: Boolean indicating if goal is set
- `hasHistory`: Boolean indicating if entries exist
- `latestEntry`: Most recent weight entry
- `averageWeight`: Average of all weights
- `minWeight`: Lowest weight recorded
- `maxWeight`: Highest weight recorded
- `weightChange`: Change from first to latest entry
- `goalProgress`: Percentage progress toward goal

Methods:
- `init()`: Initialize from SharedPreferences
- `logWeight(weight, unit, customDate)`: Add/update weight entry
- `setUnit(unit)`: Change display unit
- `setGoal(weight, unit)`: Set goal weight
- `clearGoal()`: Remove goal weight
- `deleteEntry(index)`: Remove specific entry
- `clearHistory()`: Remove all entries

## UI Components

### WeightTrackerCard
Main widget displaying:
- Current weight display
- Weight change trend indicator
- Goal progress (if goal set)
- Statistics row (average, min, max)
- Action buttons: Log, Goal, History

### WeightLogDialog
Dialog for logging weight:
- Weight input field with unit suffix
- Unit selection (kg/lb ActionChips)
- Custom date checkbox and date picker
- Save/Cancel buttons

### WeightGoalDialog
Dialog for setting goal:
- Goal weight input field
- Unit selection (kg/lb ActionChips)
- Clear goal checkbox (if goal already set)
- Save/Cancel buttons

## Keywords

Searchable keywords for action:
- weight, tracker, body, scale, kg, lb, pound, kilogram, measure, log, track

## Material 3 Style

Uses Material 3 components:
- `Card.filled()` for main card
- `ActionChip` for unit selection
- `LinearProgressIndicator` for goal progress
- `TextButton.icon` for action buttons
- `IconButton` for delete actions
- `AlertDialog` for history and confirmation dialogs

## Testing

Test coverage includes:
- Provider existence and keywords
- Weight unit conversion accuracy
- WeightEntry serialization/deserialization
- Model state management (log, delete, clear)
- Statistics calculations (average, min, max, change)
- Goal progress calculation
- History limit enforcement (30 entries)
- Widget rendering (loading, initialized, with data)
- Dialog functionality (log, goal)

## SharedPreferences Keys

- `weight_tracker_entries`: List of weight entry JSON strings
- `weight_tracker_goal`: Goal weight in kilograms (double)
- `weight_tracker_unit`: Current unit ('kg' or 'lb')

## Integration

Added to Global.providerList in `lib/data.dart`:
```dart
providerWeightTracker,
```

Total providers: 105