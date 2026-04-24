# Decision Maker Provider

## Overview

The Decision Maker provider provides a utility for making random decisions. It helps users who need help deciding between options quickly.

## Features

- **Pick from options**: Enter multiple options separated by commas, and get a random selection
- **Spinning animation**: When 3+ options are entered, a spinning animation shows before the final result
- **Coin toss**: Quick Heads/Tails flip
- **Yes/No decision**: Quick Yes/No decision
- **History tracking**: View past decisions with timestamps
- **Clear history**: Clear all decision history with confirmation

## Implementation Details

### Model: DecisionMakerModel

The `DecisionMakerModel` class (ChangeNotifier) manages decision state:

```dart
class DecisionMakerModel extends ChangeNotifier {
  static const int maxHistory = 10;
  
  String _inputOptions = "";
  String _selectedOption = "";
  DecisionType _decisionType = DecisionType.pick;
  final List<DecisionEntry> _history = [];
  // ...
}
```

### Key Properties

- `inputOptions`: User-entered options string
- `selectedOption`: The randomly selected result
- `decisionType`: Current decision mode (pick, coinToss, yesNo)
- `history`: List of past decision entries
- `isSpinning`: Animation state indicator

### Decision Types

```dart
enum DecisionType {
  pick,      // Random pick from entered options
  coinToss,  // Heads or Tails
  yesNo,     // Yes or No
}
```

### Key Methods

- `makeDecision()`: Execute the decision based on current type
- `setInputOptions(String)`: Update entered options
- `setDecisionType(DecisionType)`: Switch decision mode
- `parseOptions()`: Split input into list of options
- `clearInput()`: Clear options and result
- `clearHistory()`: Clear decision history

### Decision History

```dart
class DecisionEntry {
  final String decision;
  final DecisionType type;
  final DateTime timestamp;
}
```

Maximum 10 history entries stored (oldest removed when exceeded).

## UI Components

### DecisionMakerCard

Main card widget with:
- SegmentedButton for decision type selection (Pick, Coin, Yes/No)
- TextField for entering options (comma-separated)
- Result display with color-coded backgrounds
- "Make Decision" button with casino icon
- History toggle button
- Clear history button with confirmation

### Material 3 Components

- `Card.filled` for main container
- `SegmentedButton` for decision type selection
- `TextField` with OutlineInputBorder
- `ElevatedButton.icon` for decision button
- `IconButton` for history and clear actions

## Search Keywords

```
decision maker decide choose random pick option spin wheel coin toss yes no
```

## Test Coverage

Tests verify:
- Provider existence in Global.providerList
- Model is ChangeNotifier
- Initial state values
- Input options parsing (split, empty, whitespace handling)
- Decision type switching
- Coin toss produces Heads or Tails
- Yes/No produces Yes or No
- History respects max limit (10 entries)
- clearInput clears values
- clearHistory clears history
- requestFocus sets shouldFocus
- DecisionType enum has all types
- DecisionEntry stores data correctly
- Card widget renders loading and initialized states
- Segmented buttons display correctly
- Make Decision button exists
- Tap to decide placeholder

## Provider Registration

The provider is registered in:
- `lib/data.dart`: Added to `Global.providerList`
- `lib/main.dart`: Added to MultiProvider

## Usage Example

1. Select decision type (Pick, Coin, or Yes/No)
2. For Pick mode: Enter options separated by commas (e.g., "Pizza, Burger, Salad")
3. Tap "Make Decision" button
4. View the random result
5. Toggle history view to see past decisions