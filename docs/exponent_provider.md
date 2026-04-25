# Exponent Calculator Provider Implementation

## Overview

The Exponent provider provides math operations for power, root, and logarithm calculations.

## Features

### Power Calculation
- Calculate x^y (power/exponentiation)
- Base and exponent inputs
- Real-time result display

### Root Calculations
- Square root (sqrt): Calculate sqrt(x)
- Cube root (cbrt): Calculate cbrt(x), including negative numbers
- Nth root: Calculate nth root of x with configurable degree

### Logarithm Calculations
- Logarithm (log base y): Calculate log_y(x)
- Natural logarithm (ln): Calculate ln(x)
- Base validation (must be positive)

### History
- Track up to 10 calculations
- Save calculations with full details
- Load previous calculations from history
- Clear history with confirmation dialog

## Implementation Details

### Model (ExponentModel)
- `init()` - Initialize model and load history from SharedPreferences
- `refresh()` - Trigger UI update
- `setBase(double value)` - Set base value
- `setExponent(double value)` - Set exponent value
- `setOperation(String op)` - Set operation type (power, sqrt, cbrt, nthroot, log, ln)
- `clear()` - Reset inputs to defaults
- `saveToHistory()` - Save current calculation to history
- `loadFromHistory(entry)` - Load calculation from history
- `clearHistory()` - Clear all history
- `result` getter - Calculate result based on operation
- `operationLabel` getter - Get display label for operation
- `resultLabel` getter - Get formatted result string

### Data Classes
- `ExponentHistoryEntry` - Stores saved calculation details
  - date, operation, base, exponent, result
  - toJson/fromJson for persistence

### Widget (ExponentCard)
- StatefulWidget with TextEditingController for inputs
- Material 3 Card.filled styling
- SegmentedButton for operation selection (6 operations)
- TextField for base and exponent inputs
- Result container with surfaceContainerHigh color
- History view with ListTile entries
- Confirmation dialog for clearing history

## State Management

- Uses SharedPreferences for history persistence
- ChangeNotifier pattern for UI updates
- Global model instance: `exponentModel`
- Max history limit: 10 entries

## Keywords

- exponent, power, root, square, cube, log, logarithm, math, calculate

## Usage

The provider is automatically added to the info widget list on app startup. Users can:
1. Select operation type using SegmentedButton
2. Enter base value (and exponent where applicable)
3. View calculated result
4. Save calculations to history
5. Load previous calculations from history
6. Clear history with confirmation

## Mathematical Operations

### Power (x^y)
Uses the formula: result = pow(base, exponent)

### Square Root (sqrt)
Uses dart:math sqrt function

### Cube Root (cbrt)
Uses: pow(base, 1/3) for positive, -pow(-base, 1/3) for negative

### Nth Root
Uses: pow(base, 1/n)
- Returns NaN for negative base with even n

### Logarithm (log base y)
Uses: log(base) / log(exponent)
- Returns NaN for non-positive base or exponent

### Natural Logarithm (ln)
Uses dart:math log function
- Returns NaN for non-positive base

## Files Modified

- `lib/providers/provider_exponent.dart` - New provider implementation
- `lib/data.dart` - Added import and provider to Global.providerList
- `lib/main.dart` - Added import and model to MultiProvider
- `test/widget_test.dart` - Added 28 tests for the provider
- `AGENTS.md` - Updated documentation

## Tests Added

- Provider existence and keywords tests
- Model initialization tests
- Power calculation tests
- Square root calculation tests
- Cube root calculation tests (positive and negative)
- Nth root calculation tests
- Logarithm calculation tests
- Natural logarithm calculation tests
- Invalid input handling tests (negative sqrt, negative ln)
- History operations tests
- JSON serialization tests
- Widget rendering tests
- Provider list inclusion tests