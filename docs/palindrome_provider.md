# Palindrome Provider Implementation

## Overview

The Palindrome provider adds a palindrome checker to the launcher application. A palindrome is a word, phrase, number, or other sequence of characters that reads the same forward and backward.

## Features

- **Palindrome Detection**: Check if text reads the same forward and backward
- **Flexible Options**:
  - Ignore spaces (default: on)
  - Ignore punctuation (default: on)
  - Ignore case (default: on)
- **Visual Feedback**: Color-coded result indicator (green for palindrome, red for non-palindrome)
- **Reversed Text Display**: Shows the reversed text for comparison
- **History Tracking**: Stores up to 10 previously checked texts
- **Famous Palindrome Support**: Handles complex phrases like "A man a plan a canal Panama"

## Implementation Details

### Model: `PalindromeModel`

Located in `lib/providers/provider_palindrome.dart`

```dart
class PalindromeModel extends ChangeNotifier {
  String _inputText = '';
  bool _isPalindrome = false;
  String _reversedText = '';
  bool _ignoreSpaces = true;
  bool _ignorePunctuation = true;
  bool _ignoreCase = true;
  bool _isInitialized = false;
  List<Map<String, dynamic>> _history = [];
  static const int _maxHistoryLength = 10;
}
```

### Key Methods

- `setInputText(String value)` - Updates input text and checks palindrome
- `setIgnoreSpaces(bool value)` - Toggle space ignoring option
- `setIgnorePunctuation(bool value)` - Toggle punctuation ignoring option
- `setIgnoreCase(bool value)` - Toggle case ignoring option
- `_normalizeText(String text)` - Normalizes text based on current options
- `_checkPalindrome()` - Performs palindrome check
- `addToHistory()` - Saves current check to history
- `loadFromHistory(Map<String, dynamic> entry)` - Restores entry from history
- `clearHistory()` - Removes all history entries

### Widget: `PalindromeCard`

Material 3 styled card with:
- TextField for input with clear button
- FilterChips for options (Ignore spaces, punctuation, case)
- Result container with color-coded indicator
- Reversed text display
- Save to history button
- History view dialog

### Provider Registration

Added to `Global.providerList` in `lib/data.dart`:
```dart
providerPalindrome,
```

Added to `MultiProvider` in `lib/main.dart`:
```dart
ChangeNotifierProvider.value(value: palindromeModel),
```

## Test Coverage

Tests cover:
- Provider existence and keywords
- Model initial state and initialization
- Palindrome detection for various inputs (racecar, radar, level, madam)
- Non-palindrome detection (hello, world)
- Reversed text calculation
- Options handling (spaces, punctuation, case)
- Famous palindrome "A man a plan a canal Panama"
- Empty input handling
- Single character and number handling
- History operations (add, load, clear, max limit)
- Widget rendering states

Total: 31 tests

## Usage

1. Type "palindrome" in the search field to display the Palindrome Checker card
2. Enter text in the input field
3. Toggle options using FilterChips:
   - Ignore spaces - removes spaces before checking
   - Ignore punctuation - removes punctuation before checking
   - Ignore case - converts to lowercase before checking
4. View result (green = palindrome, red = not palindrome)
5. Save to history for future reference
6. Access history via the History button

## Keywords

`palindrome, check, text, reverse, word, phrase, mirror, backwards`