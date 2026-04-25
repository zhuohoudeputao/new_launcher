# Bitwise Calculator Provider

## Overview

The Bitwise Calculator provider is a developer utility for performing bitwise operations on integers. It supports AND, OR, XOR, NOT, and shift operations with real-time conversion between decimal, binary, and hexadecimal formats.

## Features

### Supported Operations

- **AND (&)**: Bitwise AND operation between two values
- **OR (|)**: Bitwise OR operation between two values
- **XOR (^)**: Bitwise XOR (exclusive OR) operation between two values
- **NOT (~)**: Bitwise NOT (complement) operation - requires only one input
- **Left Shift (<<)**: Shifts bits to the left, multiplying by powers of 2
- **Right Shift (>>)**: Shifts bits to the right, dividing by powers of 2

### Input Formats

- **Decimal (DEC)**: Standard integer input (e.g., 255)
- **Binary (BIN)**: Binary representation (e.g., 11111111)
- **Hexadecimal (HEX)**: Hex representation (e.g., FF)

All three formats are synchronized - entering a value in one format automatically updates the others.

### Result Display

Results are displayed in all three formats simultaneously:
- Decimal value
- Binary representation
- Hexadecimal representation

## Model: BitwiseModel

### State Properties

```dart
int input1 = 0;           // First input value
int input2 = 0;           // Second input value
String operation = 'and'; // Current operation
List<BitwiseHistory> history = []; // Calculation history
bool isLoading = false;   // Loading state
bool requiresTwoInputs = true; // Whether operation needs two inputs
```

### Key Methods

- `setInput1(int value)` - Set the first input value
- `setInput2(int value)` - Set the second input value
- `setOperation(String op)` - Set the current operation ('and', 'or', 'xor', 'not', 'leftShift', 'rightShift')
- `addToHistory()` - Save current calculation to history (max 10 entries)
- `applyFromHistory(BitwiseHistory entry)` - Load values from history entry
- `clearHistory()` - Clear all history entries
- `refresh()` - Trigger UI update

### Calculated Properties

- `result` - The computed result of the bitwise operation
- `input1Binary` - Binary string representation of input1
- `input2Binary` - Binary string representation of input2
- `resultBinary` - Binary string representation of result
- `input1Hex` - Hexadecimal string representation of input1
- `input2Hex` - Hexadecimal string representation of input2
- `resultHex` - Hexadecimal string representation of result

## Widget: BitwiseCard

### UI Components

1. **Operation Selector**: SegmentedButton with 6 operation buttons
   - `&` (AND)
   - `|` (OR)
   - `^` (XOR)
   - `~` (NOT)
   - `<<` (Left Shift)
   - `>>` (Right Shift)

2. **Input Fields**: Two rows of input fields (Input 1 and Input 2)
   - Each row has DEC, BIN, and HEX text fields
   - Input 2 is hidden for NOT operation

3. **Result Section**: Container showing result in all formats
   - DEC value
   - BIN value
   - HEX value

4. **History Section**: List of previous calculations
   - Shows expression (e.g., "12 & 10 = 8")
   - Shows binary result
   - Tap to load values

5. **Add to History Button**: Saves current calculation

### Material 3 Components

- `Card.filled()` - Main container
- `SegmentedButton` - Operation selection
- `TextField` - Input fields
- `SelectableText` - Result display
- `ElevatedButton` - Add to history button
- `AlertDialog` - Clear history confirmation

## Usage Examples

### AND Operation
```
Input 1: 12 (DEC) = 1100 (BIN) = C (HEX)
Input 2: 10 (DEC) = 1010 (BIN) = A (HEX)
Result: 8 (DEC) = 1000 (BIN) = 8 (HEX)
```

### XOR Operation
```
Input 1: 12 (DEC) = 1100 (BIN) = C (HEX)
Input 2: 10 (DEC) = 1010 (BIN) = A (HEX)
Result: 6 (DEC) = 0110 (BIN) = 6 (HEX)
```

### Left Shift Operation
```
Input 1: 5 (DEC) = 101 (BIN) = 5 (HEX)
Input 2: 2 (shift amount)
Result: 20 (DEC) = 10100 (BIN) = 14 (HEX)
```

### NOT Operation
```
Input 1: 5 (DEC) = 101 (BIN) = 5 (HEX)
Result: -6 (DEC) = ...11111111111111111111111111111010 (BIN) = FFFFFFFA (HEX)
```

Note: NOT operation produces signed 32-bit complement.

## Provider Registration

```dart
Global.providerList.add(providerBitwise);
```

## Model Registration

```dart
ChangeNotifierProvider.value(value: bitwiseModel)
```

## Info Widget Registration

```dart
Global.infoModel.addInfoWidget("Bitwise", BitwiseCard(), title: "Bitwise Calculator");
```

## Keywords

- bitwise
- bit
- and
- or
- xor
- not
- shift
- calculator
- binary
- logic

## Test Coverage

- Provider existence check
- Keywords validation
- Model initialization
- Input value setting (DEC, BIN, HEX)
- Operation setting
- All bitwise operations (AND, OR, XOR, NOT, Left Shift, Right Shift)
- requiresTwoInputs property
- Binary/hexadecimal conversion
- History management (add, apply, clear)
- History max length (10 entries)
- refresh() notification
- BitwiseHistory expression formatting
- Widget rendering tests

## Related Providers

- **NumberBase**: Converts between number bases (binary, octal, decimal, hex)
- **Ascii**: ASCII code converter
- **Prime**: Prime number checker