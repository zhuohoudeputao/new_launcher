# Memory Game Provider Implementation

## Overview

The Memory Game provider implements a classic card matching game where users flip cards to find matching pairs. The game supports two grid sizes (4x4 and 6x6) and tracks moves, best scores, and game history.

## Implementation Details

### Provider File: `lib/providers/provider_memorygame.dart`

### Model: `MemoryGameModel`

The model manages the memory game with:
- **Card Grid**: Configurable 4x4 (8 pairs) or 6x6 (18 pairs) grid
- **Card Matching**: Flip two cards to find matching pairs
- **Move Tracking**: Count number of card flips (each pair flip = 1 move)
- **Best Score**: Track minimum moves to complete each grid size
- **History**: Recent completed games with move count

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isInitialized` | `bool` | Whether the model has been initialized |
| `cards` | `List<MemoryCard>` | List of cards in the current game |
| `moves` | `int` | Number of moves in current game |
| `matchedPairs` | `int` | Number of matched pairs found |
| `gameSize` | `MemoryGameSize` | Current grid size (small4x4 or large6x6) |
| `isGameOver` | `bool` | Whether all pairs have been matched |
| `isProcessing` | `bool` | Whether a pair check is in progress |
| `totalPairs` | `int` | Total number of pairs (8 or 18) |
| `gridSize` | `int` | Grid dimension (4 or 6) |
| `bestMoves` | `int` | Best score for current grid size |
| `gamesPlayed` | `int` | Total games completed |
| `history` | `List<MemoryGameEntry>` | Recent game completions (max 10) |
| `hasHistory` | `bool` | Whether history contains any entries |

#### Card States

| State | Description |
|-------|-------------|
| `hidden` | Card face is hidden, can be flipped |
| `flipped` | Card face is visible, awaiting pair check |
| `matched` | Card pair has been matched, stays visible |

#### Methods

| Method | Description |
|--------|-------------|
| `init()` | Initialize the model and load saved data |
| `refresh()` | Notify listeners without changing state |
| `setSize(MemoryGameSize)` | Change grid size and start new game |
| `newGame()` | Start a new game with shuffled cards |
| `flipCard(int cardId)` | Flip a card to reveal its symbol |
| `getProgress()` | Calculate percentage of pairs matched |
| `getSizeLabel(MemoryGameSize)` | Get display label for grid size |
| `clearHistory()` | Clear all history and reset best scores |
| `getCardColor(MemoryCardState, context)` | Get color for card based on state |
| `getCardBorderColor(MemoryCardState, context)` | Get border color for card |

### Widget: `MemoryGameCard`

The card displays:
- SegmentedButton for grid size selection (4x4 / 6x6)
- Card grid with emoji symbols
- Statistics row (moves, pairs, best, games played)
- "Completed" message when game is finished
- "New Game" button after completion
- History view toggle showing recent completions
- Clear history button with confirmation

### UI Components

- **Size Selector**: SegmentedButton with grid_view and apps icons
- **Card Grid**: GridView with cards showing question mark or emoji
- **Card Colors**: 
  - Hidden: Primary container (question mark icon)
  - Flipped: Secondary container (emoji visible)
  - Matched: Tertiary container (emoji visible, thicker border)
- **Stats Row**: Moves, Pairs (matched/total), Best score, Games count
- **History View**: List of recent completions with moves, grid size, time ago

### Material 3 Components Used

- `Card.filled()` - Main card container
- `SegmentedButton` - Grid size selection
- `GridView.builder` - Card grid layout
- `GestureDetector` - Card flip detection
- `Container` with `BoxDecoration` - Card styling with border
- `Icon` with `extension`, `history`, `delete_outline` - Action icons
- `ElevatedButton.icon` - New game button
- `AlertDialog` - Clear history confirmation

## Card Symbols

### 4x4 Grid (8 pairs)
🌟, 🎈, 🌈, 🍀, 🔥, 💎, 🎵, 🌸

### 6x6 Grid (18 pairs)
🌟, 🎈, 🌈, 🍀, 🔥, 💎, 🎵, 🌸, ❤️, 🌙, ⚡, 🌺, 🎯, 🏆, 🍀, 🎭, 🎨, 🎪

## Testing

Tests are located in `test/widget_test.dart` under the `MemoryGame provider tests` group:

- Provider existence in Global.providerList
- Model is ChangeNotifier
- Initial state validation
- init creates cards correctly
- setSize changes grid correctly
- flipCard adds flipped cards
- flipCard two cards increases moves
- matched cards stay matched
- non-matched cards are hidden again
- isProcessing prevents flipping during check
- newGame resets state
- getProgress calculates percentage correctly
- history entries validation
- bestMoves tracking
- gamesPlayed tracking
- size label validation
- refresh calls notifyListeners
- MemoryCard and MemoryGameEntry properties
- Widget rendering (loading and initialized states)
- Grid icon display
- Size selector display
- Stats display

Total tests: 25 tests for MemoryGame provider

## Keywords

The provider registers keywords for search:
- memory, game, cards, match, flip, pairs, puzzle, remember

## Integration

The provider is integrated into the app through:
- `lib/data.dart`: Import and provider list registration
- `lib/main.dart`: Import and MultiProvider registration

## Usage Example

Users can:
1. Select grid size using SegmentedButton (4x4 or 6x6)
2. Tap hidden cards (question mark) to reveal their emoji
3. Tap second card to attempt matching
4. If cards match: both stay visible with matched color
5. If cards don't match: both flip back to hidden after 500ms
6. Continue until all pairs are matched
7. View completion message showing total moves
8. Tap "New Game" to start again
9. Track best score (minimum moves) per grid size
10. Toggle history view to see recent completions
11. Clear all history with confirmation dialog

## Game Flow

1. Initial state: All cards hidden (question mark icons)
2. User taps first card: Card flips to reveal emoji
3. User taps second card: Both cards checked for match
4. If matched: Cards stay visible, matched pairs count increases
5. If not matched: Cards flip back to hidden after 500ms
6. Move counter increments for each pair flip
7. Game ends when all pairs are matched
8. Completion recorded in history with moves and timestamp
9. Best score updated if moves < current best
10. "New Game" button appears for restart

## Persistence

Data is persisted using SharedPreferences:
- `memoryGame_bestMoves4x4`: Best score for 4x4 grid
- `memoryGame_bestMoves6x6`: Best score for 6x6 grid
- `memoryGame_gamesPlayed`: Total games completed
- `memoryGame_history`: JSON-encoded history entries

History entries stored as pipe-separated values:
`moves|size|timestamp_ms`