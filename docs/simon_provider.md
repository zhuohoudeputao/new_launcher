# Simon Provider Implementation

## Overview

The Simon provider implements a classic color sequence memory game for the Flutter launcher application. Players watch a sequence of colors and must repeat it correctly, with each successful round adding one more color.

## Implementation Details

### Location
- Provider: `lib/providers/provider_simon.dart`
- Tests: `test/widget_test.dart` (Simon provider tests group)

### Model: SimonModel

The `SimonModel` class extends `ChangeNotifier` and manages:

- **Game State**: Ready, showing sequence, waiting for input, or game over
- **Sequence**: List of colors the player must memorize and repeat
- **Player Input**: Tracking the player's attempts to match the sequence
- **Level**: Current sequence length (starts at 1, increments on success)
- **Highest Level**: Best score achieved across all games
- **Statistics**: Games played, games completed, completion rate
- **History**: Recent game entries (up to 10)

### Features

1. **Game States**
   - Ready: Initial state with Start button
   - Showing Sequence: Colors flash one at a time (600ms each)
   - Waiting Input: Player can tap colors to match sequence
   - Game Over: Player made a mistake, shows final level

2. **Sequence Generation**
   - Starts with one random color (red, green, blue, or yellow)
   - Each successful round adds one more random color
   - Sequence shown with pauses between colors

3. **Color Buttons**
   - 2x2 grid layout (180x180 total)
   - Colors: Red (top-left), Green (top-right), Blue (bottom-left), Yellow (bottom-right)
   - Active state shows bright color with white border
   - Inactive state shows dimmed color

4. **Input Handling**
   - Player taps colors while in waiting state
   - Correct input: Next color in sequence expected
   - Wrong input: Game ends immediately
   - Complete sequence: Level up, new color added

5. **Statistics**
   - Games played count
   - Games completed count (successful sequences)
   - Completion rate percentage
   - Reset stats option with confirmation dialog

6. **History**
   - Track up to 10 recent games
   - Store level reached, completion status, timestamp
   - Toggle history view

### Widget: SimonCard

The `SimonCard` widget displays:

- Level display with best level indicator
- 2x2 color button grid
- Status text (Watch sequence / Repeat sequence / Game Over)
- Start button (initial state) or Play Again button (after game over)
- Statistics row (Played, Completed, Rate)
- History toggle and reset stats buttons

### Keywords

`simon, memory, sequence, color, pattern, game, play, repeat`

## Material 3 Design

- `Card.filled` for card container
- `GridView` for 2x2 color button grid
- `GestureDetector` for color button tap detection
- Color coding: Red, Green, Blue, Yellow with active/inactive states
- `ElevatedButton` for Start/Play Again action
- `TextButton` for reset confirmation

## Tests

Test coverage includes:

- SimonGameEntry properties
- SimonModel default values
- SimonModel initialization
- Game start (adds first color, starts showing sequence)
- Game reset (returns to ready state)
- Statistics reset (clears all stats and history)
- History clearing
- Completion rate calculation
- History max limit (10 entries)
- Refresh notification
- SimonColor enum values (4 colors)
- SimonState enum values (4 states)
- Provider existence and keywords
- SimonCard rendering (loading, initialized states)
- Level display
- Provider in Global.providerList

## Game Algorithm

### Sequence Showing

1. Set state to showingSequence
2. For each color in sequence:
   - Set activeColor (600ms)
   - Clear activeColor (300ms pause)
3. Set state to waitingInput

### Input Validation

1. Player taps a color
2. Add to playerInput list
3. Compare with corresponding sequence color
4. If wrong: Game over
5. If all correct but not complete: Continue waiting
6. If all correct and complete: Level up, add new color, show sequence again

### Color Activation

- Active color: Full brightness with white border (3px)
- Inactive color: 60% alpha (dimmed)
- Animation handled with Timer for consistent timing

## Color Layout

The 2x2 grid follows classic Simon layout:
- Red (top-left) - topLeft
- Green (top-right) - topRight
- Blue (bottom-left) - bottomLeft
- Yellow (bottom-right) - bottomRight

## Future Enhancements

Potential improvements:

- Add difficulty levels (faster timing for hard mode)
- Add sound effects for each color
- Add statistics persistence via SharedPreferences
- Add high score leaderboard
- Add timed challenge mode
- Add multiplayer mode
- Customizable color themes