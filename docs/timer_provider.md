# Timer Provider Implementation

## Overview

The Timer provider adds countdown timer functionality to the launcher, allowing users to quickly set and manage timers directly from the main card list.

## Features

- Quick preset timers (1, 5, 10, 15, 30 minutes)
- Custom timer input
- Pause/resume timer functionality
- Clear all timers
- Timer completion notification via SnackBar
- Maximum 5 concurrent timers
- Visual countdown display with progress indicator

## Implementation

### File Structure

- `lib/providers/provider_timer.dart` - Timer provider implementation

### Components

#### TimerModel

Manages timer state and provides methods for timer operations:

```dart
class TimerModel extends ChangeNotifier {
  List<TimerEntry> _timers = [];
  static const int maxTimers = 5;
  
  void addTimer(int seconds, {String label = ''});
  void addQuickTimer(int minutes);
  void cancelTimer(String id);
  void pauseTimer(String id);
  void resumeTimer(String id);
  void clearAllTimers();
}
```

#### TimerEntry

Represents a single timer with its state:

```dart
class TimerEntry {
  final String id;
  final int totalSeconds;
  int remainingSeconds;
  Timer? timer;
  bool isActive;
  final String label;
  
  String get displayTime;      // Formatted remaining time
  String get totalDisplayTime; // Formatted total duration
  double get progress;         // Progress ratio (0.0 - 1.0)
}
```

#### TimerCard

Widget displaying the timer interface:

- Quick timer buttons (ActionChip)
- Custom timer input (TextField)
- Active timers list with pause/resume/cancel controls
- Circular progress indicator for each timer

#### AddTimerDialog

Dialog for adding custom timers with:
- Minutes input field
- Optional label input

## UI Design

### Card Style

Uses Material 3 `Card.filled` with:
- Transparent background via `Theme.of(context).cardColor`
- Compact layout with `mainAxisSize: MainAxisSize.min`
- ActionChips for quick timer buttons

### Timer Display

Each active timer shows:
- CircularProgressIndicator showing remaining percentage
- Countdown time display (MM:SS or HH:MM:SS)
- Timer label or duration
- Pause/Resume button (when applicable)
- Cancel button (red colored)

### Time Formatting

- Less than 1 hour: `MM:SS` (e.g., `5:30`)
- 1 hour or more: `H:MM:SS` (e.g., `1:05:30`)

## Timer Completion

When a timer completes:
- Timer is marked inactive
- SnackBar notification appears with "Timer completed" message
- Dismiss action available
- Timer remains in list until manually cleared

## Keywords

The timer provider registers the following keywords:
- timer
- countdown
- alarm
- clock
- time

## Logging

All timer operations are logged:
- Timer added: `{duration}`
- Timer paused
- Timer resumed
- Timer cancelled
- Timer completed: `{label or duration}`
- All timers cleared
- Timer limit reached warning

## Testing

Test coverage includes:
- TimerModel initialization
- Timer addition with labels
- Quick timer conversion
- Timer limit enforcement
- Timer cancellation
- Pause/resume functionality
- TimerEntry display formatting
- Progress calculation
- Widget rendering tests

Total: 22 timer-related tests

## Integration

### Provider Registration

Added to `Global.providerList` in `lib/data.dart`:
```dart
static List<MyProvider> providerList = [
  ...
  providerTimer,
];
```

### MultiProvider Setup

Added to providers in `lib/main.dart`:
```dart
ChangeNotifierProvider.value(value: timerModel),
```

## User Workflow

1. Quick timer: Tap preset button (1m, 5m, etc.)
2. Custom timer: Enter minutes in text field or use dialog
3. Active timers: View countdown with progress ring
4. Pause timer: Tap pause button
5. Resume timer: Tap play button
6. Cancel timer: Tap X button
7. Clear all: Tap clear all button with confirmation