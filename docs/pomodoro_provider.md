# Pomodoro Provider Implementation

## Overview

The Pomodoro provider implements a productivity timer based on the Pomodoro Technique, helping users manage work sessions and breaks.

## Features

- Work sessions (default 25 minutes)
- Short breaks (default 5 minutes after each work session)
- Long breaks (default 15 minutes after 4 work sessions)
- Circular progress indicator
- Session counter tracking completed pomodoros
- Session history (up to 20 entries)
- Customizable durations via settings dialog
- Pause/resume controls
- Skip current phase option
- Material 3 design with phase-specific colors

## Implementation Details

### PomodoroPhase Enum

```dart
enum PomodoroPhase { work, shortBreak, longBreak }
```

Three phases representing the Pomodoro cycle:
- **work**: Productivity session
- **shortBreak**: Brief rest after work session
- **longBreak**: Extended rest after 4 work sessions

### PomodoroSession Class

Tracks completed sessions with:
- `startTime`: When the session started
- `phase`: Type of session (work/break)
- `durationMinutes`: Session duration
- JSON serialization for persistence

### PomodoroModel

State management class with:
- Default durations: 25/5/15 minutes
- `sessionsBeforeLongBreak`: 4 sessions trigger long break
- Timer management with proper disposal handling
- SharedPreferences persistence for settings and history

#### Key Methods

- `init()`: Initialize model, load settings and history
- `start()`: Begin timer countdown
- `pause()`: Pause running timer
- `resume()`: Resume paused timer
- `stop()`: Stop timer and reset remaining time
- `skip()`: Skip to next phase
- `updateSettings()`: Change durations
- `resetCompletedSessions()`: Clear session counter
- `clearHistory()`: Delete session history
- `formatTime()`: Format remaining time as MM:SS
- `getProgress()`: Calculate progress percentage
- `getPhaseLabel()`: Get human-readable phase name
- `getPhaseIcon()`: Get phase-specific icon
- `getPhaseColor()`: Get phase-specific color

### PomodoroCard Widget

Displays:
- Phase indicator with icon and label
- Circular progress indicator
- Remaining time display
- Completed session counter
- Control buttons (start/pause/resume, skip, stop/reset)
- Settings and history toggle buttons

#### History View

- Lists completed sessions with phase, duration, and time
- Clear history button with confirmation dialog
- Maximum 20 entries stored

#### Settings Dialog

- Work duration slider (1-60 minutes)
- Short break slider (1-15 minutes)
- Long break slider (5-30 minutes)
- Duration picker with visual feedback

## Material 3 Design

- `Card.filled()` for timer display
- Phase-specific color scheme:
  - Work: `colorScheme.primary`
  - Short Break: `colorScheme.tertiary`
  - Long Break: `colorScheme.secondary`
- Icons: work (Icons.work), short break (Icons.coffee), long break (Icons.weekend)
- Circular progress indicator with phase colors
- ElevatedButton with phase-specific background

## Persistence

Settings stored as comma-separated string:
```dart
'$workDuration,$shortBreakDuration,$longBreakDuration'
```

History stored as pipe-separated list:
```dart
'startTime|phaseIndex|durationMinutes'
```

## Keywords

- pomodoro
- timer
- productivity
- work
- break
- focus
- session

## Testing

Tests cover:
- Provider existence and registration
- Phase enum values
- Session serialization
- Default values
- Initialization
- Timer controls (start/pause/resume/stop)
- Time formatting
- Progress calculation
- Phase labels, icons, colors
- Settings updates
- History management
- Maximum limits

## Usage

The Pomodoro card appears in the main launcher list. Users can:
1. Tap "Start" to begin a work session
2. Pause/resume during a session
3. Skip to move to the next phase
4. Stop to reset and return to work phase
5. Tap settings icon to adjust durations
6. Toggle history view to see completed sessions
7. Clear history with confirmation

## Future Enhancements

Potential improvements:
- Notification when session completes
- Daily/weekly statistics
- Sound alerts
- Background timer continuation
- Export session data