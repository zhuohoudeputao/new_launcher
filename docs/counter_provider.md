# Counter Provider Implementation

## Overview

The Counter provider is a utility for creating and managing multiple named counters. It allows users to track various counting tasks such as workout reps, people count, inventory items, and more.

## Features

- **Multiple counters**: Create up to 15 named counters
- **Custom step values**: Configure increment/decrement step size (default: 1)
- **Increment/Decrement**: Quick +/- buttons for each counter
- **Reset**: Reset individual counters to zero
- **Edit/Delete**: Long press to edit counter name and step, or delete
- **Total display**: Shows sum of all counter values
- **Persistence**: Counters saved via SharedPreferences

## Implementation Details

### File Location
`lib/providers/provider_counter.dart`

### Model: CounterModel

```dart
class CounterModel extends ChangeNotifier {
  static const int maxCounters = 15;
  static const String _storageKey = 'counter_items';
  
  List<CounterItem> _counters = [];
  bool _isInitialized = false;
  
  // Getters
  bool get isInitialized;
  List<CounterItem> get counters;
  int get length;
  int get totalCount;
  
  // Methods
  Future<void> init();
  Future<void> refresh();
  void addCounter(String name, int step);
  void updateCounter(int index, String name, int step);
  void increment(int index);
  void decrement(int index);
  void resetCounter(int index);
  void deleteCounter(int index);
  Future<void> clearAllCounters();
}
```

### Item: CounterItem

```dart
class CounterItem {
  final String name;
  final int count;
  final int step;
  final DateTime createdAt;
  
  // Serialization
  String toJson();
  static CounterItem fromJson(String jsonStr);
  CounterItem copyWith({...});
}
```

### Widget: CounterCard

Displays all counters with:
- Counter name and step value
- Decrement button (-)
- Current count display (large number)
- Increment button (+)
- Reset button (↻)
- Add counter button (+)
- Clear all button (trash)

### Dialogs

- **AddCounterDialog**: Input name and configure step value
- **EditCounterDialog**: Edit name/step or delete counter

## User Interaction

1. **Add counter**: Tap + button, enter name and step value
2. **Increment**: Tap + button on counter row
3. **Decrement**: Tap - button on counter row
4. **Reset**: Tap ↻ button on counter row
5. **Edit/Delete**: Long press on counter row
6. **Clear all**: Tap trash button in bottom row

## Material 3 Components

- `Card.filled()` for main card and counter items
- `IconButton.styleFrom()` for styled buttons
- `Card.filled()` with surfaceContainerHighest color for items

## Keywords

The provider registers action with keywords:
`counter count tap tally number increment add track`

## Integration

### data.dart
```dart
import 'package:new_launcher/providers/provider_counter.dart';

Global.providerList = [
  ...
  providerCounter,
];
```

### main.dart
```dart
import 'package:new_launcher/providers/provider_counter.dart';

MultiProvider(
  providers: [
    ...
    ChangeNotifierProvider.value(value: counterModel),
  ],
)
```

## Tests

Tests are located in `test/widget_test.dart` under 'Counter provider tests' group:

- CounterModel initialization
- addCounter with default and custom steps
- maxCounters limit enforcement
- increment/decrement operations
- resetCounter functionality
- updateCounter and deleteCounter
- clearAllCounters
- toJson/fromJson serialization
- CounterCard widget rendering (loading, empty, with data)
- Dialog widget existence
- Provider registration checks
- Keywords validation
- ChangeNotifier type check
- Persistence verification

## Usage Examples

### Workout tracking
1. Add counter "Reps" with step 1
2. Tap + after each set
3. Reset between exercises

### Score tracking
1. Add counter "Score" with step 5
2. Tap + for 5 points, - for -5 points

### Inventory count
1. Add counter "Items" with step 1
2. Tap + for items added, - for items removed
3. Reset when starting new count

## Data Storage

Counters are persisted using SharedPreferences with key `counter_items`. Each counter is serialized to JSON and stored in a list.

## Design Decisions

- Negative values allowed (can decrement below 0)
- Step value configurable per counter (not global)
- Maximum 15 counters (oldest removed when exceeded)
- Count persists across app restarts
- Total count shown in header for quick overview