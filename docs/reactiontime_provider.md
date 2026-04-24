# Reaction Time Provider Implementation

## Overview

The Reaction Time provider measures and tracks user response speed. It displays a visual signal after a random delay and measures how quickly the user taps. The provider tracks best time, average time, and maintains a history of recent attempts.

## Implementation Details

### Provider File: `lib/providers/provider_reactiontime.dart`

### Model: `ReactionTimeModel`

The model manages reaction time testing with:
- **Random Delay**: 1-5 seconds before the "GO" signal appears
- **Measurement**: Milliseconds between signal and user tap
- **History Tracking**: Up to 10 recent attempts

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isInitialized` | `bool` | Whether the model has been initialized |
| `state` | `ReactionState` | Current testing state (waiting, ready, go, result, early) |
| `lastReactionTime` | `int?` | Most recent reaction time in milliseconds |
| `bestTime` | `int?` | Best (lowest) reaction time recorded |
| `averageTime` | `double?` | Average reaction time across all history |
| `attemptCount` | `int` | Total number of completed attempts |
| `history` | `List<int>` | List of recent reaction times (max 10) |
| `hasHistory` | `bool` | Whether history contains any entries |

#### States

| State | Description |
|-------|-------------|
| `waiting` | Timer running, waiting for signal |
| `ready` | Ready to start a new test |
| `go` | Signal shown, waiting for user tap |
| `result` | Result displayed, ready for next test |
| `early` | User tapped too early, retry needed |

#### Methods

| Method | Description |
|--------|-------------|
| `init()` | Initialize the model |
| `refresh()` | Notify listeners without changing state |
| `startTest()` | Handle tap based on current state |
| `reset()` | Clear all data and reset to initial state |
| `clearHistory()` | Clear history while keeping current stats |
| `requestFocus()` | Request focus for quick access |

### Widget: `ReactionTimeCard`

The card displays:
- Circular button with color-coded state
- Statistics row (best time, average time, attempts)
- Result display when test completed
- "Too early" warning when user taps prematurely
- History view toggle showing recent attempts
- Clear history button with confirmation

### UI Components

- **Reaction Button**: Circular button with color-coded state
  - Waiting: Primary container color, "Wait..." text
  - GO: Primary color, "TAP!" text
  - Result: Secondary container, displays time in ms
  - Early: Error container, "Try Again" text
- **Stats Row**: Best time (trophy icon), average (bar chart icon), attempts count
- **History View**: List of recent times with best time marked

### Material 3 Components Used

- `Card.filled()` - Main card container
- `GestureDetector` - Tap detection for reaction button
- `Container` with `BoxShape.circle` - Circular button styling
- `Icon` with `timer`, `emoji_events`, `bar_chart`, `repeat` - Stat icons
- `ListTile` - History entries
- `AlertDialog` - Clear history confirmation

## Testing

Tests are located in `test/widget_test.dart` under the `ReactionTime Provider tests` group:

- Provider existence in Global.providerList
- Model initialization
- Initial state is waiting
- Initial values are null
- Constants validation (maxHistory, minDelayMs, maxDelayMs)
- hasHistory property
- reset clears all data
- clearHistory clears history
- requestFocus sets shouldFocus
- Keywords validation (reaction, reflex, speed, tap)
- Global.providerList includes ReactionTime
- Widget rendering (loading and initialized states)
- Waiting state display
- Stats row display
- ReactionState enum validation

Total tests: 26 tests for ReactionTime provider

## Keywords

The provider registers keywords for search:
- reaction, time, reflex, speed, test, tap, quick, fast, response

## Integration

The provider is integrated into the app through:
- `lib/data.dart`: Import and provider list registration
- `lib/main.dart`: Import and MultiProvider registration

## Usage Example

Users can:
1. Tap the circular button to start a test
2. Wait for the button to turn green (random 1-5 second delay)
3. Tap quickly when the button turns green
4. View their reaction time in milliseconds
5. Track best time with trophy indicator
6. View average time across all attempts
7. See attempt count
8. Toggle history view to see recent times
9. Clear all history with confirmation dialog

## State Flow

1. Initial state: `waiting`
2. User taps: Timer starts with random delay
3. Delay expires: State changes to `go` (green button)
4. User taps in `go` state: Time recorded, state changes to `result`
5. User taps in `result` state: New test begins
6. User taps during `waiting`: State changes to `early` (too early warning)
7. User taps in `early` state: Returns to `waiting` for retry