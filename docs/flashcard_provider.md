# Flashcard Provider Implementation

## Overview

The Flashcard provider is a study tool for learning and memorization. It allows users to create multiple decks of flashcards with front (question) and back (answer) text, and study them by flipping cards and marking them as correct/incorrect for progress tracking.

## Provider Definition

Located in `lib/providers/provider_flashcard.dart`.

```dart
MyProvider providerFlashcard = MyProvider(
    name: "Flashcard",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

## Data Models

### FlashcardItem

Represents a single flashcard with front and back text:

```dart
class FlashcardItem {
  final String front;
  final String back;
  final DateTime createdAt;

  FlashcardItem({
    required this.front,
    required this.back,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
```

### FlashcardDeck

Represents a collection of flashcards with study statistics:

```dart
class FlashcardDeck {
  final String name;
  final List<FlashcardItem> cards;
  final DateTime createdAt;
  final int correctCount;
  final int incorrectCount;

  int get totalCards => cards.length;
  int get studiedCards => correctCount + incorrectCount;
  double get accuracy {
    if (studiedCards == 0) return 0;
    return correctCount / studiedCards * 100;
  }
}
```

### FlashcardModel

State management class extending `ChangeNotifier`:

```dart
class FlashcardModel extends ChangeNotifier {
  static const int maxDecks = 10;
  static const int maxCardsPerDeck = 50;
  static const String _storageKey = 'flashcard_decks';

  List<FlashcardDeck> _decks = [];
  bool _isInitialized = false;

  Future<void> init();
  void addDeck(String name);
  void updateDeck(int index, String name);
  void deleteDeck(int index);
  void addCard(int deckIndex, String front, String back);
  void deleteCard(int deckIndex, int cardIndex);
  void recordStudyResult(int deckIndex, bool isCorrect);
  Future<void> clearAllDecks();
}
```

## UI Components

### FlashcardCard

Main card widget displaying all decks:

- Shows total decks and cards count
- Lists all decks with card count and accuracy
- Add deck button (+ icon)
- Clear all decks button (delete_sweep icon)
- Uses `Card.filled` for Material 3 style

### AddDeckDialog

Dialog for creating a new deck:

- Single text field for deck name
- Auto-focuses on text field
- Validates non-empty input

### EditDeckDialog

Dialog for editing/deleting existing deck:

- Shows current deck name
- Edit, delete, and cancel options
- Long press on deck opens this dialog

### AddCardDialog

Dialog for adding a card to a deck:

- Two text fields: front (question) and back (answer)
- Validates both fields are non-empty
- Accessible from deck card (+ icon)

### StudyDialog

Dialog for studying a deck:

- Displays current card index and total
- Card area shows front or back based on flip state
- Tap to flip card
- Previous/Next navigation buttons
- Correct/Incorrect marking buttons (visible only when showing answer)
- Visual feedback with primary/error colors

## Keywords

The provider responds to these keywords:
- `flashcard`
- `flash`
- `cards`
- `study`
- `learn`
- `memorize`
- `quiz`
- `deck`
- `review`

## Persistence

Decks are stored in SharedPreferences as JSON strings:

```dart
// Storage key: 'flashcard_decks'
// Each deck is serialized as JSON string
await prefs.setStringList(_storageKey, deckStrings);
```

## Integration

### Global Provider List

Added to `Global.providerList` in `lib/data.dart`:

```dart
providerFlashcard,
```

### MultiProvider

Added to `MultiProvider` in `lib/main.dart`:

```dart
ChangeNotifierProvider.value(value: flashcardModel),
```

## Limits

- Maximum 10 decks per session
- Maximum 50 cards per deck
- Older entries are removed when limits are exceeded

## Usage Flow

1. Create a deck by tapping the + button or searching "flashcard"
2. Add cards to a deck via the + icon on each deck
3. Study a deck by tapping the play icon on each deck
4. Flip cards by tapping the card area
5. Mark correct/incorrect to track accuracy
6. Edit/delete decks by long pressing on deck name
7. Clear all decks via delete_sweep button

## Material 3 Components

- `Card.filled` for main card and deck items
- `Icon(Icons.school)` for flashcard icon
- `Icon(Icons.folder)` for deck icon
- `Icon(Icons.play_arrow)` for study button
- `Icon(Icons.add_card)` for add card button
- `AlertDialog` for all dialogs
- `IconButton.styleFrom()` for styled buttons

## Testing

Tests located in `test/widget_test.dart` under "Flashcard provider tests" group:

- Model initialization and state management
- CRUD operations for decks and cards
- Study result tracking
- Accuracy calculations
- JSON serialization/deserialization
- Widget rendering tests
- Provider existence and keywords