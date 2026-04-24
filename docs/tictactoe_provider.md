# TicTacToe Provider Implementation

## Overview

The TicTacToe provider implements a classic Tic Tac Toe game where players can play against a computer opponent with basic AI.

## Implementation Details

### Provider Structure

Located in `lib/providers/provider_tictactoe.dart`:

- **Provider name**: `TicTacToe`
- **Model**: `TicTacToeModel` (ChangeNotifier)
- **Widget**: `TicTacToeCard` (StatefulWidget)

### Model Properties

```dart
class TicTacToeModel extends ChangeNotifier {
  List<TTTSymbol> board;              // 3x3 grid (9 cells)
  TTTSymbol playerSymbol;             // X
  TTTSymbol computerSymbol;           // O
  TTTResult gameResult;               // none, playerWin, computerWin, draw
  bool isGameOver;                    // Game state flag
  List<int> winningLine;              // Winning cells indices
  
  int wins;                           // Win counter
  int losses;                         // Loss counter
  int draws;                          // Draw counter
  List<TTTGameEntry> history;         // Game history (max 10)
}
```

### Enums

```dart
enum TTTSymbol { empty, x, o }
enum TTTResult { none, playerWin, computerWin, draw }
```

### AI Logic

The computer AI follows a priority-based strategy:

1. **Winning move**: If computer can win, take it
2. **Blocking move**: If player can win, block it
3. **Center**: Take center if available
4. **Corners**: Take random corner
5. **Edges**: Take random edge

This provides a reasonable challenge while remaining simple.

### Game Flow

1. Player clicks a cell → `playerMove(index)`
2. Player's X is placed on board
3. Check for win/draw
4. If game continues, computer makes move
5. Computer's O is placed on board
6. Check for win/draw
7. Update statistics and history

### UI Components

- **Grid**: 3x3 GridView with gesture detection
- **Stats row**: Wins, Losses, Draws, Win Rate
- **New Game button**: Appears when game ends
- **History toggle**: Show/hide game history
- **Reset button**: Clear stats and history

### Keywords

`tic tac toe game ttt xo grid board play`

## Tests

Located in `test/widget_test.dart` under `TicTacToe Provider tests` group:

- Provider existence in Global.providerList
- Model initialization and state management
- Player/computer moves
- Win/draw detection
- Statistics tracking
- History management
- UI rendering tests

Total: 32 tests

## Integration

1. Import in `lib/data.dart`
2. Add to `Global.providerList`
3. Import in `lib/main.dart`
4. Add to `MultiProvider`

## Material 3 Compliance

- Uses `Card.filled` for main card
- Uses `SizedBox` with fixed dimensions for grid
- ColorScheme for colors
- Proper state management with ChangeNotifier