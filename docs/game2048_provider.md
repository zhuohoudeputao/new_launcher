# Game2048 Provider Implementation

## Overview

The Game2048 provider implements a classic 2048 number puzzle game for the Flutter launcher application.

## Implementation Details

### Location
- Provider: `lib/providers/provider_2048.dart`
- Tests: `test/widget_test.dart` (Game2048 provider tests group)

### Model: Game2048Model

The `Game2048Model` class extends `ChangeNotifier` and manages:

- **Grid State**: 4x4 grid with tiles containing powers of 2
- **Score Tracking**: Accumulated score from merging tiles
- **Highest Tile**: Maximum tile value during gameplay
- **Move Count**: Total moves made
- **Game Over Detection**: No valid moves remaining
- **Win Detection**: Reaching 2048 tile
- **Statistics**: Best score, best tile, games played, games won
- **History**: Recent game entries (up to 10)

### Features

1. **Tile Movement**
   - Move tiles in 4 directions (up, down, left, right)
   - Tiles slide to edge in chosen direction
   - Same-value tiles merge when they collide
   - New tile (2 or 4) appears after each valid move

2. **Tile Merging**
   - Merge tiles of same value when adjacent
   - Merged value = sum of two tiles (doubles)
   - Score increases by merged value
   - Update highest tile if new record

3. **Game State Detection**
   - Win: Any tile reaches 2048 or higher
   - Game Over: Grid full with no valid merges
   - Check horizontal and vertical adjacency for possible merges

4. **Statistics**
   - Best score: Highest score achieved across sessions
   - Best tile: Maximum tile value achieved
   - Games played: Total games started
   - Games won: Games where 2048 was reached

5. **History**
   - Track up to 10 recent games
   - Store score, highest tile, completion status, moves
   - Timestamp for each entry

### Widget: Game2048Card

The `Game2048Card` widget displays:

- Info row (Score, Best, Moves, Tile)
- 4x4 tile grid with color-coded values
- Direction control buttons (Up, Down, Left, Right)
- New Game button
- Statistics and history toggle

### Tile Colors

Color scheme based on tile value:
- 0: Empty (surfaceContainerHighest)
- 2, 4: Light gray
- 8, 16, 32, 64: Orange gradient
- 128, 256, 512: Yellow gradient
- 1024, 2048: Amber
- >2048: Purple

### Keywords

`2048, game, puzzle, number, tile, slide, merge`

## Material 3 Design

- `Card.filled` for card container
- `GridView` for tile grid
- `IconButton` for direction controls
- `ElevatedButton` for New Game action
- Color-coded tiles with Material 3 colors

## Tests

Test coverage includes:

- Game2048Entry properties
- Game2048Model default values
- Game2048Model initialization
- Grid dimensions (4x4)
- New game state reset
- Move operations
- Tile color retrieval
- Tile text color retrieval
- Time ago formatting
- History checking
- Statistics reset
- History clearing
- History max limit
- Refresh notification
- Provider existence and keywords
- Game2048Card rendering (loading, initialized states)
- Grid display
- Control buttons display
- Direction enum values

## Algorithm Details

### Tile Movement

1. Extract non-zero tiles from row/column
2. Merge adjacent tiles of same value
3. Pad with zeros to maintain grid size
4. Update score and highest tile
5. Add new random tile if move was valid

### Merge Algorithm

For each line (row/column):
1. Iterate through non-zero tiles
2. If adjacent tiles have same value:
   - Merge them (double the value)
   - Skip next tile
   - Add merged value to score
3. Otherwise, keep tile unchanged

### New Tile Placement

- Find all empty cells
- Randomly select one empty cell
- Place 2 (90% chance) or 4 (10% chance)

### Game Over Check

1. Check for empty cells
2. If no empty cells:
   - Check horizontal merges (adjacent columns)
   - Check vertical merges (adjacent rows)
   - No possible merges = Game Over

## Future Enhancements

Potential improvements:

- Add SharedPreferences persistence for statistics
- Add gesture-based controls (swipe)
- Add undo functionality
- Add different grid sizes (5x5, 6x6)
- Add timed challenge mode
- Add achievement system
- Add sound effects for merging