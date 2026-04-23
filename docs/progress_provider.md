# Progress Tracker Provider Implementation

## Overview

The Progress Tracker provider allows users to track progress on goals and projects with percentage visualization. It provides a simple interface for adding, editing, and updating progress items with visual feedback through linear progress bars.

## Features

- Track multiple progress items with custom targets
- Linear progress bar with color coding
- Increment/decrement buttons for quick updates
- Add, edit, and delete progress items
- Maximum 15 progress items stored (oldest removed when limit exceeded)
- Progress items persisted via SharedPreferences
- Completed/total count display
- Average progress calculation
- Color coding for progress levels

## Implementation

### Provider Structure

```dart
MyProvider providerProgress = MyProvider(
    name: "Progress",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Data Model

The `ProgressItem` class represents each progress entry:

```dart
class ProgressItem {
  final String name;
  final int current;
  final int target;
  final DateTime createdAt;

  double get percentage => target > 0 ? (current / target) * 100 : 0;
  bool get isComplete => current >= target;
  int get remaining => target - current;
}
```

### ProgressModel

The `ProgressModel` manages the state and persistence:

```dart
class ProgressModel extends ChangeNotifier {
  static const int maxProgressItems = 15;
  
  List<ProgressItem> _items = [];
  bool _isInitialized = false;
  
  int get completedCount => _items.where((p) => p.isComplete).length;
  double get averageProgress {
    if (_items.isEmpty) return 0;
    return _items.map((p) => p.percentage).reduce((a, b) => a + b) / _items.length;
  }
  
  void addProgress(String name, int target);
  void updateCurrentValue(int index, int current);
  void incrementProgress(int index, int amount);
  void deleteProgress(int index);
  Future<void> clearAllProgress();
}
```

### Widget Components

#### ProgressCard

Main widget displaying all progress items:

- Shows loading state before initialization
- Empty state with message when no items
- List of progress items with visual bars
- Add and clear buttons in footer

#### Progress Item Widget

Each progress item displays:

- Name and percentage badge
- Linear progress bar with color coding
- Current/target values
- Increment/decrement buttons (when incomplete)

### Color Coding

- **100% complete**: Primary color (green)
- **75%+ progress**: Tertiary color (teal)
- **50%+ progress**: Secondary color
- **<50% progress**: On surface with alpha

## Keywords

- progress
- track
- goal
- project
- percentage
- completion
- goal tracker

## Usage

1. Tap the "+" button to add a new progress item
2. Enter a name and target value
3. Use increment/decrement buttons to update progress
4. Long press an item to edit or delete
5. Use "Clear all" button to remove all items

## Persistence

Progress items are stored in SharedPreferences as a JSON string list:

```dart
static const String _storageKey = 'progress_items';
```

Each item is serialized using `toJson()` and deserialized using `fromJson()`.

## Tests

Located in `test/widget_test.dart`:

- ProgressItem properties (percentage, completion, remaining)
- ProgressItem JSON serialization/deserialization
- ProgressModel initialization and CRUD operations
- ProgressModel statistics (completedCount, averageProgress)
- Widget rendering tests (loading, empty, with items)
- Dialog tests (Add, Edit)