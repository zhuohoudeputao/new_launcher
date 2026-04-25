# Pace Provider

## Overview

The Pace provider is a running pace calculator for fitness and race prediction. It allows users to calculate pace (min/km or min/mile), time, and distance, and provides predicted race times for common distances like 5K, 10K, Half Marathon, and Marathon.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_pace.dart`
- Tests: `test/widget_test.dart` (Pace Provider tests group)

### Provider Registration
```dart
MyProvider providerPace = MyProvider(
    name: "Pace",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

## Features

### Calculation Modes
Three calculation modes via SegmentedButton:
- **Pace**: Calculate pace (min/km or min/mile) from distance and time
- **Time**: Calculate total time from distance and pace
- **Distance**: Calculate distance from pace and time

### Unit Support
- Kilometers (km) - default unit
- Miles (mi) - optional unit
- SegmentedButton for unit selection

### Pace Calculation
- Input: distance and time (minutes + seconds)
- Output: pace per unit (e.g., 5:00 min/km)
- Real-time calculation as values are entered

### Time Calculation
- Input: distance and pace (minutes + seconds per unit)
- Output: total time in HH:MM:SS or MM:SS format
- Handles hours for long distances

### Distance Calculation
- Input: pace (minutes + seconds per unit) and time
- Output: distance in selected unit

### Race Predictions
Available in Pace mode when valid inputs:
- 5K predicted finish time
- 10K predicted finish time
- Half Marathon (21.0975 km) predicted finish time
- Marathon (42.195 km) predicted finish time
- Toggle with FilterChip

### History Management
- Save calculations to history (up to 10 entries)
- Load previous calculations from history
- Clear all history with confirmation dialog
- Entries persisted via SharedPreferences

## Data Models

### PaceHistoryEntry Class
```dart
class PaceHistoryEntry {
  final DateTime date;
  final String mode;
  final double distance;
  final int timeMinutes;
  final int timeSeconds;
  final String unit;
  final String result;
}
```

Methods:
- `toJson()`: Serializes entry to JSON string
- `fromJson(String)`: Deserializes entry from JSON string

### PaceModel Class
State management using ChangeNotifier pattern.

Properties:
- `mode`: Current calculation mode ('pace', 'time', 'distance')
- `distance`: Distance value
- `timeMinutes`: Minutes component of time/pace
- `timeSeconds`: Seconds component of time/pace
- `unit`: Current unit ('km' or 'mi')
- `totalSeconds`: Combined minutes + seconds
- `result`: Calculated result string
- `modeLabel`: Display label for current mode
- `inputLabel1/2`: Labels for input fields
- `predictedTimes`: List of predicted race times
- `history`: List of saved calculations
- `hasHistory`: Boolean indicating if history exists
- `isInitialized`: Boolean indicating initialization complete

Methods:
- `init()`: Initialize from SharedPreferences
- `refresh()`: Refresh state
- `setMode(mode)`: Change calculation mode
- `setDistance(value)`: Update distance
- `setTimeMinutes(value)`: Update minutes
- `setTimeSeconds(value)`: Update seconds
- `setUnit(unit)`: Change unit
- `clear()`: Reset all values
- `saveToHistory()`: Save current calculation
- `loadFromHistory(entry)`: Load previous calculation
- `clearHistory()`: Remove all history

## UI Components

### PaceCard
Main widget displaying:
- Mode selector (SegmentedButton: Pace, Time, Distance)
- Unit selector (SegmentedButton: km, mile)
- Input fields (distance and time/pace)
- Result display with mode label
- Race predictions toggle (FilterChip)
- Race predictions list (when enabled)
- Action buttons: Save, Clear
- History view toggle button
- Clear history button

### History View
- List of saved calculations with mode, result, and parameters
- Tap to load previous calculation
- Scrollable with max height constraint

### Clear History Confirmation
- AlertDialog with confirmation
- Cancel and Clear buttons

## Keywords

Searchable keywords for action:
- pace, run, running, calculator, time, distance, speed, marathon, race

## Material 3 Style

Uses Material 3 components:
- `Card.filled()` for main card
- `SegmentedButton` for mode and unit selection
- `TextField` with OutlineInputBorder for inputs
- `FilterChip` for race predictions toggle
- `ElevatedButton.icon` for action buttons
- `IconButton` for history and delete actions
- `AlertDialog` for confirmation dialog

## Testing

Test coverage includes:
- Provider existence and keywords
- Model state management
- Pace calculation (distance and time → pace)
- Time calculation (distance and pace → time)
- Distance calculation (pace and time → distance)
- Race predictions for standard distances
- History operations (save, load, clear)
- Widget rendering (loading, initialized, with data)

## SharedPreferences Keys

- `pace_history`: List of PaceHistoryEntry JSON strings

## Integration

Added to Global.providerList in `lib/data.dart`:
```dart
providerPace,
```

Total providers: 106