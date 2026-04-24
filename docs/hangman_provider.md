# Hangman Provider Implementation

## Overview

The Hangman provider implements a classic word guessing game where players guess letters to reveal a hidden word before running out of attempts.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_hangman.dart`

### Model: HangmanModel

The `HangmanModel` class manages game state with the following properties:

#### Game State
- `_currentWord`: The word to guess (randomly selected from word list)
- `_guessedLetters`: Set of correctly guessed letters
- `_wrongLetters`: Set of incorrectly guessed letters
- `_maxWrongGuesses`: Maximum allowed wrong guesses (6)
- `_gameWon`: Win state flag
- `_gameLost`: Lose state flag

#### Statistics
- `_wins`: Total wins count
- `_losses`: Total losses count
- `_history`: Game history entries (max 10)

#### Key Methods
- `init()`: Initialize model and start new game
- `newGame()`: Reset game state for new game
- `guessLetter(String letter)`: Process letter guess
- `_checkWin()`: Check if player has won
- `_checkLose()`: Check if player has lost
- `resetStats()`: Reset win/loss statistics
- `clearHistory()`: Clear game history
- `getHangmanStage(int wrongCount)`: Return ASCII art for hangman figure
- `getWinRate()`: Calculate win percentage

#### Computed Properties
- `displayedWord`: Word with underscores for unguessed letters
- `remainingGuesses`: Number of guesses remaining
- `availableLetters`: Letters not yet guessed
- `isGameOver`: True if game won or lost

### Word List

The provider includes 40 tech-related words:
- Flutter/Dart: flutter, dart, widget, provider, material
- Mobile: android, mobile, application, device, screen
- Features: keyboard, button, theme, color, battery
- Utilities: weather, timer, clock, calculator, notes
- Development: programming, development, software, engineer

### UI: HangmanCard

The `HangmanCard` widget displays:

1. **Header**: Game title with history and reset buttons
2. **Hangman Figure**: ASCII art showing game progress (7 stages)
3. **Word Display**: Hidden word with underscores and revealed letters
4. **Letter Buttons**: Alphabet grid for letter selection
5. **Statistics**: Wins, losses, and win rate
6. **Game Result**: Win/lose message with new game button

### Game Mechanics

- Maximum 6 wrong guesses allowed
- Correct guesses reveal letters in word
- Wrong guesses increment counter and update hangman figure
- Game ends when:
  - All letters guessed correctly (win)
  - 6 wrong guesses reached (lose)

### History Feature

- Tracks game outcome, word, and wrong guesses count
- Maximum 10 history entries stored
- Shows timestamp for each game (just now, Xm ago, Xh ago, Xd ago)

## Testing

### Test Coverage

The provider includes comprehensive tests covering:

1. **Model Tests**
   - Default values initialization
   - Game state management
   - Letter guessing mechanics
   - Win/lose detection
   - Statistics tracking
   - History management
   - Hangman figure stages

2. **Widget Tests**
   - Loading state rendering
   - Initialized state rendering
   - Hangman figure display
   - Statistics display

### Test Count
- 22 Hangman-specific tests added
- Total test count: 1800

## Usage

The Hangman game can be accessed by:
- Searching "hangman" in the launcher
- Using keywords: hangman, word, guess, game, letter, puzzle, play

## Material 3 Components

- `Card.filled` for game container
- `IconButton` with `IconButton.styleFrom()` for buttons
- `ElevatedButton` for new game button
- `Wrap` for letter button grid
- `AlertDialog` for reset confirmation

## Integration

The provider is integrated into:
- `lib/data.dart`: Added to `Global.providerList`
- `lib/main.dart`: Added to `MultiProvider`
- `test/widget_test.dart`: Added tests and provider count updates