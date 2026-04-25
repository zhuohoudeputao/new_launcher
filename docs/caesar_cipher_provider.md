# Caesar Cipher Provider Implementation

## Overview

The Caesar Cipher provider implements a classic encryption method for encoding and decoding text by shifting letters. Named after Julius Caesar, this cipher shifts each letter in the alphabet by a fixed number of positions.

## Implementation Details

### Provider File

- **Location**: `lib/providers/provider_caesar.dart`
- **Provider Name**: `CaesarCipher`
- **Model**: `CaesarCipherModel`

### Features

1. **Encrypt/Decrypt Operations**
   - Encode text by shifting letters forward
   - Decode text by shifting letters backward
   - Swap operation with one tap

2. **Shift Control**
   - Configurable shift value (0-25)
   - Slider for easy adjustment
   - Shift value display with visual indicator
   - Shift wraps around (26 becomes 0)

3. **Text Processing**
   - Preserves case (uppercase/lowercase)
   - Non-letter characters unchanged
   - Real-time conversion as you type
   - Handles wrap-around (Z+3 = C)

4. **History Tracking**
   - Stores up to 10 conversion entries
   - Includes shift value in history
   - Load previous conversions from history
   - Clear history with confirmation dialog

5. **Special Features**
   - ROT13 support (shift 13)
   - Zero shift produces same text
   - Decrypt is inverse of encrypt

### Model Class

```dart
class CaesarCipherModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _inputText = "";
  String _outputText = "";
  String _operation = "encrypt";
  int _shift = 3;
  String? _error;
  List<_CaesarHistoryEntry> _history = [];
}
```

### Key Methods

- `setInputText(String text)` - Set input and trigger processing
- `setOperation(String operation)` - Set encrypt or decrypt
- `setShift(int value)` - Set shift value (0-25, wraps at 26)
- `swapOperation()` - Toggle between encrypt/decrypt
- `addToHistory()` - Save current conversion to history
- `loadFromHistory(int index)` - Load previous conversion
- `clearHistory()` - Clear all history entries
- `copyToClipboard(String text, BuildContext context)` - Copy output

### Encryption Algorithm

```dart
String _caesarEncrypt(String text, int shift) {
  for each character:
    if letter:
      base = uppercase ? 65 : 97
      shiftedCode = ((code - base + shift) % 26) + base
    else:
      keep unchanged
}
```

### UI Components

- `CaesarCipherCard` - Main widget with all functionality
- `SegmentedButton` - Operation selector (Encrypt/Decrypt)
- `Slider` - Shift value adjustment (0-25)
- `TextField` - Input text entry
- `SelectableText` - Output display
- `IconButton` - Swap, clear, save actions
- History section with expandable entries

## Keywords

- caesar, cipher, encrypt, decrypt, shift, rotate, classic

## Material 3 Design

- Uses `Card.filled` for main card
- Uses `SegmentedButton` for operation selection
- Uses `Slider` with divisions for shift control
- Color-coded shift indicator badge
- Error display with `errorContainer` color
- IconButtons with `styleFrom()` for consistent styling

## Test Coverage

- Provider existence and keywords
- Model initialization and state
- Encryption/decryption operations
- Case preservation (uppercase/lowercase)
- Non-letter handling
- Wrap-around behavior (XYZ -> ABC)
- ROT13 (shift 13)
- Shift 0 produces same text
- Decrypt as inverse of encrypt
- Operation swapping
- Shift setting and wrapping
- History operations (add, load, clear, limit)
- UI widget rendering
- Provider list inclusion

## Usage Example

Encrypt "HELLO" with shift 3:
- Input: HELLO
- Shift: 3
- Output: KHOOR

Decrypt "KHOOR" with shift 3:
- Input: KHOOR
- Shift: 3
- Output: HELLO

ROT13 example:
- Input: HELLO
- Shift: 13
- Output: URYYB

## Integration

Added to:
- `lib/data.dart` imports and providerList
- `lib/main.dart` imports and MultiProvider
- `test/widget_test.dart` imports and test group

## Related Providers

- TextEncoder - Base64, URL, HTML, JSON encoding
- MorseCode - Morse code encoding/decoding
- NatoPhonetic - NATO phonetic alphabet encoding
- RomanNumerals - Roman numeral conversion