# Reading Time Provider Implementation

## Overview

The Reading Time Provider provides a text analysis tool for estimating reading and speaking times. It calculates word count, character count, sentence count, paragraph count, and provides formatted time estimates based on configurable words per minute (WPM) settings.

## Implementation Details

### Provider Definition

Location: `lib/providers/provider_readingtime.dart`

```dart
ReadingTimeModel readingTimeModel = ReadingTimeModel();
MyProvider providerReadingTime = MyProvider(
  name: "ReadingTime",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "ReadingTime",
        keywords: "reading, time, read, words, estimate, wpm, minutes, count, text, article, blog, content",
        action: () {
          Global.infoModel.addInfoWidget("ReadingTime", ReadingTimeCard(), title: "Reading Time Estimator");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    readingTimeModel.init();
    Global.infoModel.addInfoWidget("ReadingTime", ReadingTimeCard(), title: "Reading Time Estimator");
  },
  update: () {},
);
```

### Model: ReadingTimeModel

The model extends `ChangeNotifier` and manages:

- **Text input**: The text to analyze
- **Words per minute**: Configurable reading speed (50-500 WPM, default 250)
- **History**: List of previous analyses (up to 10 entries)

#### Key Properties

| Property | Description |
|----------|-------------|
| `text` | Current text input |
| `wordsPerMinute` | Reading speed setting (250 default) |
| `wordCount` | Number of words in text |
| `characterCount` | Total characters including spaces |
| `characterCountNoSpaces` | Characters excluding spaces |
| `sentenceCount` | Number of sentences |
| `paragraphCount` | Number of paragraphs |
| `readingTimeMinutes` | Estimated reading time in minutes |
| `readingTimeSeconds` | Estimated reading time in seconds |
| `formattedReadingTime` | Human-readable time (e.g., "1m 30s") |
| `speakingTime` | Estimated speaking time (150 WPM) |
| `history` | List of past analyses |

#### Methods

| Method | Description |
|--------|-------------|
| `init()` | Initialize the model |
| `setText(value)` | Update text input |
| `setWordsPerMinute(value)` | Update WPM setting (clamped 50-500) |
| `addToHistory()` | Save current analysis to history |
| `useHistoryEntry(entry)` | Load a history entry |
| `clearText()` | Clear text input |
| `clearHistory()` | Clear all history entries |

### History Entry Structure

```dart
class ReadingTimeHistoryEntry {
  final String textPreview;
  final int wordCount;
  final String readingTime;
  final int wpm;
  final DateTime timestamp;
}
```

### UI Widget: ReadingTimeCard

The card uses Material 3 `Card.filled` with:

- TextField for text input (5 lines max)
- Clear button when text present
- Slider for WPM adjustment (50-500)
- Chips displaying:
  - Reading time
  - Speaking time
  - Word count
  - Character count
- Sentence and paragraph counts
- Save to history button
- History list (up to 5 entries shown)
- Clear history button with confirmation dialog

## Features

### Real-time Analysis

All statistics update instantly as text is entered:

- Word count: Split by whitespace, filters empty strings
- Character count: Simple length calculation
- Character count (no spaces): Removes all whitespace
- Sentence count: Split by `.!?` punctuation
- Paragraph count: Split by double newlines

### Speaking Time

Uses 150 WPM for speech estimation (standard presentation pace).

### History Management

- Maximum 10 entries stored
- Oldest removed when limit exceeded
- Tap history entry to reload text preview
- Timestamp display: "just now", "Xm ago", "Xh ago", "Xd ago"
- Clear history with confirmation dialog

## Keywords

`reading, time, read, words, estimate, wpm, minutes, count, text, article, blog, content`

## Integration

### MultiProvider Registration

Registered in `lib/main.dart`:

```dart
ChangeNotifierProvider.value(value: readingTimeModel),
```

### Provider List

Added to `Global.providerList` in `lib/data.dart`:

```dart
providerReadingTime,
```

## Material 3 Components

- `Card.filled` with transparent background
- `TextField` with OutlineInputBorder
- `Slider` for WPM adjustment
- `Chip` for statistics display
- `TextButton` for actions
- `AlertDialog` for confirmation
- `ListTile` for history entries

## Usage Example

1. Type or paste text in the input field
2. Adjust WPM slider to match reading speed
3. View real-time statistics in chips
4. Save analysis to history if desired
5. Tap history entries to reuse previous analyses