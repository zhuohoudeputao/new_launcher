# 2048 Game Provider Implementation

## Overview

The 2048 Game provider implements the classic 2048 number puzzle game.

## Provider Details

- **Provider Name**: 2048
- **Keywords**: 2048, game, puzzle, number, tile, slide, merge
- **Model**: game2048Model

## Game Rules

- 4x4 grid with tiles numbered 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048
- Slide tiles in 4 directions (up, down, left, right)
- Same-number tiles merge when colliding, doubling the value
- Goal: create a tile with 2048 (or higher)
- New tiles (2 or 4) appear after each move
- Game ends when no moves possible

## Features

### Gameplay

- 4 directional controls (IconButton)
- Swipe gesture support
- Score tracking based on merged tile values
- Highest tile tracking
- Move count tracking

### Statistics

- Games played count
- Win rate percentage
- Best score tracking
- Best tile achieved

### History

- Game history (up to 10 entries)
- Win/loss status per game
- Clear history with confirmation dialog

## Model (Game2048Model)

```dart
class Game2048Model extends ChangeNotifier {
  List<List<int>> _grid = [];
  int _score = 0;
  int _bestTile = 0;
  int _moves = 0;
  bool _gameOver = false;
  bool _won = false;
  
  void init();
  void moveUp();
  void moveDown();
  void moveLeft();
  void moveRight();
  void resetGame();
}
```

## Widget (Game2048Card)

- Card.filled style
- 4x4 GridView with colored tiles
- Score and best tile display
- Direction control buttons
- Reset button
- Statistics display
- History toggle view

## Tile Colors

Colors based on tile value:
- 2-8: Light colors
- 16-64: Medium colors
- 128-512: Bright colors
- 1024+: Gold/yellow colors

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching
- Model initialization and state
- Grid operations
- Move operations
- Statistics
- History operations
- Widget rendering

## Related Files

- `lib/providers/provider_2048.dart` - Provider implementation