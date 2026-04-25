# Lottery Provider Implementation

## Overview

The Lottery provider implements a lottery number generator for generating random lottery-style numbers. Users can select different lottery formats and generate unique random numbers for each format.

## Implementation Details

### Location
- Provider file: `lib/providers/provider_lottery.dart`
- Model: `LotteryModel` (ChangeNotifier)

### Lottery Types

The provider supports six lottery formats:
1. **6/49** - Classic lottery format (6 numbers from 1-49)
2. **5/50** - European lottery (5 numbers from 1-50)
3. **4/35** - Mini lottery (4 numbers from 1-35)
4. **3/27** - Quick pick (3 numbers from 1-27)
5. **5/90** - Large pool (5 numbers from 1-90)
6. **7/47** - Super draw (7 numbers from 1-47)

### Features

1. **Number Generation**
   - Unique random number generation
   - Numbers automatically sorted in ascending order
   - Pool-based selection (each number used only once)

2. **History Tracking**
   - Maximum 10 entries stored
   - Entries persisted via SharedPreferences
   - Load previous draws from history
   - Clear history with confirmation dialog

3. **UI Components**
   - SegmentedButton for lottery type selection
   - Circular number display with Material 3 styling
   - Wrap layout for number presentation
   - History toggle view

### Model Structure

```dart
class LotteryModel extends ChangeNotifier {
  static const int maxHistory = 10;
  
  List<LotteryHistoryEntry> _history = [];
  LotteryType _selectedLottery;
  List<int> _currentNumbers = [];
  bool _isInitialized = false;
  
  // Methods
  Future<void> init();
  void refresh();
  void setLotteryType(LotteryType type);
  void setLotteryTypeByName(String name);
  void generateNumbers();
  void clearNumbers();
  void saveToHistory();
  void loadFromHistory(LotteryHistoryEntry entry);
  void clearHistory();
}
```

### Data Classes

```dart
class LotteryType {
  final String name;
  final int poolSize;
  final int count;
  final String description;
}

class LotteryHistoryEntry {
  final DateTime date;
  final String lotteryType;
  final List<int> numbers;
  
  String toJson();
  static LotteryHistoryEntry fromJson(String jsonStr);
  String get displayText;
}
```

### Keywords

The provider registers the following keywords for action matching:
- lottery, numbers, lucky, random, pick, draw, win, game, lotto, jackpot, powerball, mega millions

### Widget Implementation

```dart
class LotteryCard extends StatefulWidget {
  // Displays:
  // - Lottery type selector (SegmentedButton)
  // - Generated numbers (circular number display)
  // - Action buttons (Generate, Save, Clear)
  // - History view toggle
}
```

## Testing

Test coverage includes:
- Provider existence verification
- Model initialization
- Lottery type selection
- Number generation and uniqueness
- Sorted numbers validation
- History management (save, load, clear)
- JSON encoding/decoding
- Widget rendering

## Usage Example

```dart
// Generate lottery numbers
lotteryModel.setLotteryTypeByName('6/49');
lotteryModel.generateNumbers();

// Save to history
lotteryModel.saveToHistory();

// Load from history
lotteryModel.loadFromHistory(lotteryModel.history.first);

// Clear history
lotteryModel.clearHistory();
```

## Integration

The provider is integrated into the app through:
1. Import in `lib/data.dart`
2. Added to `Global.providerList`
3. Info widget registered in `_initActions`
4. Keywords registered in `_provideActions`