# Vigenère Cipher Provider Implementation

## Overview

The Vigenère Cipher provider implements a classic polyalphabetic cipher for text encryption and decryption using a keyword. It's more secure than the Caesar cipher as it uses multiple shift values based on the keyword.

## Implementation Details

### Provider File

Located at `lib/providers/provider_vigenere.dart`.

### Model: VigenereCipherModel

The `VigenereCipherModel` class manages the cipher state:

#### Properties
- `_isInitialized`: Boolean flag for initialization status
- `_inputText`: The text to encrypt/decrypt
- `_outputText`: The processed result
- `_keyword`: The encryption keyword (uppercase letters only)
- `_operation`: Current operation mode ('encrypt' or 'decrypt')
- `_keywordError`: Error message for invalid keyword
- `_inputError`: Error message for processing errors
- `_history`: List of previous conversions (max 10 entries)

#### Key Methods

**Encryption Logic**
```dart
String _vigenereEncrypt(String text, String keyword) {
  final List<String> result = [];
  int keywordIndex = 0;
  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    if (_isLetter(char)) {
      final base = _isUpperCase(char) ? 65 : 97;
      final code = char.codeUnitAt(0);
      final keyChar = keyword[keywordIndex % keyword.length];
      final keyShift = keyChar.codeUnitAt(0) - 65;
      final shiftedCode = ((code - base + keyShift) % 26) + base;
      result.add(String.fromCharCode(shiftedCode));
      keywordIndex++;
    } else {
      result.add(char);
    }
  }
  return result.join();
}
```

**Decryption Logic**
```dart
String _vigenereDecrypt(String text, String keyword) {
  // Same logic but subtracting keyShift instead of adding
  final shiftedCode = ((code - base - keyShift + 26) % 26) + base;
}
```

### Widget: VigenereCipherCard

The card widget provides the UI for cipher operations:

#### Components
- Header with history toggle button
- Operation selector (SegmentedButton: Encrypt/Decrypt)
- Keyword input field with validation
- Input text field
- Output display with copy button
- Action buttons (swap operation, clear all, save to history)
- History section with load and clear functionality

### Material 3 Components Used
- `Card.filled` for main container
- `SegmentedButton` for operation selection
- `TextField` for input fields
- `SelectableText` for output display
- `IconButton` with `IconButton.styleFrom()` for actions

## Vigenère Cipher Algorithm

### How It Works

1. **Keyword Processing**: Each letter in the keyword determines a shift value (A=0, B=1, ..., Z=25)
2. **Letter-by-Letter Encryption**: Each plaintext letter is shifted by the corresponding keyword letter
3. **Keyword Wrapping**: The keyword repeats to match the plaintext length
4. **Case Preservation**: Upper/lowercase is maintained
5. **Non-Letter Handling**: Spaces, punctuation, and numbers are unchanged

### Example

Keyword: "KEY" (K=10, E=4, Y=24)
Plaintext: "HELLO"

- H(7) + K(10) = R(17)
- E(4) + E(4) = I(8)
- L(11) + Y(24) = 35 mod 26 = J(9)
- L(11) + K(10) = V(21)
- O(14) + E(4) = S(18)

Result: "RIJVS"

## Features

### Core Features
- Encrypt text using keyword-based polyalphabetic cipher
- Decrypt text with the same keyword
- Keyword validation (letters only, uppercase)
- Case preservation
- Non-letter character handling
- History tracking (up to 10 entries)

### UI Features
- Swap encrypt/decrypt with one tap
- Clear all inputs
- Copy output to clipboard
- Save conversions to history
- Load from history
- Clear history with confirmation dialog

## Testing

Tests are located in `test/widget_test.dart` under the 'Vigenere Cipher Provider tests' group.

### Test Coverage
- Provider existence and registration
- Keywords validation
- Model initialization
- Encryption with various inputs
- Decryption verification
- Keyword wrapping behavior
- Keyword validation (non-letters rejected)
- History operations (add, load, clear, limit)
- Widget rendering
- Operation swapping
- Case preservation
- Non-letter handling

## Integration

### Provider Registration

Added to `lib/data.dart`:
```dart
import 'package:new_launcher/providers/provider_vigenere.dart';
// ...
providerVigenereCipher,
```

### MultiProvider

The model is provided via `ChangeNotifierProvider.value` in the widget:
```dart
ChangeNotifierProvider.value(
  value: vigenereCipherModel,
  builder: (context, child) => VigenereCipherCard(),
)
```

## Comparison with Caesar Cipher

| Feature | Caesar Cipher | Vigenère Cipher |
|---------|--------------|-----------------|
| Shift Method | Single fixed shift | Multiple shifts from keyword |
| Key | Numeric (0-25) | Text keyword |
| Security | Low (easy to crack) | Higher (polyalphabetic) |
| Configuration | Slider for shift | Text field for keyword |

## Keywords

`vigenere, cipher, encrypt, decrypt, keyword, polyalphabetic, classic`