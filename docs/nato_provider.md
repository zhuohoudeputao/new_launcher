# NATO Phonetic Provider Implementation

## Overview

The NATO Phonetic provider adds a NATO Phonetic Alphabet encoder/decoder to the launcher application. The NATO phonetic alphabet is used for radio communications, spelling words over phone calls, and clear communication in noisy environments.

## Features

- **Text to NATO Encoding**: Convert text to NATO phonetic words (A -> Alpha, B -> Bravo, etc.)
- **NATO to Text Decoding**: Convert NATO phonetic words back to regular text
- **Full Alphabet Support**: A-Z with standard NATO words
- **Number Support**: 0-9 converted to Zero, One, Two, etc.
- **Reference Section**: Toggle to view all NATO phonetic codes
- **History Tracking**: Stores up to 10 conversions
- **Case-Insensitive Decoding**: Handles both "Alpha" and "alpha"
- **Copy to Clipboard**: Quick copy of output

## Implementation Details

### Model: `NatoPhoneticModel`

Located in `lib/providers/provider_nato.dart`

```dart
class NatoPhoneticModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _inputText = "";
  String _outputText = "";
  String _operation = "encode";
  String? _error;
  bool _showReference = false;
  List<_NatoHistoryEntry> _history = [];
  
  static const Map<String, String> natoMap = {
    'A': 'Alpha',
    'B': 'Bravo',
    'C': 'Charlie',
    'D': 'Delta',
    'E': 'Echo',
    'F': 'Foxtrot',
    'G': 'Golf',
    'H': 'Hotel',
    'I': 'India',
    'J': 'Juliet',
    'K': 'Kilo',
    'L': 'Lima',
    'M': 'Mike',
    'N': 'November',
    'O': 'Oscar',
    'P': 'Papa',
    'Q': 'Quebec',
    'R': 'Romeo',
    'S': 'Sierra',
    'T': 'Tango',
    'U': 'Uniform',
    'V': 'Victor',
    'W': 'Whiskey',
    'X': 'X-ray',
    'Y': 'Yankee',
    'Z': 'Zulu',
    '0': 'Zero',
    '1': 'One',
    '2': 'Two',
    '3': 'Three',
    '4': 'Four',
    '5': 'Five',
    '6': 'Six',
    '7': 'Seven',
    '8': 'Eight',
    '9': 'Nine',
  };
}
```

### Key Methods

- `setInputText(String text)` - Updates input and processes conversion
- `setOperation(String operation)` - Switches between encode/decode mode
- `swapOperation()` - Quick toggle between modes
- `_encodeToNato(String text)` - Converts text to NATO phonetic words
- `_decodeFromNato(String nato)` - Converts NATO words back to text
- `toggleReference()` - Shows/hides the NATO reference section
- `addToHistory()` - Saves current conversion to history
- `loadFromHistory(int index)` - Restores conversion from history
- `clearHistory()` - Removes all history entries
- `copyToClipboard(String text, BuildContext context)` - Copies output to clipboard

### Widget: `NatoPhoneticCard`

Material 3 styled card with:
- SegmentedButton for Encode/Decode mode selection
- TextField for input
- Output display with copy button
- Action buttons (Swap, Clear, Save to history)
- Toggleable reference section showing all NATO codes
- History view with clear confirmation

### Provider Registration

Added to `Global.providerList` in `lib/data.dart`:
```dart
providerNatoPhonetic,
```

Added to `MultiProvider` in `lib/main.dart`:
```dart
ChangeNotifierProvider.value(value: natoPhoneticModel),
```

## Test Coverage

Tests cover:
- Provider existence and keywords
- Model initial state and initialization
- Operations list (encode, decode)
- NATO map entries (26 letters + 10 numbers)
- Reverse NATO map functionality
- Encoding simple text (ABC -> Alpha Bravo Charlie)
- Encoding with spaces
- Encoding numbers
- Encoding lowercase (converts to uppercase)
- Encoding unknown characters
- Decoding NATO words (Alpha Bravo -> AB)
- Decoding numbers
- Decoding case-insensitive
- Decoding unknown words
- Decoding (space) marker
- Swap operation
- Clear input
- Toggle reference
- Empty input handling
- History operations (add, load, clear, max limit)
- Widget rendering states (loading, initialized, output)

Total: 39 tests

## Usage

1. Type "nato" or "phonetic" in the search field to display the NATO Phonetic card
2. Select Encode or Decode mode using SegmentedButton
3. Enter text in the input field:
   - **Encode**: Type regular text (e.g., "ABC")
   - **Decode**: Type NATO words separated by spaces (e.g., "Alpha Bravo Charlie")
4. View output with copy button
5. Toggle reference section to see all NATO codes
6. Save conversions to history for future reference

## NATO Phonetic Alphabet Reference

- A: Alpha
- B: Bravo
- C: Charlie
- D: Delta
- E: Echo
- F: Foxtrot
- G: Golf
- H: Hotel
- I: India
- J: Juliet
- K: Kilo
- L: Lima
- M: Mike
- N: November
- O: Oscar
- P: Papa
- Q: Quebec
- R: Romeo
- S: Sierra
- T: Tango
- U: Uniform
- V: Victor
- W: Whiskey
- X: X-ray
- Y: Yankee
- Z: Zulu

## Keywords

`nato, phonetic, alphabet, radio, spelling, alpha, bravo, charlie, encode, decode`