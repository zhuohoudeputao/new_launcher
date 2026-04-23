# Meditation Provider Implementation

## Overview

The Meditation Timer provider provides a focused meditation timer with breathing guide support. Users can start meditation sessions with preset or custom durations, track their progress, and view session history.

## Features

### Core Features
- Preset durations: 1, 3, 5, 10, 15, 20, 30 minutes
- Start/pause/resume controls
- Visual circular progress indicator
- Session completion tracking
- Total meditation time display

### Breathing Guide
- Optional breathing guide (4-4-4-4 pattern)
- Four phases: Inhale, Hold, Exhale, Rest
- Visual phase indicator during meditation
- Toggle on/off before starting

### Session History
- Track completed sessions (up to 20 entries)
- Display time ago for each session
- Total minutes accumulated
- Session count display
- Clear history with confirmation

## Implementation

### File Structure
- `lib/providers/provider_meditation.dart` - Main provider implementation

### Classes

#### MeditationModel
State management class extending `ChangeNotifier`:
- `state`: Current meditation state (idle, running, paused, completed)
- `durationMinutes`: Selected meditation duration
- `remainingSeconds`: Countdown timer
- `progress`: Percentage of session completed
- `formattedTime`: MM:SS format display
- `history`: List of completed sessions
- `totalMinutes`: Total meditation time accumulated
- `sessionCount`: Number of completed sessions
- `breathingEnabled`: Toggle for breathing guide
- `breathingPhase`: Current breathing phase
- `breathingCount`: Breathing cycle count

#### MeditationSession
Data class for session history:
- `durationMinutes`: Session duration
- `completedAt`: Completion timestamp
- `breathingPattern`: Pattern used (e.g., '4-4-4-4')

#### MeditationCard
Main UI widget with:
- Idle state: Duration selection, breathing toggle, history access
- Running state: Progress indicator, controls
- Paused state: Pause indicator, resume option
- Completed state: Success message, new session button

### Key Methods

#### MeditationModel
- `init()`: Initialize from SharedPreferences
- `startMeditation(minutes)`: Begin meditation session
- `pauseMeditation()`: Pause running session
- `resumeMeditation()`: Resume paused session
- `cancelMeditation()`: Cancel and return to idle
- `reset()`: Return to idle state
- `setBreathingEnabled(bool)`: Toggle breathing guide
- `clearHistory()`: Clear all session history

### State Management
Uses `ChangeNotifierProvider` for state:
```dart
ChangeNotifierProvider.value(
  value: meditationModel,
  child: MeditationCard(),
)
```

## UI Components

### Material 3 Components
- `Card.filled` for main container
- `CircularProgressIndicator` for progress
- `ActionChip` for duration selection
- `IconButton` with `IconButton.styleFrom()`
- `AlertDialog` for history view

### Visual Elements
- Circular progress indicator with percentage
- Phase text for breathing guide
- Time display in MM:SS format
- Session completion icon

## Keywords
- meditation, meditate, relax, breath, calm, focus, zen, mindfulness

## Storage

### SharedPreferences Keys
- `meditation_history`: JSON list of sessions
- `meditation_total_minutes`: Total accumulated minutes

### Limits
- Maximum history entries: 20
- Oldest entry removed when limit exceeded

## Testing

Tests cover:
- Model initialization and state
- Start/pause/resume/cancel operations
- Progress calculation
- Formatted time display
- Breathing toggle functionality
- History clear functionality
- Session serialization
- Widget rendering states
- Provider existence and keywords
- Enum values verification

## Integration

Added to `Global.providerList` in `lib/data.dart`:
```dart
providerMeditation,
```

Import added:
```dart
import 'package:new_launcher/providers/provider_meditation.dart';
```

## Usage

### Starting Meditation
1. Select duration from preset chips (1m, 3m, 5m, 10m, 15m, 20m, 30m)
2. Optionally enable breathing guide
3. Timer starts automatically

### During Meditation
- Circular progress shows completion percentage
- Pause button to pause session
- Stop button to cancel session
- Breathing phase indicator if enabled

### After Completion
- Success message displayed
- Session added to history
- Total minutes updated
- "New Session" button to start another

### Viewing History
- Tap "History" button when sessions exist
- View list of completed sessions
- Clear all with confirmation dialog