# Morse Code Provider Implementation

## Overview

The Morse Code provider provides text encoding and decoding functionality for Morse code conversion. It allows users to convert text to Morse code (dots and dashes) and vice versa.

## Implementation Details

### File Location
`lib/providers/provider_morse.dart`

### Model Class: `MorseCodeModel`

The `MorseCodeModel` class extends `ChangeNotifier` and manages:
- Input text state
- Output text state (Morse code or decoded text)
- Current operation (encode/decode)
- Error handling
- Conversion history

### Morse Code Map

The provider includes a comprehensive Morse code mapping for:
- Letters A-Z
- Numbers 0-9
- Common punctuation (., ,, ?, ', !, /, (, ), &, :, ;, =, +, -, _, ", $, @)
- Space character (represented as '/')

### Features

1. **Encode Mode**: Converts text to Morse code
   - Uppercases input automatically
   - Uses spaces between Morse characters
   - Unknown characters shown as '?'

2. **Decode Mode**: Converts Morse code to text
   - Handles multiple spaces between characters
   - Returns uppercase text
   - Unknown Morse sequences shown as '?'

3. **History Management**
   - Stores up to 10 conversion entries
   - Preserves operation type
   - Timestamps for each entry

4. **UI Features**
   - Swap encode/decode operation with one tap
   - Clear input button
   - Copy output to clipboard
   - Save to history button
   - History view with clear all option

### UI Components

The `MorseCodeCard` widget uses Material 3 components:
- `Card.filled` for the main container
- `SegmentedButton` for encode/decode selection
- `SelectableText` for output display
- `IconButton` for action buttons

### Keywords for Search

The provider registers actions with keywords:
- `morse, code, encode, decode, dot, dash, signal, telegraph, convert`

## Provider Registration

1. Added to `Global.providerList` in `lib/data.dart`
2. Added to `MultiProvider` in `lib/main.dart`
3. Model imported in both files

## Testing

The provider includes comprehensive tests covering:
- Model initialization
- Encode operations
- Decode operations
- Roundtrip conversions
- History management
- Notification tests
- UI widget rendering
- Edge cases (unknown characters, empty input)

## Usage Example

```dart
final model = MorseCodeModel();
model.init();
model.setOperation('encode');
model.setInputText("HELLO WORLD");
// Output: ".... . .-.. .-.. --- / .-- --- .-. .-.. -.."

model.setOperation('decode');
model.setInputText("... --- ...");
// Output: "SOS"
```

## Notes

- The Morse code representation uses:
  - `.` for dots
  - `-` for dashes
  - Spaces between characters
  - `/` for spaces in text
- Lowercase input is automatically converted to uppercase
- The provider does not require external packages