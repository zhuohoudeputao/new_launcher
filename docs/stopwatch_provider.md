# Stopwatch Provider Documentation

## Overview

The Stopwatch provider adds elapsed time tracking functionality to the launcher. Unlike the Timer provider which counts down, the Stopwatch counts up to track elapsed time with lap recording capability.

## Implementation Details

### Components

1. **StopwatchModel** (`lib/providers/provider_stopwatch.dart`)
   - Manages stopwatch state (elapsed time, running status)
   - Timer with 10ms precision for smooth display updates
   - Lap recording with time splits
   - Maximum 20 laps to prevent memory issues

2. **StopwatchCard** (`lib/providers/provider_stopwatch.dart`)
   - Material 3 Card.filled style
   - Large time display with monospace font
   - Start/Pause/Lap buttons
   - Lap history view toggle
   - Reset confirmation dialog

3. **LapEntry** class
   - Stores lap number, elapsed time, lap time split
   - Formatted display strings for elapsed and lap time
   - Timestamp for each lap

### Features

- **Start**: Begin counting elapsed time
- **Pause**: Stop the stopwatch while preserving elapsed time
- **Resume**: Continue counting from paused state
- **Lap**: Record a time split while stopwatch continues
- **Reset**: Clear all data and return to initial state
- **Clear Laps**: Remove lap history while keeping elapsed time

### Display Format

Time is displayed in format: `MM:SS.ms` (minutes, seconds, centiseconds)
- For hours: `H:MM:SS.ms`

Example displays:
- `00:00.00` - Initial state
- `01:23.45` - 1 minute, 23 seconds, 45 centiseconds
- `1:05:30.12` - 1 hour, 5 minutes, 30 seconds, 12 centiseconds

### Lap Recording

Each lap entry shows:
- Lap number (#1, #2, etc.)
- Lap split time (time for that specific lap)
- Total elapsed time at lap

Laps are inserted at the beginning of the list (most recent first).
Maximum 20 laps can be recorded.

### Keywords

- `stopwatch`
- `lap`
- `elapsed`
- `time`
- `clock`

### Usage Flow

1. User taps "Start" button
2. Stopwatch begins counting with 10ms precision
3. User can tap "Lap" to record time splits
4. User can tap "Pause" to stop counting
5. Tapping "Resume" continues from paused time
6. Tapping "Reset" clears all data (with confirmation)

### Code Example

```dart
// Access stopwatch model
final stopwatch = stopwatchModel;

// Start the stopwatch
stopwatch.start();

// Record a lap
stopwatch.lap();

// Pause the stopwatch
stopwatch.pause();

// Resume from pause
stopwatch.start();

// Reset everything
stopwatch.reset();

// Check state
if (stopwatch.isRunning) { }
if (stopwatch.isStarted) { }
if (stopwatch.hasLaps) { }
```

### Model Properties

- `elapsedMilliseconds`: Total elapsed time in milliseconds
- `isRunning`: Whether stopwatch is currently counting
- `isStarted`: Whether stopwatch has been started (elapsed > 0 or running)
- `isInitialized`: Whether provider has been initialized
- `hasLaps`: Whether any laps have been recorded
- `laps`: List of LapEntry objects
- `displayTime`: Formatted string for current elapsed time

### Integration with Providers System

The Stopwatch provider follows the standard provider pattern:

```dart
MyProvider providerStopwatch = MyProvider(
    name: "Stopwatch",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

Added to `Global.providerList` in `lib/data.dart`.
Model registered in `MultiProvider` in `lib/main.dart`.

## Related Features

- **Timer Provider**: Countdown functionality (complementary feature)
- **Time Provider**: Current time display
- **Calculator Provider**: Quick calculations

## Testing

Tests are located in `test/widget_test.dart` under the "Stopwatch provider tests" group:
- Model initialization and state management
- Start/pause/reset functionality
- Lap recording and limits
- Display time formatting
- Widget rendering tests
- Provider registration tests

## Notes

- Stopwatch uses Timer.periodic with 10ms interval for smooth updates
- Reset requires confirmation dialog to prevent accidental data loss
- Lap button disabled when stopwatch not started
- Most recent laps appear first in the list