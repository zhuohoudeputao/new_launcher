# Stretch Reminder Provider Implementation

## Overview

The Stretch Reminder provider is a health-focused feature that reminds users to stretch after sitting for extended periods. This promotes better posture and health by encouraging regular movement.

## Features

- Configurable reminder interval (10, 15, 20, 30, 45, 60 minutes)
- Elapsed time display showing time since last stretch
- Progress bar visualization
- Visual warning when stretch time exceeded
- Daily stretch count tracking
- Start/stop timer controls
- "Stretched!" button to reset timer and increment count
- Clear statistics with confirmation dialog
- Stretch entries persisted via SharedPreferences

## Implementation Details

### Model: `StretchReminderModel`

The model manages the timer state and statistics:

```dart
class StretchReminderModel extends ChangeNotifier {
  Timer? _timer;
  int _intervalMinutes = 30;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  int _todayStretches = 0;
  DateTime? _lastStretchTime;
  DateTime? _sessionStartTime;
  bool _isInitialized = false;
}
```

### Key Properties

- `intervalMinutes`: Configurable interval in minutes (default: 30)
- `elapsedSeconds`: Time elapsed since timer started
- `isRunning`: Timer state
- `todayStretches`: Daily stretch count
- `lastStretchTime`: Timestamp of last stretch
- `sessionStartTime`: When the current session began

### Key Methods

- `init()`: Initialize model and load persisted data
- `start()`: Start the stretch reminder timer
- `stop()`: Stop the timer
- `reset()`: Reset timer and increment stretch count
- `setInterval(int minutes)`: Set reminder interval (5-120 range)
- `skipStretch()`: Skip current stretch reminder
- `clearStats()`: Clear all statistics

### Computed Properties

- `formattedElapsed`: Human-readable elapsed time (e.g., "5m 30s")
- `progressPercent`: Progress toward stretch reminder (0.0-1.0)
- `needsStretch`: Boolean indicating if stretch time exceeded

### Widget: `StretchReminderCard`

The card displays:
- Timer with elapsed time
- Progress bar showing progress toward reminder
- Interval selector with ActionChips
- Start/Stop controls
- "Stretched!" button for marking completion
- Daily stretch count
- Clear statistics button

## Persistence

All data is persisted via SharedPreferences:

- `StretchReminder.interval`: Interval setting
- `StretchReminder.todayStretches`: Daily stretch count
- `StretchReminder.lastStretchTime`: Last stretch timestamp
- `StretchReminder.sessionStartTime`: Session start timestamp

## Day Reset Logic

The model automatically resets `todayStretches` to 0 when:
- A new day starts (year, month, or day changes)

## UI Components

- `Card.filled` for Material 3 styling
- `LinearProgressIndicator` for progress visualization
- `ActionChip` for interval selection
- `ElevatedButton` for start/stop/reset controls
- Warning container when stretch time exceeded

## Keywords

`stretch, reminder, health, fitness, break, sit, posture, exercise, move, standup`

## Tests

Tests cover:
- Model initialization
- Start/stop timer operations
- Reset operations
- Interval setting (valid and invalid)
- Skip stretch functionality
- Clear statistics
- Formatted elapsed time display
- Progress percentage calculation
- Needs stretch detection
- Widget rendering
- Provider existence in Global.providerList