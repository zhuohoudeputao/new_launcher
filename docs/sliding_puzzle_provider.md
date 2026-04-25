# Sliding Puzzle Provider

## Overview

The Sliding Puzzle provider implements the classic 15-puzzle game (also known as sliding puzzle or tile puzzle). Players slide numbered tiles on a 4x4 grid to arrange them in order from 1 to 15, with one empty space.

## Implementation

### File Location
`lib/providers/provider_sliding_puzzle.dart`

### Model: `SlidingPuzzleModel`

The model manages the game state including:
- Tile positions on the 4x4 grid
- Current move count
- Solved state detection
- Difficulty levels
- Game statistics (games played, won, best moves)
- History tracking

### Features

1. **Classic 15-Puzzle Game**
   - 4x4 grid with tiles numbered 1-15
   - One empty space for sliding tiles
   - Goal: arrange tiles in order from left to right, top to bottom

2. **Difficulty Levels**
   - Easy (1): 50 shuffle moves
   - Medium (2): 100 shuffle moves
   - Hard (3): 150 shuffle moves

3. **Game Mechanics**
   - Tap adjacent tiles to slide them into the empty space
   - Only tiles adjacent to the empty space can be moved
   - Automatic solvability check (ensures puzzle is always solvable)

4. **Statistics Tracking**
   - Total games played
   - Games won count
   - Best moves record
   - Win rate percentage

5. **History**
   - Tracks up to 10 recent games
   - Shows moves, completion status, difficulty, and timestamp
   - Human-readable time format (just now, Xm ago, Xh ago, Xd ago)

### Algorithm Details

**Shuffle Algorithm:**
- Uses random legal moves to shuffle the puzzle
- Starts from solved state and performs shuffle moves based on difficulty
- Ensures puzzle is always solvable by checking parity

**Solvability Check:**
- Counts inversions (number of pairs where larger number precedes smaller)
- Combined with empty tile row position determines solvability
- Adjusts puzzle if initially unsolvable

### UI Components

**`SlidingPuzzleCard`**
- Material 3 `Card.filled` design
- 180x180 pixel game grid
- Movable tiles highlighted with color
- SegmentedButton for difficulty selection
- Info row showing moves, best moves, games won, win rate
- History toggle button
- New Game and Give Up buttons

### Keywords
`sliding, puzzle, 15, slide, tile, game, arrange`

## Tests

Tests are located in `test/widget_test.dart` under the 'SlidingPuzzle provider tests' group.

### Test Coverage
- Model initialization
- New game reset
- Difficulty setting
- Tile movement validation
- Move counting
- Give up functionality
- Difficulty name formatting
- Time formatting
- History limits (max 10 entries)
- History clearing
- Stats reset
- Win rate calculation
- History entry data storage
- Card widget rendering (loading, initialized states)
- Provider list inclusion
- Provider count verification

## Model Details

### Properties
- `tiles`: List of 16 integers representing tile positions (0 = empty)
- `emptyIndex`: Position of the empty tile
- `moves`: Number of moves made
- `isSolved`: Whether puzzle is solved
- `difficulty`: Current difficulty level (1-3)
- `gamesPlayed`: Total games played
- `gamesWon`: Total games won
- `bestMoves`: Best (lowest) moves to solve
- `history`: List of game history entries
- `winRate`: Win rate percentage

### Methods
- `init()`: Initialize model
- `newGame()`: Start a new shuffled puzzle
- `setDifficulty(int)`: Change difficulty and start new game
- `canMove(int)`: Check if a tile can be moved
- `moveTile(int)`: Move a tile to empty space
- `giveUp()`: Give up current game
- `resetStats()`: Reset all statistics
- `clearHistory()`: Clear game history
- `getDifficultyName()`: Get difficulty name string
- `formatTimeAgo(DateTime)`: Format timestamp to human-readable

## Integration

The provider is registered in:
- `lib/data.dart`: Import and provider list
- `lib/main.dart`: Import and MultiProvider

Total providers: 113 (including SlidingPuzzle)