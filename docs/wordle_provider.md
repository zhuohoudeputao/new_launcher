# Wordle Provider Implementation

## Overview

The Wordle provider implements a classic word guessing game for the Flutter launcher application. Players guess a 5-letter word in 6 attempts with color-coded feedback.

## Implementation Details

### Location
- Provider: `lib/providers/provider_wordle.dart`
- Tests: `test/widget_test.dart` (Wordle provider tests group)

### Model: WordleModel

The `WordleModel` class extends `ChangeNotifier` and manages:

- **Game State**: Current word, guesses, game won/lost status
- **Letter Input**: Current guess being typed
- **Letter Statuses**: Track status of each letter (correct, present, absent, unused)
- **Word List**: 200+ 5-letter words including tech-related words
- **Statistics**: Wins and losses count
- **Win Rate**: Percentage of games won
- **History**: Recent game entries (up to 10)

### Features

1. **Word Selection**
   - Random 5-letter word from extensive word list
   - Includes common words and tech-related vocabulary
   - New word selected for each game

2. **Guess Submission**
   - Type 5 letters using on-screen keyboard
   - Submit guess with Enter key
   - Maximum 6 attempts allowed

3. **Letter Feedback**
   - Green: Correct position (letter matches exactly)
   - Orange/Yellow: Wrong position (letter exists elsewhere)
   - Gray: Absent (letter not in word)

4. **Keyboard Status**
   - Track letter usage across all guesses
   - Color-coded keyboard reflects letter status
   - Unused letters show default color

5. **Win/Lose Detection**
   - Win: Guess matches target word
   - Lose: 6 attempts exhausted without match
   - Game over state prevents further input

6. **Statistics**
   - Wins count
   - Losses count
   - Win rate percentage
   - Reset stats option with confirmation dialog

7. **History**
   - Track up to 10 recent games
   - Store win/loss status, word, attempts, timestamp
   - Toggle history view

### Widget: WordleCard

The `WordleCard` widget displays:

- 5x6 guess grid showing previous guesses
- Current guess row (while typing)
- On-screen keyboard with letter status colors
- Statistics row (Wins, Losses, Rate)
- New Game button (when game over)
- History toggle and reset stats buttons

### Keywords

`wordle, word, guess, game, letter, puzzle, play, five`

## Material 3 Design

- `Card.filled` for card container
- `Row` and `InkWell` for letter boxes
- Color coding: Green for correct, Orange for present, Gray for absent
- `ElevatedButton` for new game action
- `TextButton` for reset confirmation

## Tests

Test coverage includes:

- WordleGuess properties
- WordleGameEntry properties
- WordleModel default values
- WordleModel initialization
- New game generation
- Letter addition (max 5 letters)
- Letter removal
- Guess submission (valid length)
- Guess evaluation (correct/present/absent)
- Letter status updates
- Win detection
- Lose detection
- Game over state
- History addition
- History max limit
- Statistics reset
- History clearing
- Win rate calculation
- Letter color retrieval
- Refresh notification
- Provider existence and keywords
- WordleCard rendering (loading, initialized states)
- Guess grid display
- Keyboard display
- Statistics row

## Game Algorithm

### Guess Evaluation

1. First pass: Identify correct positions (green)
2. Second pass: Identify present letters (yellow)
3. Mark remaining letters as absent (gray)
4. Update letter status map with priority:
   - Correct > Present > Absent > Unused

### Letter Status Priority

When updating letter statuses:
- If letter is correct in any position, mark as correct
- If letter is present (but not correct), mark as present
- If letter is absent (and not correct/present), mark as absent
- Unused letters stay unused until used in a guess

## Word List

The word list includes:
- Common 5-letter English words (about, above, abuse, etc.)
- Tech-related words (flutter, dart, android, widget, provider)
- Programming terms (debug, error, logic, code, etc.)
- General vocabulary (200+ words total)

## Future Enhancements

Potential improvements:

- Add daily challenge mode (same word for everyone)
- Add hard mode (must use revealed hints)
- Add statistics persistence via SharedPreferences
- Add streak tracking
- Import custom word lists
- Share results as emoji grid
- Add timer mode