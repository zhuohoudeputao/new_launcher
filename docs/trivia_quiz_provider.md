# Trivia Quiz Provider Implementation

## Overview

The Trivia Quiz provider implements a general trivia knowledge quiz game for entertainment and learning. It provides trivia questions across multiple categories with multiple-choice answers, timer support, and statistics tracking.

## Implementation Details

### File Location
`lib/providers/provider_triviaquiz.dart`

### Provider Definition
```dart
MyProvider providerTriviaQuiz = MyProvider(
    name: "TriviaQuiz",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Categories
Five trivia categories are supported:
- **Science** 🔬 - Physics, chemistry, biology, astronomy questions
- **History** 📜 - Historical events, figures, and dates
- **Geography** 🌍 - Countries, capitals, landmarks, geography facts
- **Sports** ⚽ - Sports rules, events, players, records
- **Entertainment** 🎬 - Movies, music, books, pop culture

### Question Structure
Each question contains:
- Question text
- Four answer options
- Correct answer index
- Category classification
- Optional explanation/fun fact

### Model: TriviaQuizModel

#### State Variables
- `_selectedCategory`: Currently selected category filter
- `_currentQuestion`: Active trivia question
- `_selectedAnswer`: User's selected answer
- `_answerSubmitted`: Whether answer has been submitted
- `_correctCount`: Total correct answers
- `_totalAttempts`: Total questions attempted
- `_currentStreak`: Consecutive correct answers
- `_bestStreak`: Best streak achieved
- `_history`: Quiz history entries (max 20)
- `_timeLimit`: Timer duration (0, 15, 30, 60 seconds)
- `_timeRemaining`: Remaining time for current question

#### Key Methods
- `init()`: Initialize model and generate first question
- `generateNewQuestion()`: Create new random question
- `setCategory()`: Filter questions by category
- `selectAnswer()`: Record user's answer selection
- `submitAnswer()`: Submit and evaluate answer
- `nextQuestion()`: Move to next question
- `skipQuestion()`: Skip current question
- `clearHistory()`: Reset statistics and history
- `toggleHistory()`: Toggle history view

### Widget: TriviaQuizCard

#### Features
- Category selector with ActionChips
- Timer selector with ActionChips
- Question display with category badge
- Four answer option buttons with visual feedback
- Explanation display after answering
- Statistics row (correct count, accuracy, streak, best streak)
- History view with past questions
- Clear history confirmation dialog

#### Visual Feedback
- Selected answer: SecondaryContainer background
- Correct answer: PrimaryContainer background with check icon
- Wrong answer: ErrorContainer background with cancel icon
- Timer warning: Error color when time ≤ 5 seconds

### Trivia Questions Database
35 trivia questions covering all categories:
- Science: 8 questions
- History: 7 questions
- Geography: 7 questions
- Sports: 6 questions
- Entertainment: 7 questions

## Usage

### Keywords
`trivia quiz knowledge question answer game science history geography sports entertainment fun facts learn`

### Actions
- Trivia Quiz: Show trivia quiz card for playing

### Display
- Card.filled with Material 3 styling
- SingleChildScrollView for overflow handling
- ActionChips for category and timer selection
- InkWell for answer selection with rounded corners

## Statistics Tracking

### Accuracy Calculation
```dart
double get accuracy => _totalAttempts > 0 
    ? (_correctCount / _totalAttempts) * 100 : 0;
```

### Streak Tracking
- Current streak increments on correct answers
- Current streak resets on wrong answers
- Best streak records maximum consecutive correct

## History Management

### Entry Structure
```dart
class TriviaQuizEntry {
  final String question;
  final String correctAnswer;
  final String userAnswer;
  final bool isCorrect;
  final TriviaCategory category;
  final DateTime timestamp;
}
```

### Limits
- Maximum 20 history entries
- Oldest entries removed when limit exceeded

## Timer Feature

### Options
- No Timer: Unlimited time
- 15 seconds: Quick challenge
- 30 seconds: Moderate challenge
- 60 seconds: Relaxed pace

### Behavior
- Timer counts down after question generated
- Auto-submit on timeout (counts as wrong)
- Timer warning when ≤ 5 seconds remaining

## Testing

### Test Coverage
- Model initialization
- Question generation
- Category filtering
- Answer submission (correct/wrong)
- Streak tracking
- History management
- Timer functionality
- Widget rendering
- Provider registration

### Test Count
26 tests for Trivia Quiz provider

## Material 3 Compliance

### Components Used
- Card.filled for main container
- ActionChip for category/timer selection
- ElevatedButton.icon for action buttons
- Container with BoxDecoration for answer options
- IconButton with styleFrom for header buttons

### Color Scheme Usage
- colorScheme.primaryContainer for selected/correct states
- colorScheme.secondaryContainer for categories
- colorScheme.errorContainer for wrong answers
- colorScheme.tertiaryContainer for explanations
- colorScheme.surfaceContainerHighest for question container

## Integration

### Global.providerList
Added at end of provider list:
```dart
providerTriviaQuiz,
```

### Dependencies
- Flutter Material Design
- Provider package for state management
- Dart:async for Timer functionality

## Example Questions

### Science
- "What is the chemical symbol for gold?" → Au
- "How many planets are in our solar system?" → 8
- "What is the hardest natural substance on Earth?" → Diamond

### History
- "Who was the first President of the United States?" → George Washington
- "In which year did World War II end?" → 1945
- "Who painted the Mona Lisa?" → Leonardo da Vinci

### Geography
- "What is the largest continent by area?" → Asia
- "What is the longest river in the world?" → Nile
- "What is the capital of Japan?" → Tokyo

### Sports
- "How many players are on a soccer team?" → 11
- "What sport does Tiger Woods play?" → Golf
- "How many rings are on the Olympic flag?" → 5

### Entertainment
- "Who directed the movie 'Titanic'?" → James Cameron
- "What is the name of Harry Potter's owl?" → Hedwig
- "How many Harry Potter books are there?" → 7