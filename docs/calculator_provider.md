# Calculator Provider Implementation

## Overview

The Calculator provider provides quick calculation functionality directly in the launcher. Users can perform basic arithmetic operations without opening a separate calculator app.

## Implementation Details

### Provider Structure

File: `lib/providers/provider_calculator.dart`

```dart
MyProvider providerCalculator = MyProvider(
    name: "Calculator",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Keywords

- `calc`
- `calculator`
- `math`
- `calculate`
- `equal`

### CalculatorModel

The `CalculatorModel` class manages calculator state:

#### State Properties
- `_display`: Current display value (default: '0')
- `_expression`: Pending expression (e.g., '5+')
- `_lastResult`: Last calculation result for reuse
- `_history`: List of calculation history entries (max 10)

#### Core Methods
- `inputDigit(String)`: Add digit to display
- `inputOperator(String)`: Add operator (+, -, ×, ÷)
- `inputDecimal()`: Add decimal point
- `calculate()`: Evaluate expression and show result
- `clear()`: Reset calculator state
- `deleteLastDigit()`: Remove last digit from display
- `calculatePercent()`: Convert value to percentage
- `toggleSign()`: Toggle positive/negative sign
- `clearHistory()`: Clear calculation history

### Expression Evaluation

The calculator uses a stack-based expression evaluator:

```dart
double _evaluateTokens(List<String> tokens) {
  // Uses operator precedence:
  // - *, / have higher precedence (2)
  // - +, - have lower precedence (1)
  // Handles parentheses for nested expressions
}
```

### CalculatorCard Widget

The UI component displays:
- Current expression and result
- Keypad with digits and operators
- History view (toggleable)
- Clear history button

#### Keypad Layout
```
C  ±  %  ÷
7  8  9  ×
4  5  6  -
1  2  3  +
⌫  0  .  =
```

### History Feature

- Up to 10 calculation history entries
- Each entry stores expression, result, and timestamp
- Tap history entry to reuse the result
- Clear history with confirmation dialog

### Error Handling

- Division by zero shows 'Error'
- Invalid expressions show 'Error'
- Error state clears on next valid input

## Material 3 Design

- Uses `Card.filled` for Material 3 style
- Color scheme for button colors:
  - Operators: `primaryContainer`
  - Functions: `surfaceContainerHigh`
  - Digits: `surfaceContainerHighest`

## Integration

### main.dart

Added to providers list:
```dart
ChangeNotifierProvider.value(value: calculatorModel),
```

### data.dart

Added to Global.providerList:
```dart
providerCalculator,
```

## Testing

Test coverage includes:
- Provider existence in Global.providerList
- Keywords validation
- CalculatorModel initialization
- Digit and operator input
- Arithmetic operations (+, -, ×, ÷)
- Division by zero handling
- Percentage calculation
- Sign toggle
- History management
- Clear history
- History max limit (10 entries)
- Widget rendering states

Total calculator tests: 29 tests