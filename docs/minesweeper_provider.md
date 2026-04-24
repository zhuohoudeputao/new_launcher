# Minesweeper Provider Implementation

## Overview

The Minesweeper provider implements the classic Minesweeper puzzle game in the Flutter launcher application. Players must reveal all non-mine cells while avoiding hidden mines, using numbered cells to determine adjacent mine locations.

## Implementation Details

### File Location
`lib/providers/provider_minesweeper.dart`

### Provider Registration
The provider is registered in `lib/data.dart`:
```dart
import 'package:new_launcher/providers/provider_minesweeper.dart';
// ...
providerMinesweeper,
```

### Model Class: MinesweeperModel

#### State Properties
- `_grid`: 2D grid of MinesweeperCell objects
- `_gridRows`, `_gridCols`: Grid dimensions (8x8, 10x10, 12x12)
- `_totalMines`: Number of mines (10, 20, 35)
- `_difficulty`: Current difficulty level (easy, medium, hard)
- `_revealedCount`: Number of revealed cells
- `_flaggedCount`: Number of flagged cells
- `_isGameOver`: Game ended state
- `_isWin`: Win/loss outcome
- `_firstClick`: First click made (mines placed after first click)
- `_gamesPlayed`, `_gamesWon`: Statistics
- `_bestTimeEasy`, `_bestTimeMedium`, `_bestTimeHard`: Best times per difficulty
- `_history`: Game history entries (max 10)
- `_elapsedSeconds`: Game timer

#### Key Methods
- `init()`: Initialize model and load persisted data
- `newGame()`: Start new game with current difficulty
- `setDifficulty()`: Change difficulty and restart game
- `revealCell()`: Reveal a cell (recursive for empty cells)
- `toggleFlag()`: Toggle flag on a cell
- `resetStats()`: Reset all statistics
- `clearHistory()`: Clear game history
- `_placeMines()`: Place mines avoiding first click area
- `_calculateAdjacentMines()`: Calculate mine counts for each cell
- `_revealCellRecursive()`: Flood fill reveal for empty cells

### Cell Class: MinesweeperCell

#### Properties
- `row`, `col`: Cell position
- `isMine`: Whether cell contains a mine
- `adjacentMines`: Number of adjacent mines (0-8)
- `state`: Cell state (hidden, revealed, flagged, exploded)

### Difficulty Levels

| Level | Grid Size | Mines | Safe Cells |
|-------|-----------|-------|------------|
| Easy  | 8x8       | 10    | 54         |
| Medium| 10x10     | 20    | 80         |
| Hard  | 12x12     | 35    | 109        |

### UI Components: MinesweeperCard

#### Features
- Difficulty selector (SegmentedButton)
- Game grid with tap reveal and long-press flag
- Info row (time, remaining flags, progress)
- Statistics display (wins, win rate, best time)
- History view toggle
- Clear history confirmation dialog

#### Visual Elements
- Hidden cells: SurfaceContainerHighest color
- Flagged cells: TertiaryContainer color
- Revealed cells: Surface color with number indicators
- Exploded cells: ErrorContainer color
- Number colors: Blue (1), Green (2), Red (3), Purple (4), etc.

### Game Logic

#### Mine Placement
Mines are placed after the first click to ensure the first click is always safe. The mine placement avoids:
- The clicked cell
- All 8 adjacent cells around the first click

#### Recursive Reveal
When a cell with 0 adjacent mines is revealed, all adjacent cells are automatically revealed recursively until reaching cells with adjacent mines.

#### Win Condition
All safe cells (total cells - mines) must be revealed.

#### Loss Condition
Any mine cell is clicked/revealed.

### Persistence
Statistics and history are saved using SharedPreferences:
- `minesweeper_gamesPlayed`
- `minesweeper_gamesWon`
- `minesweeper_bestTimeEasy`
- `minesweeper_bestTimeMedium`
- `minesweeper_bestTimeHard`
- `minesweeper_history` (JSON string list)

## Testing

### Test Coverage
Located in `test/widget_test.dart` under 'Minesweeper provider tests' group:

- MinesweeperCell properties test
- MinesweeperGameEntry properties test
- MinesweeperModel default values test
- MinesweeperModel initialization test
- Difficulty switching test
- Grid dimensions and mine count tests
- Difficulty text/label/color tests
- Time formatting test
- Win rate and progress calculation tests
- Statistics reset and history clear tests
- Provider existence and keywords tests
- Widget rendering tests (loading state, initialized state, grid, difficulty selector, new game button)

### Total Tests: 25

## Usage Example

```dart
// Access Minesweeper model
minesweeperModel.init();

// Start new game
minesweeperModel.newGame();

// Change difficulty
minesweeperModel.setDifficulty(MinesweeperDifficulty.medium);

// Reveal cell (row, col)
minesweeperModel.revealCell(3, 4);

// Toggle flag
minesweeperModel.toggleFlag(2, 5);
```

## Keywords
`minesweeper mine bomb puzzle grid reveal flag game`