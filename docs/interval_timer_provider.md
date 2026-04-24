# Interval Timer Provider Implementation

## Overview

The Interval Timer provider implements a HIIT/Tabata workout timer with customizable work and rest intervals. This is different from the existing Timer (single countdown) and Pomodoro (fixed work/break cycles) providers.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_interval_timer.dart`
- Tests: `test/widget_test.dart` (Interval Timer provider tests group)

### Model Class: `IntervalTimerModel`

The `IntervalTimerModel` extends `ChangeNotifier` and manages:
- Work duration (5-300 seconds)
- Rest duration (0-120 seconds)
- Sets count (1-20 rounds)
- Current phase (work/rest)
- Current set number
- Remaining seconds in current phase
- Running/paused state

### Presets

Five preset configurations are provided:
1. **Tabata**: 20s work, 10s rest, 8 sets
2. **HIIT 30/10**: 30s work, 10s rest, 8 sets
3. **HIIT 45/15**: 45s work, 15s rest, 6 sets
4. **Circuit**: 60s work, 30s rest, 5 sets
5. **EMOM**: 60s work, 0s rest, 10 sets

### Key Methods

- `applyPreset(IntervalPreset preset)`: Apply a preset configuration
- `setWorkDuration(int seconds)`: Set work duration (5-300s)
- `setRestDuration(int seconds)`: Set rest duration (0-120s)
- `setSets(int count)`: Set number of rounds (1-20)
- `start()`: Start the timer
- `pause()`: Pause the running timer
- `resume()`: Resume a paused timer
- `stop()`: Stop and reset the timer
- `skipPhase()`: Skip to the next phase/set
- `_advancePhase()`: Internal method to advance phase when time expires

### UI Components

- `IntervalTimerCard`: Main card displaying timer interface
- Setup mode: Shows presets, duration/set controls
- Running mode: Circular progress indicator, phase indicator, total progress

### Material 3 Components Used

- `Card.filled()` for main card container
- `CircularProgressIndicator` for phase countdown
- `LinearProgressIndicator` for total progress
- `ActionChip` for preset selection
- `ElevatedButton` and `TextButton` for controls

## Integration

### Provider Registration

Added to `Global.providerList` in `lib/data.dart`:
```dart
providerIntervalTimer,
```

### MultiProvider Registration

Added to `MultiProvider` in `lib/main.dart`:
```dart
ChangeNotifierProvider.value(value: intervalTimerModel),
```

### Search Keywords

Keywords: `interval, timer, hiit, tabata, workout, circuit, training`

## Testing

25 tests covering:
- Model initialization
- Preset configuration
- Duration/sets setting
- Timer operations (start, pause, resume, stop)
- Phase advancement
- Skip phase functionality
- Widget rendering (setup and running states)
- Provider registration verification

## Bug Fix

During implementation, a critical bug was fixed where `start()` called `resetToStart()` which set `isRunning = false`, immediately after setting `isRunning = true`. This was resolved by creating a separate `_resetToRunning()` method that doesn't modify `isRunning`.

## Usage

1. Open the launcher
2. Type "hiit" or "tabata" to find the Interval Timer
3. Select a preset or customize durations/sets
4. Press Start to begin workout
5. Use Pause/Resume controls during workout
6. Use Skip to advance to next phase
7. Use Stop to reset and return to setup mode