# Diff Checker Provider Implementation

## Overview

The Diff Checker provider compares two text inputs and shows differences line by line.

## Provider Details

- **Provider Name**: DiffChecker
- **Keywords**: diff, compare, text, difference, checker, compare, lines
- **Model**: diffCheckerModel

## Features

### Line Comparison

- Line-by-line comparison
- Color-coded differences
- Additions shown in primary color (green)
- Deletions shown in error color (red)
- Unchanged lines in neutral color

### Word-Level Diff

- Optional word-level diff within lines
- Toggle with FilterChip
- Highlights changed words in each line

### Statistics

- Additions count
- Deletions count

## Model (DiffCheckerModel)

```dart
class DiffCheckerModel extends ChangeNotifier {
  String _text1 = '';
  String _text2 = '';
  bool _wordDiff = false;
  List<DiffLine> _diffLines = [];
  int _additions = 0;
  int _deletions = 0;
  final List<DiffHistoryEntry> _history = [];
  static const int maxHistory = 10;
  
  void setText1(String value);
  void setText2(String value);
  void toggleWordDiff();
  void _computeDiff();
  void addToHistory();
  void clearHistory();
  void useHistoryEntry(DiffHistoryEntry entry);
}
```

### DiffLine

```dart
class DiffLine {
  DiffType type; // addition, deletion, unchanged
  String text;
  List<DiffWord>? wordDiffs;
}
```

## Widget (DiffCheckerCard)

- Card.filled style
- TextField for first text input
- TextField for second text input
- FilterChip for word diff toggle
- ListView of diff lines with color coding
- Statistics display
- History toggle view

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching
- Model initialization and state
- Diff computation
- Word diff toggle
- Statistics
- History operations
- Widget rendering

## Related Files

- `lib/providers/provider_diff.dart` - Provider implementation