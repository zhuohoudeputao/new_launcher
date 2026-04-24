# Tip Calculator Provider Implementation

## Overview

The Tip Calculator provider (`provider_tip.dart`) provides quick tip calculation functionality for dining and bill splitting scenarios. It allows users to calculate tips based on bill amounts, tip percentages, and split counts.

## Implementation Details

### File Location
`lib/providers/provider_tip.dart`

### Provider Registration
The provider is registered in:
- `lib/data.dart` - Added to `Global.providerList`
- `lib/main.dart` - `tipModel` added to MultiProvider

### Model Structure

#### TipModel Class
The `TipModel` class extends `ChangeNotifier` and manages:
- `_billAmount`: Current bill amount (double)
- `_tipPercentage`: Tip percentage (double, default 15%)
- `_splitCount`: Number of people to split between (int, 1-20)
- `_isInitialized`: Initialization flag
- `_history`: List of saved calculations (max 10 entries)

#### Computed Properties
- `tipAmount`: Calculated as `billAmount * tipPercentage / 100`
- `totalAmount`: Calculated as `billAmount + tipAmount`
- `perPerson`: Calculated as `totalAmount / splitCount`
- `tipPerPerson`: Calculated as `tipAmount / splitCount`
- `isCustomPercentage`: Checks if tip percentage is custom (not preset)

#### TipCalculation Class
Data structure for history entries containing:
- `billAmount`, `tipPercentage`, `splitCount`
- `tipAmount`, `totalAmount`, `perPerson`, `tipPerPerson`
- `timestamp`

### Methods

#### Core Methods
- `init()`: Initialize the model
- `refresh()`: Notify listeners to refresh UI
- `setBillAmount(double)`: Set bill amount
- `setTipPercentage(double)`: Set tip percentage
- `setSplitCount(int)`: Set split count (clamped 1-20)
- `incrementSplit()`: Increase split count (max 20)
- `decrementSplit()`: Decrease split count (min 1)

#### History Methods
- `saveToHistory()`: Save current calculation to history
- `clearHistory()`: Clear all history entries
- `formatAmount(double)`: Format amount with $ prefix

#### Reset Methods
- `clear()`: Reset all values to defaults

### UI Components

#### TipCard Widget
Main widget displaying:
- Title row with history toggle and clear button
- Bill amount input with $ prefix
- Tip percentage selector using SegmentedButton (10%, 15%, 18%, 20%, 25%)
- Custom tip percentage input field
- Split selector with +/- buttons
- Results display (tip, total, per person, tip each)
- Save and Clear action buttons

#### History View
Displays saved calculations in a ListView:
- Bill amount and tip percentage
- Split count and per-person amount
- Tap to restore previous calculation

### Features

#### Preset Tip Percentages
Quick selection buttons for common percentages:
- 10%, 15%, 18%, 20%, 25%

#### Custom Tip Input
TextField for entering custom tip percentages (0-100%)

#### Bill Splitting
Split between 1-20 people with visual increment/decrement buttons

#### Real-time Calculation
All calculations update instantly as values change

#### History Management
- Save calculations for reference
- Restore previous calculations
- Clear history with confirmation dialog

### Material 3 Components Used
- `Card.filled()` for main container
- `SegmentedButton` for preset tip selection
- `TextField` with OutlineInputBorder
- `IconButton` for +/- buttons
- `ElevatedButton` for Save/Clear
- `AlertDialog` for confirmations

### Keywords
`tip, tipcalc, calculator, bill, restaurant, dining, split`

## Testing

### Test Coverage
Located in `test/widget_test.dart`:
- Provider existence and keywords
- Model initialization and state
- Bill amount, tip percentage, split count operations
- Calculation accuracy tests
- History operations (save, clear, max limit)
- Widget rendering tests
- Material 3 component tests

### Test Count
34 tests for Tip Calculator provider (lines 9200-9539 in test file)

## Integration

### Provider List
Added to `Global.providerList` as `providerTip`

### MultiProvider
`tipModel` added to `MultiProvider` in `main.dart`

### Info Widget
Registered with key `"TipCalculator"` and title `"Tip Calculator"`

## Usage Example

```dart
// Set bill amount
tipModel.setBillAmount(100);

// Set tip percentage
tipModel.setTipPercentage(20);

// Set split count
tipModel.setSplitCount(4);

// Get calculated values
double tip = tipModel.tipAmount; // 20
double total = tipModel.totalAmount; // 120
double perPerson = tipModel.perPerson; // 30
double tipEach = tipModel.tipPerPerson; // 5

// Save to history
tipModel.saveToHistory();

// Format display
String display = tipModel.formatAmount(30); // "$30"
```

## Future Enhancements
Potential improvements:
- Round up/down options
- Tax calculation integration
- Currency symbol customization
- Export history to CSV