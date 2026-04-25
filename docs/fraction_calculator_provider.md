# Fraction Calculator Provider

## Overview

The Fraction Calculator provider implements a fraction arithmetic calculator for the Flutter launcher application. It allows users to perform mathematical operations on fractions (add, subtract, multiply, divide) with automatic simplification to lowest terms.

## Implementation

### File Location
- Provider: `lib/providers/provider_fraction.dart`

### Model: FractionCalculatorModel

The model manages the state for fraction calculations:

```dart
class FractionCalculatorModel extends ChangeNotifier {
  int _firstNumerator = 1;
  int _firstDenominator = 2;
  int _secondNumerator = 1;
  int _secondDenominator = 4;
  String _operation = '+';
  List<FractionOperationHistory> _history = [];
  bool _isInitialized = false;

  static const int maxHistoryLength = 10;
}
```

### Fraction Class

The Fraction class handles all fraction operations:

```dart
class Fraction {
  final int numerator;
  final int denominator;

  Fraction(this.numerator, this.denominator);

  bool get isValid => denominator != 0;
  double get decimal => numerator / denominator;

  Fraction simplify();
  Fraction add(Fraction other);
  Fraction subtract(Fraction other);
  Fraction multiply(Fraction other);
  Fraction divide(Fraction other);
  String toStringDisplay();
}
```

## Features

1. **Fraction Input**: Two fractions with numerator and denominator inputs
2. **Operations**: Add (+), Subtract (-), Multiply (×), Divide (÷)
3. **Automatic Simplification**: Results automatically simplified to lowest terms
4. **Mixed Number Display**: Displays results as whole number + fraction (e.g., "1 3/4")
5. **Decimal Conversion**: Shows decimal equivalent of result
6. **Swap Fractions**: Button to swap first and second fractions
7. **Division by Zero Handling**: Detects and displays error for division by zero
8. **History Tracking**: Saves up to 10 previous calculations
9. **History Reuse**: Tap history entries to reload previous calculations

## UI Components

### FractionCalculatorCard

Uses Material 3 Card.filled with:

- Router icon and title
- Two fraction input sections with TextField for numerator/denominator
- SegmentedButton for operation selection (+, -, ×, ÷)
- Result section showing:
  - Equation display (e.g., "1/2 + 1/4")
  - Fraction result (e.g., "3/4")
  - Decimal result (e.g., "0.7500")
- History section with ActionChips for quick reuse

## Keywords

- fraction, calculator, math, add, subtract, multiply, divide, numerator, denominator, simplify, reduce

## Tests

Located in `test/widget_test.dart` under group "Fraction Calculator provider tests":

- Model initialization
- Fraction class simplify
- Fraction class add/subtract/multiply/divide
- Division by zero handling
- toStringDisplay for various fraction formats
- Model setters (numerator, denominator, operation)
- Result calculation
- Fraction validity check
- Swap fractions
- History operations
- Max history limit
- applyFromHistory
- refresh/notifyListeners
- Widget rendering
- Provider registration
- Keyword validation

## Integration

The provider is registered in:
- `lib/data.dart`: Provider import and providerList
- `lib/main.dart`: Model import and MultiProvider