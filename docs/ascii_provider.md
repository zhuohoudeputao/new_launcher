# ASCII Converter Provider Implementation

## Overview

The ASCII Converter provider allows users to convert text to ASCII codes and vice versa. It provides an interactive ASCII table reference and history tracking for conversions.

## Implementation Details

### File Location
`lib/providers/provider_ascii.dart`

### Model Class: AsciiModel

The `AsciiModel` class extends `ChangeNotifier` and manages:
- Input text and output text
- Conversion mode (encode/decode)
- ASCII table reference visibility
- History of conversions (up to 10 entries)

### Static Methods

#### `textToAscii(String text)`
Converts text characters to their ASCII code values:
```dart
AsciiModel.textToAscii('Hello') // Returns: "72 101 108 108 111"
```

#### `asciiToText(String ascii)`
Converts space-separated ASCII codes to text:
```dart
AsciiModel.asciiToText('72 101 108 108 111') // Returns: "Hello"
```

Handles invalid input:
- Non-numeric input returns "Invalid ASCII codes"
- Values outside 0-255 range are filtered out

#### `getAsciiTable()`
Returns a list of printable ASCII characters (32-126) with their codes and names:
```dart
AsciiModel.getAsciiTable() // Returns 95 entries
```

### UI Component: AsciiCard

The `AsciiCard` widget displays:
- Mode selection using SegmentedButton (encode/decode)
- Input TextField with clear button
- Output display in SelectableText container
- Save to history button
- Swap input/output button
- History access button
- ASCII table reference toggle

### ASCII Table Reference

The ASCII table shows printable characters (32-126) in a GridView with:
- Character display
- ASCII code number
- Tappable cells to add to input

### Provider Registration

The provider is registered as:
```dart
MyProvider providerAsciiConverter = MyProvider(
  name: "Ascii",
  ...
);
```

### Keywords

The provider is searchable with keywords:
- ascii, converter, encode, decode, character, code, text, char, table

## Material 3 Components Used

- `Card.filled` - Main container
- `SegmentedButton<String>` - Mode selection
- `TextField` - Input field
- `SelectableText` - Output display
- `GridView` - ASCII table reference
- `IconButton` - Swap and clear buttons
- `ElevatedButton.icon` - Save to history

## History Management

- Maximum 10 history entries
- Each entry stores: input, output, mode, timestamp
- History persisted via SharedPreferences
- Clear history with confirmation dialog

## Testing

Tests cover:
- Model initialization
- textToAscii/asciiToText static methods
- Invalid input handling
- Mode swapping
- History operations
- Widget rendering
- Provider registration