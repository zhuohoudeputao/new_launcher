# Caesar Cipher Provider Implementation

## Overview

The Caesar Cipher provider encrypts and decrypts text using the classic Caesar cipher.

## Provider Details

- **Provider Name**: CaesarCipher
- **Keywords**: caesar, cipher, encrypt, decrypt, shift, rotate, classic
- **Model**: caesarCipherModel

## Features

### Encryption/Decryption

- Encrypt: Shift letters forward by N positions
- Decrypt: Shift letters backward by N positions
- Configurable shift value (0-25) with slider
- ROT13 support (shift 13)

### Text Handling

- Preserves case (uppercase/lowercase)
- Non-letter characters unchanged
- Wrap-around handling (XYZ+3 = ABC)

## Model (CaesarCipherModel)

```dart
class CaesarCipherModel extends ChangeNotifier {
  String _input = '';
  String _output = '';
  int _shift = 3;
  bool _isEncrypt = true;
  final List<CaesarHistoryEntry> _history = [];
  static const int maxHistory = 10;
  
  void setInput(String value);
  void setShift(int value);
  void toggleMode();
  void _process();
  void addToHistory();
  void clearHistory();
  void useHistoryEntry(CaesarHistoryEntry entry);
}
```

## Encryption Formula

```dart
String encrypt(String text, int shift) {
  return text.split('').map((char) {
    if (char.toUpperCase() == char.toLowerCase()) return char;
    final isUpper = char.toUpperCase() == char;
    final base = isUpper ? 65 : 97;
    final code = char.codeUnitAt(0) - base;
    final shifted = (code + shift) % 26;
    return String.fromCharCode(base + shifted);
  }).join();
}
```

## Widget (CaesarCipherCard)

- Card.filled style
- SegmentedButton for encrypt/decrypt mode
- Slider for shift value (0-25)
- TextField for input text
- SelectableText for output
- Copy to clipboard button
- History toggle view

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching
- Model initialization and state
- Encryption/decryption operations
- Shift handling
- Case preservation
- Wrap-around
- History operations
- Widget rendering

## Related Files

- `lib/providers/provider_caesar.dart` - Provider implementation