# Percentage Calculator Provider Implementation

## Overview

The Percentage Calculator provider adds a versatile percentage calculation tool to the launcher, supporting four common calculation modes with history tracking and Material 3 styling.

## Implementation Details

### Provider Structure

Located in `lib/providers/provider_percentage.dart`:

```dart
MyProvider providerPercentage = MyProvider(
  name: "Percentage",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);
```

### PercentageModel

The `PercentageModel` class extends `ChangeNotifier` and manages:
- Calculation mode selection
- Input values for calculations
- History of previous calculations
- SharedPreferences persistence

### Calculation Modes

Four modes are supported via `PercentageMode` enum:

1. **percentageOf** - Calculate X% of Y
   - Example: 20% of 100 = 20
   - Formula: `value1 / 100 * value2`

2. **whatPercent** - Calculate what percentage X is of Y
   - Example: 50 is 25% of 200
   - Formula: `value1 / value2 * 100`

3. **percentageChange** - Calculate percentage change between two values
   - Example: 100 to 150 = +50%
   - Formula: `(value2 - value1) / value1 * 100`

4. **discount** - Calculate discounted price
   - Example: 20% off $100 = $80
   - Formula: `value2 - (value1 / 100 * value2)`

### History Management

- Maximum 10 history entries stored
- Entries stored via SharedPreferences with key `percentage_history`
- Each entry includes: mode, value1, value2, result, timestamp
- `PercentageHistory` class with `toJson()`/`fromJson()` serialization

### Error Handling

- Division by zero returns `null` for `whatPercent` and `percentageChange` modes
- Invalid input (non-numeric) returns `null`
- Empty input returns `null`

### PercentageCard Widget

Features:
- SegmentedButton for mode selection
- Two TextField inputs with appropriate labels
- Result display area with save button
- History section with ActionChip entries
- Clear history confirmation dialog
- Loading state with CircularProgressIndicator

Material 3 components:
- `Card.filled` for main container
- `SegmentedButton` for mode selection
- `ActionChip` for history entries
- `TextField` with OutlineInputBorder

## Keywords

Search keywords: `percentage, percent, calc, discount, ratio, rate, %`

## Usage Example

```dart
// Calculate 20% of 100
model.setMode(PercentageMode.percentageOf);
model.setInput1('20');
model.setInput2('100');
final result = model.calculate(); // Returns 20.0

// Save to history
model.addToHistory();

// Load from history
model.loadFromHistory(model.history.first);
```

## State Persistence

The model initializes by loading history from SharedPreferences:

```dart
Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();
  final historyStr = prefs.getStringList(_historyKey) ?? [];
  _history = historyStr.map((s) => PercentageHistory.fromJson(s)).toList();
}
```

## Testing

Tests cover:
- All four calculation modes
- Division by zero handling
- Invalid input handling
- History operations (add, load, clear)
- JSON serialization
- Widget rendering states
- Provider existence and keywords

Total: 28 tests for Percentage provider