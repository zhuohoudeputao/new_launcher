# Water Intake Tracker Provider

## Overview

The Water provider allows users to track their daily water intake, helping them stay hydrated and maintain healthy drinking habits. It provides a simple glass-counting interface with goal setting and progress visualization.

## Implementation

### File Location
`lib/providers/provider_water.dart`

### Model: `WaterModel`

The `WaterModel` class manages the state for water tracking:

```dart
class WaterModel extends ChangeNotifier {
  static const int maxHistoryDays = 30;
  static const String _storageKey = 'water_entries';
  static const String _goalKey = 'water_goal';
  static const int defaultGoal = 8;

  List<WaterEntry> _history = [];
  int _dailyGoal = defaultGoal;
  bool _isInitialized = false;
}
```

### Properties

- `isInitialized`: Whether the model has been initialized
- `dailyGoal`: Daily water intake goal (1-20 glasses, default 8)
- `history`: List of water entries for the past 30 days
- `todayGlasses`: Current day's glass count
- `progress`: Progress percentage toward daily goal (0.0 to 1.0+)
- `goalReached`: Boolean indicating if daily goal has been met

### Methods

- `init()`: Initialize model and load saved data from SharedPreferences
- `addGlass()`: Add one glass to today's count
- `removeGlass()`: Remove one glass from today's count (if > 0)
- `setGoal(int goal)`: Set daily goal (1-20 glasses)
- `clearHistory()`: Clear all water history entries
- `refresh()`: Refresh model state and check for daily reset

### Data Structure: `WaterEntry`

```dart
class WaterEntry {
  final DateTime date;
  final int glasses;
  final int goal;

  String toJson();
  static WaterEntry fromJson(String jsonStr);
  static String getDayKey(DateTime date);
}
```

## UI Components

### WaterCard

The main widget displays:
- Title with water drop icon
- Current count / daily goal display (e.g., "3/8")
- Linear progress bar with color indication
- Add glass button
- Remove glass button (disabled when count is 0)
- Settings button for goal adjustment
- "Goal reached!" celebration message when goal is met

### Goal Dialog

Allows users to adjust their daily goal:
- Uses +/- buttons to increment/decrement goal
- Range: 1 to 20 glasses
- Real-time update of the goal setting

## Features

### Daily Tracking
- Automatic daily reset at midnight
- Today's entry created automatically on first access
- History maintained for up to 30 days

### Goal Setting
- Default goal: 8 glasses
- Adjustable range: 1-20 glasses
- Goal saved to SharedPreferences
- Goal setting dialog with +/- controls

### Progress Visualization
- Linear progress bar using Material 3's `LinearProgressIndicator`
- Color changes based on progress:
  - Primary color when goal reached
  - Tertiary color when goal not yet reached

### Persistence
- All data saved to SharedPreferences
- History entries serialized as JSON
- Goal stored separately for quick access

## Material 3 Compliance

- Uses `Card.filled` for main card container
- Uses `LinearProgressIndicator` with rounded corners
- Uses `Theme.of(context).cardColor` for transparency support
- Uses ColorScheme colors for progress indication
- Uses `IconButton.styleFrom()` for consistent button styling

## Provider Registration

```dart
MyProvider providerWater = MyProvider(
    name: "Water",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

Added to `Global.providerList` in `lib/data.dart`.

## Keywords

Keywords for search functionality:
- water
- drink
- hydration
- glass
- cup
- intake
- track
- daily
- health

## Testing

Tests are located in `test/widget_test.dart` under the "Water provider tests" group:

- WaterModel initialization
- Add/remove glass operations
- Goal setting functionality
- Progress calculation
- Goal reached detection
- History clearing
- WaterEntry JSON serialization
- WaterCard widget rendering
- Provider registration verification

## Usage Example

```dart
// Add a glass of water
waterModel.addGlass();

// Remove a glass (if mistakenly added)
waterModel.removeGlass();

// Set daily goal to 10 glasses
waterModel.setGoal(10);

// Check if goal reached
if (waterModel.goalReached) {
  // Show celebration
}
```

## Future Enhancements

Potential improvements:
- Time-based reminders for drinking water
- Custom glass size (ml instead of glasses)
- Weekly/monthly statistics visualization
- Integration with health apps
- Notification reminders