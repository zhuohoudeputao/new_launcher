# Math Quiz Provider Implementation

## Overview

The Math Quiz provider (`provider_mathquiz.dart`) provides a mental math practice and quiz game feature for the launcher. Users can solve randomly generated math problems across four operations and three difficulty levels.

## Features

- Random math problems with four operations: addition (+), subtraction (-), multiplication (×), division (÷)
- Three difficulty levels: Easy (numbers 1-10), Medium (numbers 1-50), Hard (numbers 1-100)
- Optional timer modes: No Timer, 10s, 30s, 60s per question
- Answer input with number keyboard
- Skip button for difficult problems
- Statistics tracking: correct count, accuracy percentage, current streak, best streak
- History tracking (up to 20 entries) with question, answer, and timestamp
- Streak tracking with fire icon for consecutive correct answers
- Clear history with confirmation dialog

## Implementation Details

### Model Class: `MathQuizModel`

Located at `lib/providers/provider_mathquiz.dart`, implements `ChangeNotifier`.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `difficulty` | `MathDifficulty` | Current difficulty level |
| `currentProblem` | `MathProblem?` | Current math problem |
| `userInput` | `String` | User's answer input |
| `correctCount` | `int` | Total correct answers |
| `totalAttempts` | `int` | Total attempts (answers submitted) |
| `currentStreak` | `int` | Consecutive correct answers |
| `bestStreak` | `int` | Best streak achieved |
| `history` | `List<MathQuizEntry>` | Quiz history (max 20 entries) |
| `accuracy` | `double` | Accuracy percentage calculation |
| `timeLimit` | `int` | Timer setting (0, 10, 30, 60 seconds) |
| `timeRemaining` | `int` | Remaining time on current question |
| `timerActive` | `bool` | Whether timer is running |

#### Methods

| Method | Description |
|--------|-------------|
| `init()` | Initialize the model and generate first problem |
| `setDifficulty(MathDifficulty)` | Change difficulty and generate new problem |
| `setTimeLimit(int)` | Set timer mode |
| `generateNewProblem()` | Generate a new random math problem |
| `updateInput(String)` | Update user input (filters non-digits) |
| `submitAnswer()` | Submit current answer |
| `skipProblem()` | Skip current problem (counts as wrong) |
| `nextProblem()` | Generate next problem |
| `toggleHistory()` | Toggle history view visibility |
| `clearHistory()` | Clear history and reset statistics |
| `reset()` | Full reset including timer |
| `getDifficultyName()` | Get string name of current difficulty |
| `formatTimeAgo(DateTime)` | Format timestamp as relative time |

### Helper Classes

#### `MathProblem`

Stores a math problem with:
- `a`, `b`: The two operands
- `operation`: The math operation type
- `answer`: The correct answer
- `operationSymbol`: Symbol representation (+, -, ×, ÷)
- `questionString`: Full question string (e.g., "5 + 3 = ?")
- `checkAnswer(int)`: Validate user answer

#### `MathQuizEntry`

Stores a quiz entry in history with:
- `question`: The question text
- `correctAnswer`: The correct answer
- `userAnswer`: User's submitted answer
- `isCorrect`: Whether answer was correct
- `timestamp`: When the question was answered
- `resultText`: "Correct" or "Wrong"

### Enums

```dart
enum MathDifficulty { easy, medium, hard }
enum MathOperation { addition, subtraction, multiplication, division }
```

### Widget: `MathQuizCard`

Uses Material 3 components:
- `Card.filled` for container
- `SegmentedButton` for difficulty selection
- `ActionChip` for timer options
- `TextField` for answer input
- `ElevatedButton` for submit and skip actions

## Problem Generation Logic

### Easy Difficulty (1-10)
- Addition: a + b where a, b ∈ [1, 10]
- Subtraction: a - b where a ≥ b
- Multiplication: a × b where a, b ∈ [1, 10]
- Division: a ÷ b where a = b × k for k ∈ [1, 5]

### Medium Difficulty (1-50)
- Addition: a + b where a, b ∈ [1, 50]
- Subtraction: a - b where a ≥ b
- Multiplication: a × b where a, b ∈ [1, 50]
- Division: a ÷ b where a = b × k for k ∈ [1, 10]

### Hard Difficulty (1-100)
- Addition: a + b where a, b ∈ [1, 100]
- Subtraction: a - b where a ≥ b
- Multiplication: a × b where a, b ∈ [1, 20]
- Division: a ÷ b where a = b × k for k ∈ [1, 12]

## UI Layout

```
┌─────────────────────────────────────┐
│  🧮 Math Quiz              [history] │
├─────────────────────────────────────┤
│  [Easy] [Medium] [Hard]             │ ← SegmentedButton
│  [No Timer] [10s] [30s] [60s]       │ ← ActionChip row
├─────────────────────────────────────┤
│           5 + 3 = ?                 │ ← Problem display
│        ┌─────────────────┐          │
│        │   Enter answer   │          │ ← TextField
│        └─────────────────┘          │
│      [Skip]         [Submit]        │ ← Buttons
├─────────────────────────────────────┤
│  ✓Correct  %Accuracy  🔥Streak  🏆Best│ ← Statistics
│     5         83%        3       5   │
└─────────────────────────────────────┘
```

## Testing

Tests are located in `test/widget_test.dart` under "MathQuiz provider tests" group:

- Model initialization
- Difficulty setting
- Problem generation
- Input filtering
- Answer submission (correct/wrong)
- Streak tracking
- Accuracy calculation
- History limits and clearing
- Time formatting
- Skip functionality
- Problem and entry classes
- Widget rendering
- Provider integration

## Integration

The provider is added to:
- `Global.providerList` in `lib/data.dart`
- `MultiProvider` in `lib/main.dart`

## Usage Keywords

Search keywords: `math, quiz, arithmetic, mental, calculate, addition, subtraction, multiplication, division, practice`

## Future Enhancements

Potential improvements:
- Custom operation selection (e.g., only multiplication)
- Mixed operation mode
- Difficulty presets for children
- Achievement badges
- Sound effects for correct/wrong answers
- Daily challenge mode