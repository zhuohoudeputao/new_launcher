# Rock Paper Scissors Provider

## Overview

The Rock Paper Scissors provider is a fun game utility that allows users to play the classic Rock Paper Scissors game against a computer opponent. The provider tracks win/loss/draw statistics and maintains a history of recent games.

## Implementation

### Provider File: `lib/providers/provider_rockpaperscissors.dart`

### Key Components

#### RPSChoice Enum
- `rock` - Rock choice (represented by 🪨)
- `paper` - Paper choice (represented by 📄)
- `scissors` - Scissors choice (represented by ✂️)

#### RPSResult Enum
- `win` - Player wins
- `lose` - Player loses
- `draw` - Game is a draw

#### RPSGameEntry Class
Stores individual game data:
- `playerChoice` - Player's choice
- `computerChoice` - Computer's choice
- `result` - Game result
- `timestamp` - When the game was played

#### RockPaperScissorsModel Class
Manages game state and statistics:
- `_isInitialized` - Initialization flag
- `_playerChoice` - Current player choice
- `_computerChoice` - Current computer choice
- `_lastResult` - Last game result
- `_wins`, `_losses`, `_draws` - Statistics counters
- `_history` - List of recent games (max 10)

### Key Methods

- `play(RPSChoice choice)` - Play a game with the given choice
- `resetStats()` - Reset all statistics
- `clearHistory()` - Clear game history
- `getChoiceEmoji(RPSChoice choice)` - Get emoji for choice
- `getChoiceName(RPSChoice choice)` - Get name for choice
- `getResultText(RPSResult result)` - Get result text
- `getResultColor(RPSResult result, BuildContext context)` - Get color for result
- `getWinRate()` - Calculate win rate percentage

### UI Components

#### RockPaperScissorsCard Widget
Displays the game interface:
- Game area with player vs computer comparison
- Choice buttons (Rock, Paper, Scissors)
- Statistics row (Wins, Losses, Draws, Win Rate)
- History toggle button
- Reset button with confirmation dialog

### Material 3 Design
- Uses `Card.filled` for main card
- Uses `Card` with elevation 0 for game area
- Uses `ElevatedButton` for choice buttons
- Uses `TextButton` for history toggle
- Color coding for results (green for win, red for lose)

## Keywords

The provider can be triggered via search with these keywords:
- `rock` - Rock keyword
- `paper` - Paper keyword
- `scissors` - Scissors keyword
- `game` - Game keyword
- `rps` - RPS abbreviation
- `play` - Play keyword
- `hand` - Hand keyword

## Statistics

The provider tracks:
- Total wins
- Total losses
- Total draws
- Win rate percentage
- History of up to 10 recent games

## Game Logic

The game follows standard Rock Paper Scissors rules:
- Rock beats Scissors
- Scissors beats Paper
- Paper beats Rock
- Same choices result in a draw

## Integration

The provider is integrated into:
- `Global.providerList` in `lib/data.dart`
- MultiProvider in `lib/main.dart`

## Tests

Tests are located in `test/widget_test.dart` under the "RockPaperScissors Provider tests" group:
- Model initialization tests
- Game play tests
- Statistics tracking tests
- History management tests
- Enum tests
- Widget rendering tests
- Keywords tests