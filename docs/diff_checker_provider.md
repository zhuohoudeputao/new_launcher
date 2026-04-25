# DiffChecker Provider Implementation

## Overview

The DiffChecker provider provides a text comparison utility for developers to compare two text inputs and visualize differences with color-coded highlighting.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_diff.dart`

### Model: DiffCheckerModel

The `DiffCheckerModel` class manages the state for text comparison:

#### Properties
- `_originalText`: The original text to compare
- `_modifiedText`: The modified text to compare against
- `_diffLines`: List of computed diff lines
- `_history`: List of saved comparisons (max 10 entries)
- `_isLoading`: Loading state indicator
- `_showWordDiff`: Toggle for word-level diff within lines

#### Computed Properties
- `additions`: Count of added lines
- `deletions`: Count of deleted lines
- `hasChanges`: Boolean indicating if there are any changes
- `diffLines`: List of DiffLine objects representing the comparison

### Diff Algorithm

The diff algorithm compares two texts line-by-line:
1. Split both texts into lines
2. For each line index, compare original and modified lines
3. If original line is null (new line added) → Addition
4. If modified line is null (line deleted) → Deletion
5. If both lines exist and are identical → Unchanged
6. If both lines exist and differ → Show addition and deletion

### Word-Level Diff

When `showWordDiff` is enabled:
- Compares words within changed lines
- Words unique to modified text shown as additions
- Words unique to original text shown as deletions
- Common words shown as unchanged

### DiffLine Class

Represents a single line in the diff output:
- `text`: The line content
- `type`: DiffType (addition, deletion, unchanged)
- `originalLine`: Original line number (optional)
- `modifiedLine`: Modified line number (optional)
- `wordDiffs`: Word-level diff details (optional)

### DiffHistory Class

Stores saved comparison entries:
- `original`: Original text
- `modified`: Modified text
- `additions`: Number of added lines
- `deletions`: Number of deleted lines
- `timestamp`: When the comparison was saved

## UI Components

### DiffCheckerCard

Material 3 styled card containing:
- Header with title and Word Diff toggle (FilterChip)
- Two text input fields (Original and Modified)
- Diff view showing line-by-line comparison
- Statistics bar showing additions/deletions count
- Save to History button
- Clear button
- History list with tap-to-restore functionality

### Color Coding

- Additions: Primary color (green theme)
- Deletions: Error color (red theme)
- Unchanged: Neutral surface color

### Icons/Prefixes
- Additions: `+` prefix
- Deletions: `-` prefix
- Unchanged: ` ` (space) prefix

## Provider Configuration

```dart
MyProvider providerDiffChecker = MyProvider(
    name: "DiffChecker",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Keywords
`diff compare text difference checker compare lines`

## Integration

The provider is integrated into:
1. `Global.providerList` in `lib/data.dart`
2. `MultiProvider` in `lib/main.dart`
3. Test suite in `test/widget_test.dart`

## Usage Example

1. Type "diff" in the search field to find the Diff Checker card
2. Enter original text in the first input field
3. Enter modified text in the second input field
4. View the color-coded diff output
5. Toggle "Word Diff" for word-level comparison
6. Save comparison to history for later reference
7. Tap history entries to restore previous comparisons

## Material 3 Components Used

- `Card.filled()`: Main container
- `FilterChip`: Word Diff toggle
- `TextField`: Text input fields
- `RichText`: Word-level diff display
- `ListView.builder`: Diff view container
- `ElevatedButton`: Save to History button
- `TextButton`: Clear buttons
- `AlertDialog`: Clear history confirmation

## Test Coverage

Tests cover:
- Provider existence and configuration
- Model initialization
- Text input handling
- Diff computation
- Addition/deletion detection
- Word diff toggle
- History management (add, apply, clear)
- Widget rendering
- Provider list integration